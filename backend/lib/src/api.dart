// Monta o roteador HTTP da API. Handlers recebem um ActivityStore, um
// UserStore e um Mailer, entao dao para testar sem banco nem SMTP. A fonte
// de verdade do contrato com o app e docs/CONTRATO.md. Tudo exceto /health,
// /auth/register|login e /auth/password/forgot|reset exige
// `Authorization: Bearer <token>`.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io' show HttpConnectionInfo, stderr;
import 'dart:math';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'activity_store.dart';
import 'auth/password.dart';
import 'auth/rate_limiter.dart';
import 'auth/tokens.dart';
import 'fit_decoder.dart';
import 'mailer.dart';
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

/// Validade do codigo de recuperacao de senha.
const Duration validadeCodigoReset = Duration(minutes: 15);

/// Tentativas (certas ou erradas) que um codigo de recuperacao aceita.
const int tentativasCodigoReset = 5;

/// Iteracoes do PBKDF2 do codigo de recuperacao. Leve de proposito: o codigo
/// vive 15 min e aceita 5 tentativas; o hash so evita guardar em claro.
const int iteracoesCodigoReset = 1000;

/// Tamanho maximo do nome de uma atividade (em caracteres Unicode).
const int nomeAtividadeMaximo = 120;

const int _limitePadrao = 20;
const int _limiteMaximo = 100;

/// Limites de tentativa das rotas de conta. Os padroes sao o contrato com o
/// app; os testes injetam outros valores quando precisam.
class AuthRateLimits {
  const AuthRateLimits({
    this.loginFailuresPerEmail = 5,
    this.loginFailuresPerIp = 20,
    this.loginWindow = const Duration(minutes: 15),
    this.registrationsPerIp = 10,
    this.registerWindow = const Duration(hours: 1),
    this.forgotPerEmail = 3,
    this.forgotPerIp = 10,
    this.forgotWindow = const Duration(hours: 1),
    this.passwordChecksPerUser = 5,
    this.passwordCheckWindow = const Duration(minutes: 15),
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

  /// Pedidos de recuperacao de senha por email e por IP (todos contam,
  /// email existente ou nao) dentro de [forgotWindow].
  final int forgotPerEmail;
  final int forgotPerIp;
  final Duration forgotWindow;

  /// Senha atual errada em POST /auth/password/change e DELETE /me, por
  /// usuario, dentro de [passwordCheckWindow]. Impede que um token roubado
  /// sirva para adivinhar a senha.
  final int passwordChecksPerUser;
  final Duration passwordCheckWindow;
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

/// Cursor opaco da listagem: base64url (sem padding) de "<sortKey>:<id>".
String _codificarCursor(UploadRecord r) =>
    base64Url.encode(utf8.encode('${r.sortKey}:${r.id}')).replaceAll('=', '');

/// Null quando o cursor nao e um que a API emitiu.
ActivityCursor? _decodificarCursor(String texto) {
  try {
    final String bruto =
        utf8.decode(base64Url.decode(base64Url.normalize(texto)));
    final int sep = bruto.indexOf(':');
    if (sep <= 0 || sep == bruto.length - 1) return null;
    final int? k = int.tryParse(bruto.substring(0, sep));
    if (k == null) return null;
    return ActivityCursor(k, bruto.substring(sep + 1));
  } on FormatException {
    return null;
  }
}

/// Inteiro >= 0 de um header; qualquer outra coisa = null (ignorado).
int? _headerInteiro(Request req, String nome) {
  final String? v = req.headers[nome]?.trim();
  if (v == null || v.isEmpty) return null;
  final int? n = int.tryParse(v);
  return (n == null || n < 0) ? null : n;
}

/// Numero finito >= 0 de um header; qualquer outra coisa = null (ignorado).
double? _headerNumero(Request req, String nome) {
  final String? v = req.headers[nome]?.trim();
  if (v == null || v.isEmpty) return null;
  final double? n = double.tryParse(v);
  return (n == null || !n.isFinite || n < 0) ? null : n;
}

/// Metadados do upload: headers do app (invalidos sao ignorados) mais os
/// derivados dos timestamps dos records do FIT. So os records com posicao
/// valida sao considerados (sao os que o decodificador devolve).
ActivityMetadata _metadadosDoUpload(Request req, List<int> fit) {
  final String? tipoTxt = req.headers['x-activity-type']?.trim().toLowerCase();
  final String? tipo =
      (tipoTxt != null && tiposDeAtividade.contains(tipoTxt)) ? tipoTxt : null;
  final int? rpeTxt = _headerInteiro(req, 'x-rpe');
  final int? rpe = (rpeTxt != null && rpeTxt >= 1 && rpeTxt <= 10) ? rpeTxt : null;
  final String? humorTxt = req.headers['x-mood']?.trim().toLowerCase();
  final String? humor =
      (humorTxt != null && humores.contains(humorTxt)) ? humorTxt : null;
  final List<FitTrackPoint>? pontos = decodificarPontos(fit);
  int? primeiro;
  int? elapsed;
  if (pontos != null && pontos.isNotEmpty) {
    final List<int> ts = [for (final p in pontos) p.timestampUnixMs];
    primeiro = ts.reduce(min);
    elapsed = ts.reduce(max) - primeiro;
  }
  return ActivityMetadata(
    activityType: tipo,
    startTimeMs: _headerInteiro(req, 'x-start-time') ?? primeiro,
    elapsedTimeMs: elapsed,
    timerTimeMs: _headerInteiro(req, 'x-timer-time-ms'),
    distanceMeters: _headerNumero(req, 'x-distance-meters'),
    rpe: rpe,
    mood: humor,
  );
}

/// Nome de arquivo seguro para content-disposition: so [A-Za-z0-9._-].
String _nomeArquivoSeguro(String base) =>
    base.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');

/// Codigo de recuperacao: 6 digitos de Random.secure().
String _gerarCodigo(Random rnd) =>
    rnd.nextInt(1000000).toString().padLeft(6, '0');

Handler createApi(
  ActivityStore store,
  UserStore users, {
  Mailer? mailer,
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
  final Mailer correio = mailer ?? ConsoleMailer();
  final Random rndSeguro = Random.secure();
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
  final esquecidosPorEmail = RateLimiter(
      maxAttempts: rateLimits.forgotPerEmail,
      window: rateLimits.forgotWindow,
      nowMs: now);
  final esquecidosPorIp = RateLimiter(
      maxAttempts: rateLimits.forgotPerIp,
      window: rateLimits.forgotWindow,
      nowMs: now);
  final senhaErradaPorUsuario = RateLimiter(
      maxAttempts: rateLimits.passwordChecksPerUser,
      window: rateLimits.passwordCheckWindow,
      nowMs: now);

  // Hash descartavel para o login de email inexistente gastar o mesmo tempo
  // que o de senha errada (nao revela, pelo tempo, quais emails existem).
  String? hashFantasma;
  // Idem para o codigo de recuperacao de email inexistente.
  String? codigoFantasma;

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

  router.get('/health', (Request req) async {
    bool ok;
    try {
      ok = await store.ping().timeout(const Duration(seconds: 3));
    } catch (_) {
      ok = false;
    }
    return ok
        ? _json({'status': 'ok', 'db': 'ok'})
        : _json({'status': 'degraded', 'db': 'erro'}, status: 503);
  });

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

  router.post('/auth/logout-all', protegido((req, u) async {
    await users.deleteSessionsForUser(u.id);
    return Response(204);
  }));

  /// Confere a senha atual de [u] para change e DELETE /me. Devolve a
  /// resposta de erro (429 ou 403) ou null se a senha confere.
  Response? conferirSenhaAtual(UserRecord u, String senha) {
    final Duration? espera = senhaErradaPorUsuario.check(u.id);
    if (espera != null) return _muitasTentativas(espera);
    if (!verifyPassword(senha, u.passwordHash)) {
      senhaErradaPorUsuario.recordFailure(u.id);
      // 403 e nao 401: a sessao continua valida, so a senha nao confere.
      return _erro(403, 'senha atual incorreta');
    }
    senhaErradaPorUsuario.reset(u.id);
    return null;
  }

  router.post('/auth/password/change', protegido((req, u) async {
    final body = await _readJson(req);
    if (body == null) return _erro(400, 'corpo JSON invalido');
    final String atual = _texto(body, 'currentPassword') ?? '';
    final String nova = _texto(body, 'newPassword') ?? '';
    if (nova.runes.length < _senhaMinima) {
      return _erro(400, 'senha precisa ter ao menos $_senhaMinima caracteres');
    }
    final Response? negado = conferirSenhaAtual(u, atual);
    if (negado != null) return negado;
    await users.updatePasswordHash(
        u.id, hashPassword(nova, iterations: passwordIterations));
    // A sessao usada segue valida; as outras (outros aparelhos) caem.
    final String atualHash =
        hashToken(bearerToken(req.headers['authorization'])!);
    await users.deleteSessionsForUser(u.id, exceptTokenHash: atualHash);
    return Response(204);
  }));

  router.post('/auth/password/forgot', (Request req) async {
    final body = await _readJson(req);
    if (body == null) return _erro(400, 'corpo JSON invalido');
    final String email = _normalizarEmail(_texto(body, 'email') ?? '');
    final String ip = ipDe(req);
    // Todo pedido conta (email existente ou nao); bloqueado nao conta.
    final Duration? espera = _maiorEspera(
        esquecidosPorEmail.check(email), esquecidosPorIp.check(ip));
    if (espera != null) return _muitasTentativas(espera);
    esquecidosPorEmail.recordFailure(email);
    esquecidosPorIp.recordFailure(ip);

    final UserRecord? u = email.isEmpty ? null : await users.findByEmail(email);
    final String codigo = _gerarCodigo(rndSeguro);
    // Hash calculado nos dois casos para o tempo nao revelar se o email existe.
    final String codigoHash =
        hashPassword(codigo, iterations: iteracoesCodigoReset);
    if (u != null) {
      final int agora = now();
      // Um pedido por usuario: este substitui (e invalida) o anterior.
      await users.savePasswordReset(PasswordResetRecord(
        userId: u.id,
        codeHash: codigoHash,
        createdAtMs: agora,
        expiresAtMs: agora + validadeCodigoReset.inMilliseconds,
      ));
      // Sem await: a demora do SMTP revelaria que o email existe. Falha de
      // envio vai para o log (sem o codigo) e o usuario pode pedir de novo.
      unawaited(correio
          .sendPasswordResetCode(
              to: u.email, code: codigo, validFor: validadeCodigoReset)
          .catchError((Object e) {
        stderr.writeln('falha ao enviar email de recuperacao: $e');
      }));
    }
    return _json({'status': 'ok'}, status: 202);
  });

  router.post('/auth/password/reset', (Request req) async {
    final body = await _readJson(req);
    if (body == null) return _erro(400, 'corpo JSON invalido');
    final String email = _normalizarEmail(_texto(body, 'email') ?? '');
    final String codigo = (_texto(body, 'code') ?? '').trim();
    final String nova = _texto(body, 'newPassword') ?? '';
    // Antes de olhar o codigo: senha curta nao gasta tentativa.
    if (nova.runes.length < _senhaMinima) {
      return _erro(400, 'senha precisa ter ao menos $_senhaMinima caracteres');
    }
    Response invalido() => _erro(400, 'codigo invalido ou expirado');

    final UserRecord? u = email.isEmpty ? null : await users.findByEmail(email);
    if (u == null) {
      // Mesmo custo de um codigo conferido, mesma resposta.
      codigoFantasma ??=
          hashPassword('000000', iterations: iteracoesCodigoReset);
      verifyPassword(codigo, codigoFantasma!);
      return invalido();
    }
    // Consome a tentativa antes de conferir: tentativas simultaneas nao
    // passam do limite. Inexistente, expirado ou esgotado = null.
    final PasswordResetRecord? pedido = await users.consumePasswordResetAttempt(
        u.id,
        nowMs: now(),
        maxAttempts: tentativasCodigoReset);
    if (pedido == null) {
      codigoFantasma ??=
          hashPassword('000000', iterations: iteracoesCodigoReset);
      verifyPassword(codigo, codigoFantasma!);
      return invalido();
    }
    // verifyPassword compara em tempo constante; formato errado = falso.
    final bool confere = RegExp(r'^\d{6}$').hasMatch(codigo) &
        verifyPassword(codigo, pedido.codeHash);
    if (!confere) {
      if (pedido.attempts >= tentativasCodigoReset) {
        await users.deletePasswordReset(u.id);
      }
      return invalido();
    }
    await users.deletePasswordReset(u.id);
    final UserRecord? atualizado = await users.updatePasswordHash(
        u.id, hashPassword(nova, iterations: passwordIterations));
    if (atualizado == null) return invalido();
    // Quem tinha a senha antiga (ou um token vazado) perde o acesso.
    await users.deleteSessionsForUser(u.id);
    falhasPorEmail.reset(email);
    return abrirSessao(atualizado, status: 200);
  });

  router.delete('/me', protegido((req, u) async {
    final body = await _readJson(req);
    if (body == null) return _erro(400, 'corpo JSON invalido');
    final Response? negado =
        conferirSenhaAtual(u, _texto(body, 'password') ?? '');
    if (negado != null) return negado;
    // No Postgres o delete do usuario leva sessoes, codigos e uploads numa
    // so instrucao (FK em cascata); o segundo passo cobre o store em memoria.
    await users.deleteUser(u.id);
    await store.deleteAllForUser(u.id);
    return Response(204);
  }));

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
    // outro com 201 (os metadados do reenvio sao ignorados).
    final id = newId();
    final rec = await store.saveUpload(bytes,
        userId: u.id,
        activityGuid: guid,
        metadata: _metadadosDoUpload(req, bytes),
        nowMs: now(),
        id: id);
    return _json(rec.toJson(), status: rec.id == id ? 201 : 200);
  }));

  // Upload de outro usuario responde igual a inexistente (404), para nao
  // revelar que o id existe. /uploads/<id> e /activities/<id> sao o mesmo
  // recurso.
  Future<Response> lerAtividade(Request req, UserRecord u, String id) async {
    final rec = await store.getUpload(id, userId: u.id);
    if (rec == null) return _erro(404, 'nao encontrado');
    return _json(rec.toJson());
  }

  // Rota como Feature GeoJSON. Tres situacoes distintas:
  //  - upload inexistente (ou alheio) -> 404
  //  - upload existe mas sem rota     -> 204 (o recurso existe, so nao tem
  //    representacao; 404 aqui faria o cliente achar que o upload sumiu)
  //  - upload com rota                -> 200 com a Feature
  Future<Response> lerRota(Request req, UserRecord u, String id) async {
    final rec = await store.getUpload(id, userId: u.id);
    if (rec == null) return _erro(404, 'nao encontrado');
    final rota = await store.getRoute(id, userId: u.id);
    if (rota == null) return Response(204);
    return _json(rota.toFeatureJson());
  }

  FutureOr<Response> Function(Request, String) comId(
          Future<Response> Function(Request, UserRecord, String) h) =>
      (Request req, String id) async {
        final UserRecord? u = await autenticar(req);
        if (u == null) return _naoAutorizado();
        return h(req, u, id);
      };

  router.get('/uploads/<id>', comId(lerAtividade));
  router.get('/uploads/<id>/route', comId(lerRota));
  router.get('/activities/<id>', comId(lerAtividade));
  router.get('/activities/<id>/route', comId(lerRota));

  router.patch('/activities/<id>', comId((req, u, id) async {
    final body = await _readJson(req);
    if (body == null || !body.containsKey('name')) {
      return _erro(400, 'corpo precisa de {"name"}');
    }
    final Object? valor = body['name'];
    if (valor != null && valor is! String) {
      return _erro(400, 'name precisa ser texto ou null');
    }
    final String nome = (valor as String? ?? '').trim();
    if (nome.runes.length > nomeAtividadeMaximo) {
      return _erro(
          400, 'name pode ter no maximo $nomeAtividadeMaximo caracteres');
    }
    final rec = await store.updateName(id,
        userId: u.id, name: nome.isEmpty ? null : nome);
    if (rec == null) return _erro(404, 'nao encontrado');
    return _json(rec.toJson());
  }));

  router.delete('/activities/<id>', comId((req, u, id) async {
    if (!await store.deleteUpload(id, userId: u.id)) {
      return _erro(404, 'nao encontrado');
    }
    return Response(204);
  }));

  router.get('/activities/<id>/fit', comId((req, u, id) async {
    final rec = await store.getUpload(id, userId: u.id);
    final List<int>? bytes =
        rec == null ? null : await store.getFit(id, userId: u.id);
    if (rec == null || bytes == null) return _erro(404, 'nao encontrado');
    final String nome = _nomeArquivoSeguro(rec.activityGuid ?? rec.id);
    return Response(200, body: bytes, headers: {
      'content-type': 'application/vnd.ant.fit',
      'content-disposition': 'attachment; filename="$nome.fit"',
      'content-length': '${bytes.length}',
    });
  }));

  router.get('/activities', protegido((req, u) async {
    final Map<String, String> q = req.url.queryParameters;
    int limite = _limitePadrao;
    final String? limiteTxt = q['limit'];
    if (limiteTxt != null) {
      final int? n = int.tryParse(limiteTxt.trim());
      if (n == null || n < 1 || n > _limiteMaximo) {
        return _erro(400, 'limit precisa estar entre 1 e $_limiteMaximo');
      }
      limite = n;
    }
    ActivityCursor? depois;
    final String? cursorTxt = q['before'];
    if (cursorTxt != null && cursorTxt.isNotEmpty) {
      depois = _decodificarCursor(cursorTxt);
      if (depois == null) return _erro(400, 'cursor invalido');
    }
    // Um a mais para saber se existe proxima pagina sem segunda consulta.
    final List<UploadRecord> lista =
        await store.listPage(u.id, limit: limite + 1, after: depois);
    final bool temMais = lista.length > limite;
    final List<UploadRecord> pagina =
        temMais ? lista.sublist(0, limite) : lista;
    return _json({
      'activities': [for (final r in pagina) r.toJson()],
      'nextCursor': temMais ? _codificarCursor(pagina.last) : null,
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
