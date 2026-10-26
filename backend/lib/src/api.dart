// Monta o roteador HTTP da API. Handlers recebem um ActivityStore e um
// UserStore, entao dao para testar sem banco. Contrato com o app: POST
// /uploads recebe o arquivo FIT como corpo (application/octet-stream) e
// devolve { "uploadId": ... }. Tudo exceto /health e /auth/register|login
// exige `Authorization: Bearer <token>`.
library;

import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'activity_store.dart';
import 'auth/password.dart';
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

Handler createApi(
  ActivityStore store,
  UserStore users, {
  String Function()? genId,
  String Function()? genUserId,
  int Function()? nowMs,
  int passwordIterations = defaultPbkdf2Iterations,
}) {
  final newId = genId ?? () => _defaultId('up');
  final newUserId = genUserId ?? () => _defaultId('usr');
  final now = nowMs ?? () => DateTime.now().millisecondsSinceEpoch;
  final router = Router();

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
    final UserRecord? u = await users.findByEmail(email);
    if (u == null) {
      hashFantasma ??=
          hashPassword('senha-fantasma', iterations: passwordIterations);
      verifyPassword(senha, hashFantasma!);
      return _erro(401, 'email ou senha incorretos');
    }
    if (!verifyPassword(senha, u.passwordHash)) {
      return _erro(401, 'email ou senha incorretos');
    }
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
