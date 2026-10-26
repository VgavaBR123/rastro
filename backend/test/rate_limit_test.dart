// Testes do limite de tentativas: o RateLimiter puro e o contrato 429 +
// Retry-After em /auth/login e /auth/register.
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:strava_estudo_backend/src/activity_store.dart';
import 'package:strava_estudo_backend/src/api.dart';
import 'package:strava_estudo_backend/src/auth/rate_limiter.dart';
import 'package:strava_estudo_backend/src/user_store.dart';
import 'package:test/test.dart';

const int _min = 60 * 1000;

void main() {
  group('RateLimiter', () {
    late int agora;
    late RateLimiter rl;

    setUp(() {
      agora = 0;
      rl = RateLimiter(
          maxAttempts: 3,
          window: const Duration(minutes: 10),
          nowMs: () => agora);
    });

    test('libera ate o maximo e bloqueia depois', () {
      expect(rl.check('k'), isNull);
      rl.recordFailure('k');
      agora = 1 * _min;
      rl.recordFailure('k');
      expect(rl.check('k'), isNull);
      agora = 2 * _min;
      rl.recordFailure('k');
      // Bloqueado ate o primeiro registro (t=0) sair da janela (t=10min).
      expect(rl.check('k'), const Duration(minutes: 8));
    });

    test('janela desliza: libera quando o registro mais antigo expira', () {
      for (final t in [0, 1, 2]) {
        agora = t * _min;
        rl.recordFailure('k');
      }
      agora = 10 * _min - 1;
      expect(rl.check('k'), const Duration(milliseconds: 1));
      agora = 10 * _min;
      expect(rl.check('k'), isNull);
      // So uma vaga abriu: nova falha bloqueia de novo ate t=1min+10min.
      rl.recordFailure('k');
      expect(rl.check('k'), const Duration(minutes: 1));
    });

    test('reset zera so a chave pedida', () {
      for (var i = 0; i < 3; i++) {
        rl.recordFailure('a');
        rl.recordFailure('b');
      }
      rl.reset('a');
      expect(rl.check('a'), isNull);
      expect(rl.check('b'), isNotNull);
    });

    test('poda chaves antigas na escrita (nao vaza memoria)', () {
      for (var i = 0; i < 100; i++) {
        rl.recordFailure('ip$i');
      }
      expect(rl.trackedKeys, 100);
      agora = 11 * _min;
      rl.recordFailure('novo');
      expect(rl.trackedKeys, 1);
    });

    test('check tambem apaga a chave que expirou por inteiro', () {
      rl.recordFailure('k');
      agora = 10 * _min;
      expect(rl.check('k'), isNull);
      expect(rl.trackedKeys, 0);
    });

    test('retryAfterSeconds arredonda para cima, minimo 1', () {
      expect(retryAfterSeconds(const Duration(milliseconds: 1)), 1);
      expect(retryAfterSeconds(Duration.zero), 1);
      expect(retryAfterSeconds(const Duration(milliseconds: 1000)), 1);
      expect(retryAfterSeconds(const Duration(milliseconds: 1001)), 2);
      expect(retryAfterSeconds(const Duration(minutes: 15)), 900);
    });
  });

  group('API', () {
    late Handler api;
    late int agora;
    late String ip;

    Future<Response> postJson(String path, Object body) async => api(Request(
          'POST',
          Uri.parse('http://x$path'),
          body: jsonEncode(body),
          headers: {'content-type': 'application/json'},
        ));

    Future<Response> registrar(String email) => postJson('/auth/register',
        {'email': email, 'password': 'senha-boa-123', 'displayName': 'Fulano'});

    Future<Response> login(String email, String senha) =>
        postJson('/auth/login', {'email': email, 'password': senha});

    Future<void> errarSenha(String email, int vezes) async {
      for (var i = 0; i < vezes; i++) {
        expect((await login(email, 'errada-$i')).statusCode, 401);
      }
    }

    Future<void> esperar429(Response r, int retryAfter) async {
      expect(r.statusCode, 429);
      expect(r.headers['retry-after'], '$retryAfter');
      expect(
          jsonDecode(await r.readAsString()), {'error': 'muitas tentativas'});
    }

    setUp(() async {
      agora = 1000000;
      ip = '10.0.0.1';
      api = createApi(
        InMemoryActivityStore(),
        InMemoryUserStore(),
        nowMs: () => agora,
        passwordIterations: 2,
        clientIp: (_) => ip,
      );
      expect((await registrar('a@exemplo.com')).statusCode, 201);
      expect((await registrar('b@exemplo.com')).statusCode, 201);
    });

    test('5 falhas: a 6a e 429 com Retry-After da janela restante', () async {
      await errarSenha('a@exemplo.com', 1);
      agora += 2 * _min;
      await errarSenha('a@exemplo.com', 4);
      agora += 30 * 1000;
      // Primeira falha expira 15 min depois dela: faltam 15 - 2.5 = 12.5 min.
      await esperar429(await login('a@exemplo.com', 'errada'), 750);
    });

    test('senha certa na 6a tentativa tambem e 429', () async {
      await errarSenha('a@exemplo.com', 5);
      await esperar429(await login('a@exemplo.com', 'senha-boa-123'), 900);
    });

    test('depois da janela volta a aceitar', () async {
      await errarSenha('a@exemplo.com', 5);
      agora += 15 * _min;
      expect((await login('a@exemplo.com', 'senha-boa-123')).statusCode, 200);
    });

    test('sucesso zera o contador do email', () async {
      await errarSenha('a@exemplo.com', 4);
      expect((await login('a@exemplo.com', 'senha-boa-123')).statusCode, 200);
      await errarSenha('a@exemplo.com', 5);
      expect((await login('a@exemplo.com', 'x')).statusCode, 429);
    });

    test('emails diferentes nao se afetam', () async {
      await errarSenha('a@exemplo.com', 5);
      expect((await login('a@exemplo.com', 'x')).statusCode, 429);
      expect((await login('b@exemplo.com', 'senha-boa-123')).statusCode, 200);
      expect((await login('b@exemplo.com', 'x')).statusCode, 401);
    });

    test('email com caixa e espacos diferentes conta como o mesmo', () async {
      await errarSenha('A@Exemplo.com', 2);
      await errarSenha(' a@EXEMPLO.COM ', 3);
      expect((await login('a@exemplo.com', 'senha-boa-123')).statusCode, 429);
    });

    test('email inexistente conta como falha', () async {
      await errarSenha('ninguem@exemplo.com', 5);
      await esperar429(await login('ninguem@exemplo.com', 'x'), 900);
    });

    test('limite por IP: 20 falhas com emails variados -> 429', () async {
      for (var i = 0; i < 20; i++) {
        expect((await login('x$i@exemplo.com', 'errada')).statusCode, 401);
      }
      // Bloqueia ate quem tem a senha certa, vindo desse IP.
      await esperar429(await login('a@exemplo.com', 'senha-boa-123'), 900);
      // Outro IP segue livre.
      ip = '10.0.0.2';
      expect((await login('a@exemplo.com', 'senha-boa-123')).statusCode, 200);
    });

    test('sucesso nao zera o contador do IP', () async {
      for (var i = 0; i < 19; i++) {
        await login('x$i@exemplo.com', 'errada');
      }
      expect((await login('a@exemplo.com', 'senha-boa-123')).statusCode, 200);
      expect((await login('y@exemplo.com', 'errada')).statusCode, 401);
      expect((await login('a@exemplo.com', 'senha-boa-123')).statusCode, 429);
    });

    test('register: 11o cadastro do mesmo IP na hora = 429', () async {
      // O setUp ja fez 2 cadastros deste IP; um deles repetido (409) conta.
      expect((await registrar('a@exemplo.com')).statusCode, 409);
      for (var i = 0; i < 7; i++) {
        expect((await registrar('n$i@exemplo.com')).statusCode, 201);
      }
      final r = await registrar('n99@exemplo.com');
      await esperar429(r, 3600);
      ip = '10.0.0.9';
      expect((await registrar('n99@exemplo.com')).statusCode, 201);
      ip = '10.0.0.1';
      agora += 60 * _min;
      expect((await registrar('n100@exemplo.com')).statusCode, 201);
    });

    test('outras rotas nao sao limitadas', () async {
      for (var i = 0; i < 30; i++) {
        final r = await api(Request('GET', Uri.parse('http://x/health')));
        expect(r.statusCode, 200);
      }
    });
  });

  test('extrator padrao: sem conexao = unknown; X-Forwarded-For so se ligado',
      () {
    final req = Request('GET', Uri.parse('http://x/'),
        headers: {'x-forwarded-for': '1.1.1.1, 2.2.2.2'});
    expect(extratorDeIp()(req), ipDesconhecido);
    expect(extratorDeIp(confiarEmForwardedFor: true)(req), '2.2.2.2');
  });
}
