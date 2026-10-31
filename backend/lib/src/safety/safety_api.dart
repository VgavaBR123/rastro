// Rotas do Rastro Seguro (docs/CONTRATO-RASTRO-SEGURO.md) penduradas no
// roteador da API. Toda rota, menos o link publico /s/<token>, exige Bearer;
// recurso de outra conta responde 404, igual a inexistente.
library;

import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../user_store.dart';
import 'safety_service.dart';

Response _json(Object data, {int status = 200}) => Response(
      status,
      body: jsonEncode(data),
      headers: {'content-type': 'application/json'},
    );

Response _erro(int status, String mensagem) =>
    _json({'error': mensagem}, status: status);

Future<Map<String, dynamic>?> _lerJson(Request req) async {
  try {
    final String texto = await req.readAsString();
    if (texto.trim().isEmpty) return <String, dynamic>{};
    final Object? v = jsonDecode(texto);
    return v is Map<String, dynamic> ? v : null;
  } on FormatException {
    return null;
  }
}

/// Tamanho maximo aceito para um token de push (os do FCM tem ~160 chars).
const int tamanhoMaximoTokenPush = 4096;

void montarRotasRastroSeguro(
  Router router,
  SafetyService safety,
  Future<UserRecord?> Function(Request) autenticar,
) {
  /// Autentica, roda e traduz SafetyError em resposta.
  FutureOr<Response> Function(Request) rota(
          Future<Response> Function(Request, UserRecord) h) =>
      (Request req) => _protegida(req, autenticar, (u) => h(req, u));

  FutureOr<Response> Function(Request, String) rotaId(
          Future<Response> Function(Request, UserRecord, String) h) =>
      (Request req, String id) =>
          _protegida(req, autenticar, (u) => h(req, u, id));

  Future<Response> comCorpo(Request req,
      Future<Response> Function(Map<String, dynamic>) h) async {
    final Map<String, dynamic>? body = await _lerJson(req);
    if (body == null) return _erro(400, 'corpo JSON invalido');
    return h(body);
  }

  // Contatos.
  router.post('/safety/contacts', rota((req, u) async {
    return comCorpo(req, (b) async {
      final Object? email = b['email'];
      if (email is! String) return _erro(400, 'email obrigatorio');
      return _json(await safety.inviteContact(u, email), status: 201);
    });
  }));
  router.get('/safety/contacts',
      rota((req, u) async => _json(await safety.listContacts(u))));
  router.post('/safety/contacts/<id>/accept',
      rotaId((req, u, id) async => _json(await safety.acceptContact(u, id))));
  router.delete('/safety/contacts/<id>', rotaId((req, u, id) async {
    await safety.deleteContact(u, id);
    return Response(204);
  }));

  // Sessoes. /active antes de /<id> para nao cair como id.
  router.post('/safety/sessions', rota((req, u) async {
    return comCorpo(req,
        (b) async => _json(await safety.createSession(u, b), status: 201));
  }));
  router.get('/safety/sessions/active',
      rota((req, u) async => _json(await safety.activeSession(u))));
  router.get('/safety/sessions/<id>',
      rotaId((req, u, id) async => _json(await safety.getSession(u, id))));
  router.post('/safety/sessions/<id>/positions', rotaId((req, u, id) async {
    return comCorpo(
        req, (b) async => _json(await safety.position(u, id, b)));
  }));
  router.post('/safety/sessions/<id>/ok',
      rotaId((req, u, id) async => _json(await safety.ok(u, id))));
  router.post('/safety/sessions/<id>/extend', rotaId((req, u, id) async {
    return comCorpo(req, (b) async => _json(await safety.extend(u, id, b)));
  }));
  router.post('/safety/sessions/<id>/arrived',
      rotaId((req, u, id) async => _json(await safety.arrived(u, id))));
  router.post('/safety/sessions/<id>/sos',
      rotaId((req, u, id) async => _json(await safety.sos(u, id))));

  // Notificacoes.
  router.get('/notifications', rota((req, u) async {
    final String? txt = req.url.queryParameters['since'];
    int? since;
    if (txt != null && txt.isNotEmpty) {
      since = int.tryParse(txt.trim());
      if (since == null || since < 0) return _erro(400, 'since invalido');
    }
    return _json({'notifications': await safety.notifications(u, sinceMs: since)});
  }));
  router.post('/notifications/<id>/read', rotaId((req, u, id) async {
    await safety.markRead(u, id);
    return Response(204);
  }));

  // Tokens de push.
  router.post('/push/tokens', rota((req, u) async {
    return comCorpo(req, (b) async {
      final Object? token = b['token'];
      final Object? plataforma = b['platform'];
      if (token is! String ||
          token.trim().isEmpty ||
          token.length > tamanhoMaximoTokenPush) {
        return _erro(400, 'token invalido');
      }
      if (plataforma != 'android' && plataforma != 'ios') {
        return _erro(400, 'platform precisa ser android ou ios');
      }
      await safety.registerPushToken(u, token.trim(), plataforma as String);
      return Response(204);
    });
  }));
  router.delete('/push/tokens/<token>', rotaId((req, u, token) async {
    // O segmento chega como veio na URL; tokens do FCM tem ':' (%3A).
    String t;
    try {
      t = Uri.decodeComponent(token);
    } on ArgumentError {
      return _erro(400, 'token invalido');
    }
    await safety.deletePushToken(u, t);
    return Response(204);
  }));

  // Link publico, sem conta.
  router.get('/s/<token>', (Request req, String token) async {
    final bool comoJson = token.endsWith('.json');
    final String t =
        comoJson ? token.substring(0, token.length - '.json'.length) : token;
    final PublicSessionView? v = await safety.publicView(t);
    return comoJson ? paginaPublicaJson(v) : paginaPublicaHtml(v);
  });
}

Future<Response> _protegida(
  Request req,
  Future<UserRecord?> Function(Request) autenticar,
  Future<Response> Function(UserRecord) h,
) async {
  final UserRecord? u = await autenticar(req);
  if (u == null) return _erro(401, 'nao autorizado');
  try {
    return await h(u);
  } on SafetyError catch (e) {
    return _erro(e.status, e.message);
  }
}

// ------------------------------------------------------------ link publico

const String mensagemLinkExpirado = 'Este link expirou';

/// Cabecalhos do link publico: sem cache, sem indexacao, sem Referer (o
/// token nao vaza para o OpenStreetMap) e nada carregado de fora.
const Map<String, String> _cabecalhosPublicos = {
  'cache-control': 'no-store',
  'x-robots-tag': 'noindex, nofollow',
  'referrer-policy': 'no-referrer',
  'x-content-type-options': 'nosniff',
  'x-frame-options': 'DENY',
};

Response paginaPublicaJson(PublicSessionView? v) => Response(
      v == null ? 404 : 200,
      body: jsonEncode(v == null ? {'error': mensagemLinkExpirado} : v.toJson()),
      headers: {..._cabecalhosPublicos, 'content-type': 'application/json'},
    );

/// Escape de HTML para texto e atributos.
String escaparHtml(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');

String _iso(int ms) =>
    DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toIso8601String();

/// Hora em UTC no HTML; o script da pagina troca pela hora local de quem
/// abre (sem script, fica a hora UTC com o rotulo).
String _hora(int ms) {
  final DateTime d = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  final String hh = d.hour.toString().padLeft(2, '0');
  final String mm = d.minute.toString().padLeft(2, '0');
  return '<time datetime="${_iso(ms)}">$hh:$mm UTC</time>';
}

String _idade(int ms) {
  final int min = ms ~/ 60000;
  if (min < 1) return 'ha menos de 1 min';
  if (min < 60) return 'ha $min min';
  final int h = min ~/ 60;
  return 'ha $h h';
}

const String _estilo = 'body{font-family:system-ui,sans-serif;margin:0;'
    'padding:16px;line-height:1.5;background:#fff;color:#111}'
    'main{max-width:32rem;margin:0 auto}h1{font-size:1.4rem}'
    '.situacao{font-size:1.2rem;font-weight:600}'
    'a{color:#0645ad}'
    '@media (prefers-color-scheme:dark){body{background:#111;color:#eee}'
    'a{color:#8ab4f8}}';

// Troca o texto de cada <time> pela hora local de quem abre a pagina.
const String _script = "document.querySelectorAll('time').forEach(function(t){"
    "var d=new Date(t.getAttribute('datetime'));"
    "if(!isNaN(d))t.textContent=d.toLocaleTimeString([],"
    "{hour:'2-digit',minute:'2-digit'});});";

String _documento(String titulo, String corpo, {bool atualizar = false}) =>
    '<!doctype html><html lang="pt-BR"><head><meta charset="utf-8">'
    '<meta name="viewport" content="width=device-width, initial-scale=1">'
    '<meta name="robots" content="noindex, nofollow">'
    '<meta name="referrer" content="no-referrer">'
    '${atualizar ? '<meta http-equiv="refresh" content="30">' : ''}'
    '<title>${escaparHtml(titulo)}</title><style>$_estilo</style></head>'
    '<body><main>$corpo</main><script>$_script</script></body></html>';

Response paginaPublicaHtml(PublicSessionView? v) {
  final Map<String, String> cab = {
    ..._cabecalhosPublicos,
    'content-type': 'text/html; charset=utf-8',
    'content-security-policy': "default-src 'none'; style-src 'unsafe-inline'; "
        "script-src 'unsafe-inline'; base-uri 'none'; form-action 'none'; "
        "frame-ancestors 'none'",
  };
  if (v == null) {
    return Response(404,
        body: _documento('Rastro Seguro',
            '<h1>$mensagemLinkExpirado</h1>'
            '<p>O acompanhamento terminou ou o endereco esta incorreto.</p>'),
        headers: cab);
  }
  final String nome = escaparHtml(v.firstName);
  final String situacao = switch (v.state) {
    'arrived' => 'Chegou${v.sinceMs == null ? '' : ' as ${_hora(v.sinceMs!)}'}',
    'no_response' => 'Nao respondeu desde '
        '${v.sinceMs == null ? '' : _hora(v.sinceMs!)}',
    'ended' => 'Acompanhamento encerrado sem confirmacao de chegada',
    _ => 'Em atividade',
  };
  final StringBuffer b = StringBuffer()
    ..write('<h1>Rastro Seguro: $nome</h1>')
    ..write('<p class="situacao" role="status">$situacao</p>')
    ..write('<p>Horario previsto de chegada: ${_hora(v.etaMs)}</p>');
  if (v.lastPosition == null) {
    b.write('<p>Ainda sem posicao conhecida.</p>');
  } else {
    b
      ..write('<p>Ultima posicao: ${_idade(v.lastPositionAgeMs!)}')
      ..write(v.lastPosition!.accuracyM == null
          ? ''
          : ' (precisao de ${v.lastPosition!.accuracyM!.round()} m)')
      ..write('.</p>')
      ..write('<p><a href="${escaparHtml(v.mapUrl!)}" rel="noopener noreferrer">'
          'Abrir a ultima posicao no mapa</a></p>');
  }
  b.write('<p><small>Esta pagina se atualiza a cada 30 segundos.</small></p>');
  return Response(200,
      body: _documento('Rastro Seguro: ${v.firstName}', b.toString(),
          atualizar: true),
      headers: cab);
}

final RegExp _caminhoLink = RegExp(r'/s/[^\s?/]+');
final RegExp _caminhoTokenPush = RegExp(r'/push/tokens/[^\s?/]+');

/// Para o log de requisicoes: o token do link publico e o token de push sao
/// segredos e nao vao para o log.
String ocultarSegredosDoCaminho(String linha) => linha
    .replaceAll(_caminhoLink, '/s/<token>')
    .replaceAll(_caminhoTokenPush, '/push/tokens/<token>');
