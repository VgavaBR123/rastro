// Montagem comum dos testes do Rastro Seguro: API em memoria, relogio falso,
// ids previsiveis e um PushSender que captura as mensagens.
import 'dart:async';
import 'dart:convert';


import 'package:shelf/shelf.dart';
import 'package:strava_estudo_backend/src/activity_store.dart';
import 'package:strava_estudo_backend/src/api.dart';
import 'package:strava_estudo_backend/src/safety/push_sender.dart';
import 'package:strava_estudo_backend/src/safety/safety_service.dart';
import 'package:strava_estudo_backend/src/safety/safety_store.dart';
import 'package:strava_estudo_backend/src/user_store.dart';

const int seg = 1000;
const int minuto = 60 * seg;
const int hora = 60 * minuto;
const int t0 = 1760000000000;

class PushFalso implements PushSender {
  final List<PushMessage> enviadas = [];

  /// Tokens que o "provedor" diz que nao valem mais.
  final Set<String> invalidos = {};

  /// Quantos envios seguidos devolvem `failed` (falha passageira).
  int falhasPassageiras = 0;

  /// Se definido, todo envio fica pendurado ate ele completar.
  Completer<void>? travar;

  @override
  Future<PushResult> send(PushMessage m) async {
    enviadas.add(m);
    if (travar != null) await travar!.future;
    if (falhasPassageiras > 0) {
      falhasPassageiras--;
      return PushResult.failed;
    }
    return invalidos.contains(m.token)
        ? PushResult.invalidToken
        : PushResult.sent;
  }
}

/// Store em memoria que falha de proposito na N-esima gravacao da caixa de
/// entrada (contada a partir de [falharNaGravacao]).
class StoreFalhavel extends InMemorySafetyStore {
  int? _faltam;

  /// A [n]-esima chamada de addNotification daqui em diante lanca erro (uma
  /// vez so).
  void falharNaGravacao(int n) => _faltam = n;

  @override
  Future<void> addNotification(NotificationRecord n) async {
    if (_faltam != null) {
      _faltam = _faltam! - 1;
      if (_faltam == 0) {
        _faltam = null;
        throw StateError('falha simulada no INSERT da caixa de entrada');
      }
    }
    return super.addNotification(n);
  }
}

class Conta {
  Conta(this.token, this.id, this.email);
  final String token;
  final String id;
  final String email;
}

class Harness {
  Harness({SafetyConfig? config}) {
    final cfg = config ??
        const SafetyConfig(
          tickMs: 15 * seg,
          silenceMs: 5 * minuto,
          stopMs: 10 * minuto,
          checkMs: 2 * minuto,
          publicBaseUrl: 'https://rastro.exemplo',
        );
    var n = 0;
    var tok = 0;
    service = SafetyService(
      store: safety,
      users: users,
      config: cfg,
      push: push,
      nowMs: () => agora,
      genId: (p) => '${p}_${++n}',
      genShareToken: () => 'link${++tok}'.padRight(43, 'x'),
    );
    var u = 0;
    api = createApi(
      InMemoryActivityStore(),
      users,
      genUserId: () => 'usr_${++u}',
      nowMs: () => agora,
      passwordIterations: 2,
      clientIp: (_) => '10.0.0.1',
      rateLimits: const AuthRateLimits(registrationsPerIp: 1000),
      safety: service,
    );
  }

  final StoreFalhavel safety = StoreFalhavel();
  final InMemoryUserStore users = InMemoryUserStore();
  final PushFalso push = PushFalso();
  late final SafetyService service;
  late final Handler api;
  int agora = t0;

  Future<Response> chamar(String metodo, String path,
          {Object? body, String? token}) async =>
      api(Request(
        metodo,
        Uri.parse('http://x$path'),
        body: body == null ? null : jsonEncode(body),
        headers: {
          if (body != null) 'content-type': 'application/json',
          if (token != null) 'authorization': 'Bearer $token',
        },
      ));

  Future<Map<String, dynamic>> json(String metodo, String path,
      {Object? body, String? token, int esperado = 200}) async {
    final r = await chamar(metodo, path, body: body, token: token);
    final String texto = await r.readAsString();
    if (r.statusCode != esperado) {
      throw StateError('$metodo $path: ${r.statusCode} $texto');
    }
    return jsonDecode(texto) as Map<String, dynamic>;
  }

  Future<int> status(String metodo, String path,
          {Object? body, String? token}) async =>
      (await chamar(metodo, path, body: body, token: token)).statusCode;

  Future<Conta> conta(String email, {String nome = 'Fulana de Tal'}) async {
    final m = await json('POST', '/auth/register',
        body: {'email': email, 'password': 'senha-boa-123', 'displayName': nome},
        esperado: 201);
    return Conta(m['token'] as String, (m['user'] as Map)['id'] as String,
        email);
  }

  /// Convite de [dona] para [contato], ja aceito. Devolve o id do contato.
  Future<String> contatoAceito(Conta dona, Conta contato) async {
    final c = await json('POST', '/safety/contacts',
        body: {'email': contato.email}, token: dona.token, esperado: 201);
    final id = c['id'] as String;
    await json('POST', '/safety/contacts/$id/accept', token: contato.token);
    return id;
  }

  Future<Map<String, dynamic>> criarSessao(Conta dona, List<String> contatos,
          {int? etaMs}) =>
      json('POST', '/safety/sessions',
          body: {
            'activityGuid': 'act_1',
            'etaMs': etaMs ?? agora + hora,
            'contactIds': contatos,
          },
          token: dona.token,
          esperado: 201);

  Future<Map<String, dynamic>> posicao(Conta dona, String sessao,
          {double? lat = -23.55,
          double? lon = -46.63,
          bool moving = true,
          bool paused = false}) =>
      json('POST', '/safety/sessions/$sessao/positions',
          body: {
            'lat': lat,
            'lon': lon,
            'accuracyM': 5,
            'recordedAtMs': agora,
            'moving': moving,
            'paused': paused,
          },
          token: dona.token);

  Future<List<Map<String, dynamic>>> caixa(Conta c) async {
    final m = await json('GET', '/notifications', token: c.token);
    return [for (final n in m['notifications'] as List) n as Map<String, dynamic>];
  }

  Future<List<String>> tipos(Conta c) async =>
      [for (final n in await caixa(c)) n['type'] as String];

  /// Avanca o relogio em [ms] e roda um tick do vigia.
  Future<void> avancar(int ms) async {
    agora += ms;
    await service.tick();
  }
}
