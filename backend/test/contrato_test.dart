// Testes das rotas de docs/CONTRATO.md acrescentadas depois da primeira
// versao: saude, logout-all, troca/recuperacao de senha, exclusao de conta,
// metadados e rotas de atividade, paginacao e stats por tipo. Stores em
// memoria e um mailer falso que captura o codigo.
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:strava_estudo_backend/src/activity_store.dart';
import 'package:strava_estudo_backend/src/api.dart';
import 'package:strava_estudo_backend/src/mailer.dart';
import 'package:strava_estudo_backend/src/user_store.dart';
import 'package:test/test.dart';

import 'fit_fixture.dart';

/// Captura os emails em vez de enviar.
class MailerFalso implements Mailer {
  final List<({String to, String code})> enviados = [];

  @override
  Future<void> sendPasswordResetCode({
    required String to,
    required String code,
    required Duration validFor,
  }) async {
    enviados.add((to: to, code: code));
  }
}

/// Store cujo banco "caiu".
class StoreForaDoAr extends InMemoryActivityStore {
  @override
  Future<bool> ping() async => throw StateError('conexao recusada');
}

const int _min = 60 * 1000;
const int _t0 = 1760000000000;

void main() {
  late InMemoryActivityStore store;
  late InMemoryUserStore users;
  late MailerFalso mailer;
  late Handler api;
  late int agora;
  late String tokenA;
  late String userIdA;
  late String ipAtual;

  Future<Map<String, dynamic>> jsonOf(Response r) async =>
      jsonDecode(await r.readAsString()) as Map<String, dynamic>;

  Map<String, String> bearer(String token) =>
      {'authorization': 'Bearer $token'};

  Future<Response> chamar(String metodo, String path,
          {Object? body, String? token, Map<String, String>? headers}) async =>
      api(Request(
        metodo,
        Uri.parse('http://x$path'),
        body: body == null ? null : jsonEncode(body),
        headers: {
          if (body != null) 'content-type': 'application/json',
          if (token != null) ...bearer(token),
          ...?headers,
        },
      ));

  Future<Response> login(String email, String senha) =>
      chamar('POST', '/auth/login', body: {'email': email, 'password': senha});

  Future<String> tokenLogin(String email, String senha) async =>
      (await jsonOf(await login(email, senha)))['token'] as String;

  Future<String> registrar(String email) async =>
      (await jsonOf(await chamar('POST', '/auth/register', body: {
        'email': email,
        'password': 'senha-boa-123',
        'displayName': 'X'
      })))['token'] as String;

  Future<Response> upload(List<int> body,
          {String? guid, String? token, Map<String, String>? headers}) async =>
      api(Request('POST', Uri.parse('http://x/uploads'), body: body, headers: {
        ...bearer(token ?? tokenA),
        if (guid != null) 'x-activity-guid': guid,
        ...?headers,
      }));

  List<int> fit(int n, {int t0 = _t0}) =>
      gerarFit(startTimeUnixMs: t0, pontos: rotaSintetica(n, t0));

  Future<int> status(String metodo, String path,
          {Object? body, String? token}) async =>
      (await chamar(metodo, path, body: body, token: token)).statusCode;

  void montar({ActivityStore? s}) {
    var n = 0;
    var u = 0;
    api = createApi(
      s ?? store,
      users,
      mailer: mailer,
      genId: () => 'id${(++n).toString().padLeft(3, '0')}',
      genUserId: () => 'u${++u}',
      nowMs: () => agora,
      passwordIterations: 2,
      clientIp: (_) => ipAtual,
    );
  }

  setUp(() async {
    store = InMemoryActivityStore();
    users = InMemoryUserStore();
    mailer = MailerFalso();
    agora = 1000;
    ipAtual = '10.0.0.1';
    montar();
    final r = await chamar('POST', '/auth/register', body: {
      'email': 'a@exemplo.com',
      'password': 'senha-boa-123',
      'displayName': 'A'
    });
    final body = await jsonOf(r);
    tokenA = body['token'] as String;
    userIdA = (body['user'] as Map)['id'] as String;
  });

  group('GET /health', () {
    test('200 com db ok', () async {
      final r = await chamar('GET', '/health');
      expect(r.statusCode, 200);
      expect(await jsonOf(r), {'status': 'ok', 'db': 'ok'});
    });

    test('503 degraded quando o banco nao responde', () async {
      montar(s: StoreForaDoAr());
      final r = await chamar('GET', '/health');
      expect(r.statusCode, 503);
      expect(await jsonOf(r), {'status': 'degraded', 'db': 'erro'});
    });
  });

  group('POST /auth/logout-all', () {
    test('204 e derruba todas as sessoes, inclusive a atual', () async {
      final outro = await tokenLogin('a@exemplo.com', 'senha-boa-123');
      final tokenB = await registrar('b@exemplo.com');
      final r = await chamar('POST', '/auth/logout-all', token: tokenA);
      expect(r.statusCode, 204);
      expect(await r.readAsString(), isEmpty);
      expect(await status('GET', '/me', token: tokenA), 401);
      expect(await status('GET', '/me', token: outro), 401);
      // Outro usuario nao e afetado.
      expect(await status('GET', '/me', token: tokenB), 200);
    });

    test('401 sem token', () async {
      expect(await status('POST', '/auth/logout-all'), 401);
    });
  });

  group('POST /auth/password/change', () {
    Future<Response> trocar(String atual, String nova, {String? token}) =>
        chamar('POST', '/auth/password/change',
            body: {'currentPassword': atual, 'newPassword': nova},
            token: token ?? tokenA);

    test('204, revoga as outras sessoes e mantem a atual', () async {
      final outro = await tokenLogin('a@exemplo.com', 'senha-boa-123');
      final r = await trocar('senha-boa-123', 'senha-nova-456');
      expect(r.statusCode, 204);
      expect(await status('GET', '/me', token: tokenA), 200);
      expect(await status('GET', '/me', token: outro), 401);
      expect((await login('a@exemplo.com', 'senha-boa-123')).statusCode, 401);
      expect((await login('a@exemplo.com', 'senha-nova-456')).statusCode, 200);
    });

    test('403 (nao 401) com senha atual errada; sessao segue valida', () async {
      final r = await trocar('errada-errada', 'senha-nova-456');
      expect(r.statusCode, 403);
      expect((await jsonOf(r))['error'], isA<String>());
      expect(await status('GET', '/me', token: tokenA), 200);
      expect((await login('a@exemplo.com', 'senha-boa-123')).statusCode, 200);
    });

    test('400 com senha nova curta', () async {
      expect((await trocar('senha-boa-123', '1234567')).statusCode, 400);
    });

    test('401 sem token', () async {
      final r = await chamar('POST', '/auth/password/change',
          body: {'currentPassword': 'x', 'newPassword': 'senha-nova-456'});
      expect(r.statusCode, 401);
    });
  });

  group('recuperacao de senha', () {
    Future<Response> esqueci(String email) =>
        chamar('POST', '/auth/password/forgot', body: {'email': email});

    Future<Response> redefinir(String email, String code,
            [String nova = 'senha-nova-456']) =>
        chamar('POST', '/auth/password/reset',
            body: {'email': email, 'code': code, 'newPassword': nova});

    String codigoErrado(String certo) =>
        certo == '000000' ? '000001' : '000000';

    test('forgot: 202 e envia codigo de 6 digitos; guarda so o hash', () async {
      final r = await esqueci('  A@Exemplo.com ');
      expect(r.statusCode, 202);
      expect(mailer.enviados, hasLength(1));
      expect(mailer.enviados.single.to, 'a@exemplo.com');
      final code = mailer.enviados.single.code;
      expect(code, matches(RegExp(r'^\d{6}$')));
      final pedido = users.resetDe(userIdA)!;
      expect(pedido.codeHash, isNot(contains(code)));
      expect(pedido.codeHash, startsWith(r'pbkdf2_sha256$'));
      expect(pedido.expiresAtMs, agora + 15 * _min);
    });

    test('forgot: 202 para email inexistente sem enviar nada', () async {
      final r = await esqueci('ninguem@exemplo.com');
      expect(r.statusCode, 202);
      expect(mailer.enviados, isEmpty);
      expect((await esqueci('')).statusCode, 202);
      expect(mailer.enviados, isEmpty);
    });

    test('forgot: 429 apos 3 pedidos por email na hora', () async {
      for (var i = 0; i < 3; i++) {
        ipAtual = '10.0.1.$i'; // IPs diferentes: so o limite por email conta
        expect((await esqueci('a@exemplo.com')).statusCode, 202);
      }
      final r = await esqueci('A@exemplo.com');
      expect(r.statusCode, 429);
      expect(int.parse(r.headers['retry-after']!), greaterThanOrEqualTo(1));
      expect(mailer.enviados, hasLength(3));
      agora += 60 * _min;
      expect((await esqueci('a@exemplo.com')).statusCode, 202);
    });

    test('forgot: 429 apos 10 pedidos por IP na hora (qualquer email)',
        () async {
      for (var i = 0; i < 10; i++) {
        expect((await esqueci('x$i@exemplo.com')).statusCode, 202);
      }
      expect((await esqueci('outro@exemplo.com')).statusCode, 429);
      ipAtual = '10.0.0.2';
      expect((await esqueci('outro@exemplo.com')).statusCode, 202);
    });

    test('reset com codigo certo: 200 {token,user}, revoga sessoes antigas',
        () async {
      final outro = await tokenLogin('a@exemplo.com', 'senha-boa-123');
      await esqueci('a@exemplo.com');
      final r = await redefinir('a@exemplo.com', mailer.enviados.last.code);
      expect(r.statusCode, 200);
      final body = await jsonOf(r);
      expect((body['user'] as Map)['id'], userIdA);
      final novo = body['token'] as String;
      expect(await status('GET', '/me', token: novo), 200);
      expect(await status('GET', '/me', token: tokenA), 401);
      expect(await status('GET', '/me', token: outro), 401);
      expect((await login('a@exemplo.com', 'senha-boa-123')).statusCode, 401);
      expect((await login('a@exemplo.com', 'senha-nova-456')).statusCode, 200);
      // Codigo e de uso unico.
      expect(users.resetDe(userIdA), isNull);
      final again = await redefinir(
          'a@exemplo.com', mailer.enviados.last.code, 'outra-senha-789');
      expect(again.statusCode, 400);
    });

    test('reset com codigo errado: 400 generico, senha nao muda', () async {
      await esqueci('a@exemplo.com');
      final r = await redefinir(
          'a@exemplo.com', codigoErrado(mailer.enviados.last.code));
      expect(r.statusCode, 400);
      expect((await jsonOf(r))['error'], 'codigo invalido ou expirado');
      expect((await login('a@exemplo.com', 'senha-boa-123')).statusCode, 200);
    });

    test('reset: mesma mensagem para email inexistente e sem pedido', () async {
      final a = await redefinir('ninguem@exemplo.com', '123456');
      final b = await redefinir('a@exemplo.com', '123456');
      expect(a.statusCode, 400);
      expect(b.statusCode, 400);
      expect((await jsonOf(a))['error'], 'codigo invalido ou expirado');
      expect((await jsonOf(b))['error'], 'codigo invalido ou expirado');
    });

    test('reset com codigo expirado (15 min) = 400', () async {
      await esqueci('a@exemplo.com');
      final code = mailer.enviados.last.code;
      agora += 15 * _min;
      final r = await redefinir('a@exemplo.com', code);
      expect(r.statusCode, 400);
      expect((await jsonOf(r))['error'], 'codigo invalido ou expirado');
    });

    test('codigo ainda vale 1 ms antes de expirar', () async {
      await esqueci('a@exemplo.com');
      agora += 15 * _min - 1;
      expect(
          (await redefinir('a@exemplo.com', mailer.enviados.last.code))
              .statusCode,
          200);
    });

    test('5 tentativas erradas invalidam o codigo (nem o certo passa)',
        () async {
      await esqueci('a@exemplo.com');
      final code = mailer.enviados.last.code;
      for (var i = 0; i < 5; i++) {
        expect(
            (await redefinir('a@exemplo.com', codigoErrado(code))).statusCode,
            400);
      }
      expect(users.resetDe(userIdA), isNull);
      expect((await redefinir('a@exemplo.com', code)).statusCode, 400);
    });

    test('4 erradas e a 5a certa ainda funciona', () async {
      await esqueci('a@exemplo.com');
      final code = mailer.enviados.last.code;
      for (var i = 0; i < 4; i++) {
        await redefinir('a@exemplo.com', codigoErrado(code));
      }
      expect((await redefinir('a@exemplo.com', code)).statusCode, 200);
    });

    test('pedido novo invalida o codigo anterior', () async {
      await esqueci('a@exemplo.com');
      final antigo = mailer.enviados.last.code;
      await esqueci('a@exemplo.com');
      final novo = mailer.enviados.last.code;
      if (antigo != novo) {
        expect((await redefinir('a@exemplo.com', antigo)).statusCode, 400);
      }
      expect((await redefinir('a@exemplo.com', novo)).statusCode, 200);
    });

    test('reset: 400 com senha nova curta, sem gastar tentativa', () async {
      await esqueci('a@exemplo.com');
      final code = mailer.enviados.last.code;
      final r = await redefinir('a@exemplo.com', code, '1234567');
      expect(r.statusCode, 400);
      expect(users.resetDe(userIdA)!.attempts, 0);
      expect((await redefinir('a@exemplo.com', code)).statusCode, 200);
    });
  });

  group('DELETE /me', () {
    test('204: apaga usuario, sessoes, codigos e atividades', () async {
      await upload(fit(5), guid: 'g1');
      await upload([1, 2, 3]);
      await chamar('POST', '/auth/password/forgot',
          body: {'email': 'a@exemplo.com'});
      final tokenB = await registrar('b@exemplo.com');
      await upload(fit(3), token: tokenB);

      final r = await chamar('DELETE', '/me',
          body: {'password': 'senha-boa-123'}, token: tokenA);
      expect(r.statusCode, 204);
      expect(await store.listUploads(userIdA), isEmpty);
      expect(users.resetDe(userIdA), isNull);
      expect(users.sessoesDe(userIdA), 0);
      expect(await users.findById(userIdA), isNull);
      expect(await status('GET', '/me', token: tokenA), 401);
      expect((await login('a@exemplo.com', 'senha-boa-123')).statusCode, 401);
      // B intacto.
      final listaB = (await jsonOf(
              await chamar('GET', '/activities', token: tokenB)))['activities']
          as List;
      expect(listaB, hasLength(1));
      // O email fica livre para um cadastro novo.
      expect(
          (await chamar('POST', '/auth/register', body: {
            'email': 'a@exemplo.com',
            'password': 'senha-boa-123',
            'displayName': 'A2'
          }))
              .statusCode,
          201);
    });

    test('403 com senha errada; nada e apagado', () async {
      await upload([1, 2]);
      final r = await chamar('DELETE', '/me',
          body: {'password': 'errada-errada'}, token: tokenA);
      expect(r.statusCode, 403);
      expect(await status('GET', '/me', token: tokenA), 200);
      expect(await store.listUploads(userIdA), hasLength(1));
    });

    test('401 sem token', () async {
      expect(await status('DELETE', '/me', body: {'password': 'senha-boa-123'}),
          401);
    });

    test('429 depois de 5 senhas erradas (change e delete somam)', () async {
      for (var i = 0; i < 3; i++) {
        expect(
            await status('DELETE', '/me',
                body: {'password': 'errada-$i'}, token: tokenA),
            403);
      }
      for (var i = 0; i < 2; i++) {
        expect(
            await status('POST', '/auth/password/change',
                body: {'currentPassword': 'e$i', 'newPassword': 'senha-x-123'},
                token: tokenA),
            403);
      }
      final r = await chamar('DELETE', '/me',
          body: {'password': 'senha-boa-123'}, token: tokenA);
      expect(r.statusCode, 429);
      expect(r.headers['retry-after'], isNotNull);
      agora += 15 * _min;
      expect(
          await status('DELETE', '/me',
              body: {'password': 'senha-boa-123'}, token: tokenA),
          204);
    });
  });

  group('objeto activity e metadados do upload', () {
    const Set<String> campos = {
      'id', 'uploadId', 'status', 'receivedAt', 'sizeBytes', 'activityGuid', //
      'activityType', 'name', 'startTime', 'elapsedTimeMs', 'timerTimeMs',
      'distanceMeters', 'pointCount', 'lengthMeters',
    };

    test('headers validos viram metadados; elapsed vem do FIT', () async {
      final r = await upload(fit(12), guid: 'g1', headers: {
        'x-activity-type': 'run',
        'x-start-time': '1760000000500',
        'x-timer-time-ms': '600000',
        'x-distance-meters': '1234.5',
      });
      expect(r.statusCode, 201);
      final body = await jsonOf(r);
      expect(body.keys.toSet(), campos);
      expect(body['activityType'], 'run');
      expect(body['startTime'], 1760000000500);
      expect(body['timerTimeMs'], 600000);
      expect(body['distanceMeters'], 1234.5);
      expect(body['name'], isNull);
      // rotaSintetica: um ponto por segundo -> 11 s entre o 1o e o 12o.
      expect(body['elapsedTimeMs'], 11000);
      expect(body['pointCount'], 12);
      // Mesmo objeto nas rotas de leitura.
      for (final path in ['/uploads/id001', '/activities/id001']) {
        expect(await jsonOf(await chamar('GET', path, token: tokenA)), body);
      }
    });

    test('sem headers: startTime do 1o record do FIT', () async {
      final body = await jsonOf(await upload(fit(4)));
      expect(body['startTime'], _t0);
      expect(body['elapsedTimeMs'], 3000);
      expect(body['activityType'], isNull);
      expect(body['timerTimeMs'], isNull);
      expect(body['distanceMeters'], isNull);
    });

    test('metadados invalidos sao ignorados (nao e erro)', () async {
      final r = await upload(fit(4), headers: {
        'x-activity-type': 'swim',
        'x-start-time': '-5',
        'x-timer-time-ms': 'abc',
        'x-distance-meters': '-1',
      });
      expect(r.statusCode, 201);
      final body = await jsonOf(r);
      expect(body['activityType'], isNull);
      expect(body['startTime'], _t0, reason: 'cai para o FIT');
      expect(body['timerTimeMs'], isNull);
      expect(body['distanceMeters'], isNull);
      final r2 = await upload([
        1,
        2,
        3
      ], headers: {
        'x-start-time': '12.5',
        'x-distance-meters': 'NaN',
        'x-timer-time-ms': '1e3',
      });
      final b2 = await jsonOf(r2);
      expect(b2['startTime'], isNull, reason: 'sem header valido e sem FIT');
      expect(b2['elapsedTimeMs'], isNull);
      expect(b2['distanceMeters'], isNull);
      expect(b2['timerTimeMs'], isNull);
      expect(b2['activityGuid'], isNull);
      expect(b2.keys.toSet(), campos);
    });

    test('GET /activities/<id> 404 para inexistente e de outro usuario',
        () async {
      await upload([1]);
      final tokenB = await registrar('b@exemplo.com');
      expect(await status('GET', '/activities/zzz', token: tokenA), 404);
      expect(await status('GET', '/activities/id001', token: tokenB), 404);
      expect(await status('GET', '/activities/id001'), 401);
    });
  });

  group('PATCH /activities/<id>', () {
    Future<Response> renomear(Object? body, {String id = 'id001'}) =>
        chamar('PATCH', '/activities/$id', body: body, token: tokenA);

    setUp(() async => upload(fit(3)));

    test('120 chars ok, 121 = 400', () async {
      final r = await renomear({'name': 'a' * 120});
      expect(r.statusCode, 200);
      expect((await jsonOf(r))['name'], 'a' * 120);
      final r2 = await renomear({'name': 'b' * 121});
      expect(r2.statusCode, 400);
      final atual =
          await jsonOf(await chamar('GET', '/activities/id001', token: tokenA));
      expect(atual['name'], 'a' * 120);
    });

    test('vazio ou null remove o nome', () async {
      await renomear({'name': 'Treino'});
      expect((await jsonOf(await renomear({'name': '  '})))['name'], isNull);
      await renomear({'name': 'Treino'});
      expect((await jsonOf(await renomear({'name': null})))['name'], isNull);
    });

    test('nome e trimado e volta no objeto completo', () async {
      final body = await jsonOf(await renomear({'name': '  Longao  '}));
      expect(body['name'], 'Longao');
      expect(body['id'], 'id001');
      expect(body['pointCount'], 3);
    });

    test('400 sem o campo ou com tipo errado; 404 inexistente ou alheio',
        () async {
      expect((await renomear({'outro': 1})).statusCode, 400);
      expect((await renomear({'name': 5})).statusCode, 400);
      expect((await renomear({'name': 'x'}, id: 'zzz')).statusCode, 404);
      final tokenB = await registrar('b@exemplo.com');
      final r = await chamar('PATCH', '/activities/id001',
          body: {'name': 'x'}, token: tokenB);
      expect(r.statusCode, 404);
    });
  });

  group('DELETE /activities/<id>', () {
    test('204, some da listagem, e reenvio do mesmo guid = 201', () async {
      expect((await upload(fit(3), guid: 'g-del')).statusCode, 201);
      final r = await chamar('DELETE', '/activities/id001', token: tokenA);
      expect(r.statusCode, 204);
      expect(await status('GET', '/activities/id001', token: tokenA), 404);
      expect(await status('DELETE', '/activities/id001', token: tokenA), 404);
      final again = await upload(fit(3), guid: 'g-del');
      expect(again.statusCode, 201);
      expect((await jsonOf(again))['id'], 'id002');
    });

    test('404 para upload de outro usuario (e ele continua la)', () async {
      await upload([1]);
      final tokenB = await registrar('b@exemplo.com');
      expect(await status('DELETE', '/activities/id001', token: tokenB), 404);
      expect(await status('GET', '/activities/id001', token: tokenA), 200);
    });
  });

  group('rota e FIT', () {
    test('/activities/<id>/route: 200, 204 sem rota, 404', () async {
      await upload(fit(6));
      await upload([1, 2, 3]);
      final r = await chamar('GET', '/activities/id001/route', token: tokenA);
      expect(r.statusCode, 200);
      final feature = await jsonOf(r);
      expect(feature['type'], 'Feature');
      expect((feature['geometry'] as Map)['coordinates'] as List, hasLength(6));
      expect(
          await status('GET', '/activities/id002/route', token: tokenA), 204);
      expect(await status('GET', '/activities/zzz/route', token: tokenA), 404);
    });

    test('/fit devolve os bytes identicos com os headers do contrato',
        () async {
      final List<int> original = fit(8);
      await upload(original, guid: 'act-123');
      final r = await chamar('GET', '/activities/id001/fit', token: tokenA);
      expect(r.statusCode, 200);
      expect(r.headers['content-type'], 'application/vnd.ant.fit');
      expect(r.headers['content-disposition'],
          'attachment; filename="act-123.fit"');
      final List<int> bytes = await r.read().expand((c) => c).toList();
      expect(bytes, original);
    });

    test('/fit sem guid usa o id; guid com caracteres estranhos e saneado',
        () async {
      await upload([9, 8, 7]);
      await upload([1], guid: 'a"b/c');
      final r1 = await chamar('GET', '/activities/id001/fit', token: tokenA);
      expect(r1.headers['content-disposition'],
          'attachment; filename="id001.fit"');
      expect(await r1.read().expand((c) => c).toList(), [9, 8, 7]);
      final r2 = await chamar('GET', '/activities/id002/fit', token: tokenA);
      expect(r2.headers['content-disposition'],
          'attachment; filename="a_b_c.fit"');
    });

    test('/fit 404 inexistente ou alheio; 401 sem token', () async {
      await upload([1]);
      final tokenB = await registrar('b@exemplo.com');
      expect(await status('GET', '/activities/zzz/fit', token: tokenA), 404);
      expect(await status('GET', '/activities/id001/fit', token: tokenB), 404);
      expect(await status('GET', '/activities/id001/fit'), 401);
    });
  });

  group('GET /activities paginado', () {
    Future<Map<String, dynamic>> pagina({int? limit, String? before}) async {
      final q = <String, String>{
        if (limit != null) 'limit': '$limit',
        if (before != null) 'before': before,
      };
      final uri =
          Uri(path: '/activities', queryParameters: q.isEmpty ? null : q);
      final r = await chamar('GET', uri.toString(), token: tokenA);
      expect(r.statusCode, 200);
      return jsonOf(r);
    }

    test('ordem por startTime desc (fallback receivedAt) e id desc', () async {
      // id001: startTime 5000 (header); id002: sem start -> receivedAt 1000;
      // id003: startTime 5000 (empata com id001); id004: FIT em _t0.
      await upload([1], headers: {'x-start-time': '5000'});
      await upload([2]);
      await upload([3], headers: {'x-start-time': '5000'});
      await upload(fit(3));
      final ids = [
        for (final a in (await pagina())['activities'] as List) (a as Map)['id']
      ];
      expect(ids, ['id004', 'id003', 'id001', 'id002']);
    });

    test('nao repete nem pula itens com empates', () async {
      // 25 atividades com so 4 valores distintos de startTime.
      for (var i = 0; i < 25; i++) {
        await upload([i + 1], headers: {'x-start-time': '${(i % 4) * 1000}'});
      }
      final esperado = [for (final r in await store.listUploads(userIdA)) r.id];
      for (final limite in [1, 3, 4, 7, 25, 100]) {
        final vistos = <String>[];
        String? cursor;
        var paginas = 0;
        do {
          final body = await pagina(limit: limite, before: cursor);
          final lista = body['activities'] as List;
          expect(lista.length, lessThanOrEqualTo(limite));
          vistos.addAll([for (final a in lista) (a as Map)['id'] as String]);
          cursor = body['nextCursor'] as String?;
          paginas++;
        } while (cursor != null);
        expect(vistos, esperado, reason: 'limit=$limite');
        expect(paginas, (25 / limite).ceil(), reason: 'limit=$limite');
      }
    });

    test('padrao 20; nextCursor null na ultima pagina', () async {
      for (var i = 0; i < 21; i++) {
        await upload([i + 1]);
      }
      final p1 = await pagina();
      expect(p1['activities'] as List, hasLength(20));
      expect(p1['nextCursor'], isA<String>());
      final p2 = await pagina(before: p1['nextCursor'] as String);
      expect(p2['activities'] as List, hasLength(1));
      expect(p2['nextCursor'], isNull);
      expect(p2.containsKey('nextCursor'), isTrue);
    });

    test('limit fora de 1..100 ou cursor invalido = 400', () async {
      for (final q in [
        'limit=0',
        'limit=101',
        'limit=abc',
        'limit=-1',
        'before=lixo!!',
        'before=${base64Url.encode(utf8.encode('semdoispontos'))}',
      ]) {
        expect(await status('GET', '/activities?$q', token: tokenA), 400,
            reason: q);
      }
      expect(await status('GET', '/activities?limit=1', token: tokenA), 200);
      expect(await status('GET', '/activities?limit=100', token: tokenA), 200);
    });

    test('cursor de A nao vaza nada para B', () async {
      for (var i = 0; i < 3; i++) {
        await upload([i + 1]);
      }
      final cursor = (await pagina(limit: 1))['nextCursor'] as String;
      final tokenB = await registrar('b@exemplo.com');
      final r =
          await chamar('GET', '/activities?before=$cursor', token: tokenB);
      expect(((await jsonOf(r))['activities'] as List), isEmpty);
    });
  });

  group('stats estendido', () {
    test('totalTimerTimeMs, distancia do app com fallback e byType', () async {
      await upload(fit(12), headers: {
        'x-activity-type': 'run',
        'x-timer-time-ms': '1000',
        'x-distance-meters': '5000',
      });
      await upload([
        1
      ], headers: {
        'x-activity-type': 'run',
        'x-timer-time-ms': '2000',
        'x-distance-meters': '3000',
      });
      // ride sem distancia informada: cai para o comprimento da rota.
      await upload(fit(6), headers: {'x-activity-type': 'ride'});
      // sem tipo: conta no total, nao entra em byType.
      await upload([2], headers: {'x-distance-meters': '100'});

      final ride = (await store.getUpload('id003', userId: userIdA))!;
      expect(ride.lengthMeters, greaterThan(0));

      final stats =
          (await jsonOf(await chamar('GET', '/me', token: tokenA)))['stats']
              as Map<String, dynamic>;
      expect(stats['activityCount'], 4);
      expect(stats['totalTimerTimeMs'], 3000);
      expect(stats['totalDistanceMeters'] as num,
          closeTo(5000 + 3000 + ride.lengthMeters! + 100, 1e-6));
      final byType = stats['byType'] as Map<String, dynamic>;
      expect(byType.keys.toSet(), {'run', 'ride'});
      expect(byType['run'], {'count': 2, 'distanceMeters': 8000.0});
      expect((byType['ride'] as Map)['count'], 1);
      expect((byType['ride'] as Map)['distanceMeters'] as num,
          closeTo(ride.lengthMeters!, 1e-6));
    });

    test('sem atividades: byType vazio e timer 0', () async {
      final stats =
          (await jsonOf(await chamar('GET', '/me', token: tokenA)))['stats']
              as Map<String, dynamic>;
      expect(stats['totalTimerTimeMs'], 0);
      expect(stats['byType'], isEmpty);
    });
  });

  group('SmtpConfig.fromEnv', () {
    test('le as variaveis e escolhe a porta pelo SSL', () {
      final c = SmtpConfig.fromEnv({
        'SMTP_HOST': 'smtp.exemplo.com',
        'SMTP_FROM': 'nao-responda@exemplo.com',
        'SMTP_USER': 'u',
        'SMTP_PASSWORD': 'p',
        'SMTP_SSL': 'true',
      });
      expect(c.port, 465);
      expect(c.ssl, isTrue);
      expect(c.username, 'u');
      final d = SmtpConfig.fromEnv({
        'SMTP_HOST': 'h',
        'SMTP_FROM': 'f@x.com',
        'SMTP_PORT': '2525',
      });
      expect(d.port, 2525);
      expect(d.ssl, isFalse);
      expect(d.username, isNull);
    });

    test('falta host/from ou porta invalida = StateError', () {
      expect(
          () => SmtpConfig.fromEnv({'SMTP_FROM': 'f@x.com'}), throwsStateError);
      expect(() => SmtpConfig.fromEnv({'SMTP_HOST': 'h'}), throwsStateError);
      expect(
          () => SmtpConfig.fromEnv(
              {'SMTP_HOST': 'h', 'SMTP_FROM': 'f@x.com', 'SMTP_PORT': 'x'}),
          throwsStateError);
    });

    test('ConsoleMailer escreve destinatario e codigo', () async {
      final linhas = <String>[];
      await ConsoleMailer(escrever: linhas.add).sendPasswordResetCode(
          to: 'a@x.com', code: '123456', validFor: const Duration(minutes: 15));
      expect(linhas.single, contains('a@x.com'));
      expect(linhas.single, contains('123456'));
    });
  });
}
