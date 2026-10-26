// Monta o roteador HTTP da API. Handlers recebem um ActivityStore e um
// UserStore, entao dao para testar sem banco. Contrato com o app: POST
// /uploads recebe o arquivo FIT como corpo (application/octet-stream) e
// devolve { "uploadId": ... }. Tudo exceto /health e /auth/register|login
// exige `Authorization: Bearer <token>`.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io' show HttpConnectionInfo;

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'activity_store.dart';
import 'auth/password.dart';
import 'auth/rate_limiter.dart';
import 'auth/tokens.dart';
import 'user_store.dart';

Response _json(Object data, {int status = 200}) => Response(
      status,
      body: jsonEncode(data),
      headers: {'content-type': 'application/json'},
    );

Response _erro(int status, String mensagem) =>
    _json({'error': mensagem}, status: status);

Response _naoAutorizado() => _erro(401, 'nao autorizado');

Future<List<int>> _readBytes(Request req) async {
  final out = <int>[];
  await for (final chunk in req.read()) {
    out.addAll(chunk);
  }
  return out;
}

/// Corpo JSON como mapa; null se nao for um objeto JSON valido.
Future<Map<String, dynamic>?> _readJson(Request req) async {
  try {
    final Object? v = jsonDecode(await req.readAsString());
    return v is Map<String, dynamic> ? v : null;
  } on FormatException {
    return null;
  }
}

String? _texto(Map<String, dynamic> body, String campo) {
  final Object? v = body[campo];
  return v is String ? v : null;
}

/// Precisa de `@` e de ponto no dominio. Validacao de verdade so com email
/// de confirmacao; aqui so barramos o obviamente errado.
final RegExp _emailValido = RegExp(r'^[^@\s]+@[^@\s.]+(\.[^@\s.]+)+$');

String _normalizarEmail(String email) => email.trim().toLowerCase();

const int _senhaMinima = 8;

/// Limites de tentativa das rotas de conta. Os padroes sao o contrato com o
/// app; os testes injetam outros valores quando precisam.
class AuthRateLimits {
  const AuthRateLimits({
    this.loginFailuresPerEmail = 5,
    this.loginFailuresPerIp = 20,
    this.loginWindow = const Duration(minutes: 15),
    this.registrationsPerIp = 10,
    this.registerWindow = const Duration(hours: 1),
  });

  /// Falhas de login por email (normalizado) dentro de [loginWindow].
  final int loginFailuresPerEmail;

  /// Falhas de login por IP (qualquer email) dentro de [loginWindow]; barra
  /// quem testa muitos emails a partir do mesmo endereco.
  final int loginFailuresPerIp;
  final Duration loginWindow;

  /// Cadastros por IP (com sucesso ou nao) dentro de [registerWindow].
  final int registrationsPerIp;
  final Duration registerWindow;
}

/// Chave usada quando nao da para saber o IP (ex.: testes sem shelf_io).
const String ipDesconhecido = 'unknown';

/// IP do cliente pela conexao TCP (shelf_io). Por padrao NAO olha
/// X-Forwarded-For, que qualquer cliente pode inventar. Atras de um proxy
/// reverso confiavel, passe [confiarEmForwardedFor]: usa o ultimo endereco da
/// lista, que e o que o proxy imediato acrescentou.
String Function(Request) extratorDeIp({bool confiarEmForwardedFor = false}) =>
    (Request req) {
      if (confiarEmForwardedFor) {
        final String? xff = req.headers['x-forwarded-for'];
        if (xff != null) {
          final List<String> partes = [
            for (final p in xff.split(','))
              if (p.trim().isNotEmpty) p.trim()
          ];
          if (partes.isNotEmpty) return partes.last;
        }
      }
      final Object? info = req.context['shelf.io.connection_info'];
      if (info is HttpConnectionInfo) return info.remoteAddress.address;
      return ipDesconhecido;
    };

Response _muitasTentativas(Duration espera) => Response(
      429,
      body: jsonEncode({'error': 'muitas tentativas'}),
      headers: {
        'content-type': 'application/json',
        'retry-after': '${retryAfterSeconds(espera)}',
      },
    );

/// A maior das esperas (null = nenhuma bloqueia).
Duration? _maiorEspera(Duration? a, Duration? b) {
  if (a == null) return b;
  if (b == null) return a;
  return a > b ? a : b;
}

Handler createApi(
  ActivityStore store,
  UserStore users, {
  String Function()? genId,
  String Function()? genUserId,
  int Function()? nowMs,
  int passwordIterations = defaultPbkdf2Iterations,
  AuthRateLimits rateLimits = const AuthRateLimits(),
  String Function(Request)? clientIp,
}) {
  final newId = genId ?? () => _defaultId('up');
  final newUserId = genUserId ?? () => _defaultId('usr');
  final now = nowMs ?? () => DateTime.now().millisecondsSinceEpoch;
  final ipDe = clientIp ?? extratorDeIp();
  final router = Router();

  // Limites em memoria (instancia unica do servidor; ver rate_limiter.dart).
  // Um limitador por regra, entao chaves de email e de IP nao se misturam.
  final falhasPorEmail = RateLimiter(
      maxAttempts: rateLimits.loginFailuresPerEmail,
      window: rateLimits.loginWindow,
      nowMs: now);
  final falhasPorIp = RateLimiter(
      maxAttempts: rateLimits.loginFailuresPerIp,
      window: rateLimits.loginWindow,
      nowMs: now);
  final cadastrosPorIp = RateLimiter(
      maxAttempts: rateLimits.registrationsPerIp,
      window: rateLimits.registerWindow,
      nowMs: now);

  // Hash descartavel para o login de email inexistente gastar o mesmo tempo
  // que o de senha errada (nao revela, pelo tempo, quais emails existem).
  String? hashFantasma;

  Future<Response> abrirSessao(UserRecord user, {required int status}) async {
    final String token = generateToken();
    final int agora = now();
    await users.createSession(SessionRecord(
      tokenHash: hashToken(token),
      userId: user.id,
      createdAtMs: agora,
      expiresAtMs: agora + sessionLifetime.inMilliseconds,
    ));
    return _json({'token': token, 'user': user.toJson()}, status: status);
  }

  /// Usuario dono do Bearer, ou null (sem token, desconhecido, expirado).
  Future<UserRecord?> autenticar(Request req) async {
    final String? token = bearerToken(req.headers['authorization']);
    if (token == null) return null;
    final String h = hashToken(token);
    final SessionRecord? s = await users.findSession(h);
    if (s == null) return null;
    if (s.expiresAtMs <= now()) {
      await users.deleteSession(h);
      return null;
    }
    return users.findById(s.userId);
  }

  /// Envolve um handler que exige Bearer valido.
  FutureOr<Response> Function(Request) protegido(
          FutureOr<Response> Function(Request, UserRecord) h) =>
      (Request req) async {
        final UserRecord? u = await autenticar(req);
        if (u == null) return _naoAutorizado();
        return h(req, u);
      };

  router.get('/health', (Request req) => _json({'status': 'ok'}));

  router.post('/auth/register', (Request req) async {
    // Conta toda tentativa de cadastro do IP, com sucesso ou nao; bloqueada
    // nao conta (senao quem insiste nunca sai do bloqueio).
    final String ip = ipDe(req);
    final Duration? espera = cadastrosPorIp.check(ip);
    if (espera != null) return _muitasTentativas(espera);
    cadastrosPorIp.recordFailure(ip);

    final body = await _readJson(req);
    if (body == null) return _erro(400, 'corpo JSON invalido');
    final String email = _normalizarEmail(_texto(body, 'email') ?? '');
    final String senha = _texto(body, 'password') ?? '';
    final String nome = (_texto(body, 'displayName') ?? '').trim();
    if (!_emailValido.hasMatch(email)) return _erro(400, 'email invalido');
    if (senha.runes.length < _senhaMinima) {
      return _erro(400, 'senha precisa ter ao menos $_senhaMinima caracteres');
    }
    if (nome.isEmpty) return _erro(400, 'displayName obrigatorio');

    if (await users.findByEmail(email) != null) {
      return _erro(409, 'email ja cadastrado');
    }
    final UserRecord? criado = await users.createUser(UserRecord(
      id: newUserId(),
      email: email,
      passwordHash: hashPassword(senha, iterations: passwordIterations),
      displayName: nome,
      createdAtMs: now(),
    ));
    // Null aqui = outro cadastro do mesmo email ganhou a corrida.
    if (criado == null) return _erro(409, 'email ja cadastrado');
    return abrirSessao(criado, status: 201);
  });

  router.post('/auth/login', (Request req) async {
    final body = await _readJson(req);
    if (body == null) return _erro(400, 'corpo JSON invalido');
    final String email = _normalizarEmail(_texto(body, 'email') ?? '');
    final String senha = _texto(body, 'password') ?? '';
    final String ip = ipDe(req);

    // Bloqueado pelo email ou pelo IP: responde 429 antes de olhar a senha
    // (nem a correta passa) e sem gastar PBKDF2.
    final Duration? espera =
        _maiorEspera(falhasPorEmail.check(email), falhasPorIp.check(ip));
    if (espera != null) return _muitasTentativas(espera);

    Response falhou() {
      falhasPorEmail.recordFailure(email);
      falhasPorIp.recordFailure(ip);
      return _erro(401, 'email ou senha incorretos');
    }

    final UserRecord? u = await users.findByEmail(email);
    if (u == null) {
      // Email inexistente conta como falha igual a senha errada.
      hashFantasma ??=
          hashPassword('senha-fantasma', iterations: passwordIterations);
      verifyPassword(senha, hashFantasma!);
      return falhou();
    }
    if (!verifyPassword(senha, u.passwordHash)) return falhou();
    // Sucesso zera so o contador do email; o do IP segue valendo.
    falhasPorEmail.reset(email);
    return abrirSessao(u, status: 200);
  });

  router.post('/auth/logout', (Request req) async {
    final UserRecord? u = await autenticar(req);
    if (u == null) return _naoAutorizado();
    await users
        .deleteSession(hashToken(bearerToken(req.headers['authorization'])!));
    return Response(204);
  });

  router.get('/me', protegido((req, u) async {
    final UserStats stats = await store.statsFor(u.id);
    return _json({'user': u.toJson(), 'stats': stats.toJson()});
  }));

  router.patch('/me', protegido((req, u) async {
    final body = await _readJson(req);
    if (body == null) return _erro(400, 'corpo JSON invalido');
    final String nome = (_texto(body, 'displayName') ?? '').trim();
    if (nome.isEmpty) return _erro(400, 'displayName obrigatorio');
    final UserRecord? atualizado = await users.updateDisplayName(u.id, nome);
    if (atualizado == null) return _naoAutorizado();
    return _json({'user': atualizado.toJson()});
  }));

  router.post('/uploads', protegido((req, u) async {
    final bytes = await _readBytes(req);
    if (bytes.isEmpty) {
      return _erro(400, 'arquivo vazio');
    }
    final header = req.headers['x-activity-guid']?.trim();
    final guid = (header == null || header.isEmpty) ? null : header;
    // Idempotente por (usuario, atividade): reenvio da mesma atividade pelo
    // mesmo usuario devolve o upload que ja existe com 200, em vez de criar
    // outro com 201.
    final id = newId();
    final rec = await store.saveUpload(bytes,
        userId: u.id, activityGuid: guid, nowMs: now(), id: id);
    return _json(rec.toJson(), status: rec.id == id ? 201 : 200);
  }));

  // Upload de outro usuario responde igual a inexistente (404), para nao
  // revelar que o id existe.
  router.get('/uploads/<id>', (Request req, String id) async {
    final UserRecord? u = await autenticar(req);
    if (u == null) return _naoAutorizado();
    final rec = await store.getUpload(id, userId: u.id);
    if (rec == null) return _erro(404, 'nao encontrado');
    return _json(rec.toJson());
  });

  // Rota como Feature GeoJSON. Tres situacoes distintas:
  //  - upload inexistente (ou alheio) -> 404
  //  - upload existe mas sem rota     -> 204 (o recurso existe, so nao tem
  //    representacao; 404 aqui faria o cliente achar que o upload sumiu)
  //  - upload com rota                -> 200 com a Feature
  router.get('/uploads/<id>/route', (Request req, String id) async {
    final UserRecord? u = await autenticar(req);
    if (u == null) return _naoAutorizado();
    final rec = await store.getUpload(id, userId: u.id);
    if (rec == null) return _erro(404, 'nao encontrado');
    final rota = await store.getRoute(id, userId: u.id);
    if (rota == null) return Response(204);
    return _json(rota.toFeatureJson());
  });

  router.get('/activities', protegido((req, u) async {
    final list = await store.listUploads(u.id);
    return _json({
      'activities': [for (final r in list) r.toJson()]
    });
  }));

  return router.call;
}

int _seq = 0;
String _defaultId(String prefixo) {
  _seq++;
  final ts = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  return '${prefixo}_${ts}_$_seq';
}
