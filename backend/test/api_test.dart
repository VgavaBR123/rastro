// Testes dos handlers da API com stores em memoria (sem Postgres).
import 'dart:convert';
import 'dart:typed_data';

import 'package:shelf/shelf.dart';
import 'package:strava_estudo_backend/src/activity_store.dart';
import 'package:strava_estudo_backend/src/api.dart';
import 'package:strava_estudo_backend/src/auth/tokens.dart';
import 'package:strava_estudo_backend/src/user_store.dart';
import 'package:test/test.dart';

import 'fit_fixture.dart';

void main() {
  late InMemoryActivityStore store;
  late InMemoryUserStore users;
  late Handler api;
  // Relogio controlado pelos testes (expiracao de sessao).
  late int agora;
  // Token do usuario padrao, registrado no setUp.
  late String tokenA;
  late String userIdA;

  Future<Map<String, dynamic>> jsonOf(Response r) async =>
      jsonDecode(await r.readAsString()) as Map<String, dynamic>;

  Map<String, String> bearer(String token) =>
      {'authorization': 'Bearer $token'};

  Future<Response> postJson(String path, Object body,
          {Map<String, String>? headers}) async =>
      api(Request(
        'POST',
        Uri.parse('http://x$path'),
        body: jsonEncode(body),
        headers: {'content-type': 'application/json', ...?headers},
      ));

  Future<Response> registrar(String email,
          {String password = 'senha-boa-123', String displayName = 'Fulano'}) =>
      postJson('/auth/register',
          {'email': email, 'password': password, 'displayName': displayName});

  Future<String> tokenDe(String email) async =>
      (await jsonOf(await registrar(email)))['token'] as String;

  Future<Response> get(String path, {String? token}) async => api(Request(
        'GET',
        Uri.parse('http://x$path'),
        headers: token == null ? null : bearer(token),
      ));

  setUp(() async {
    store = InMemoryActivityStore();
    users = InMemoryUserStore();
    agora = 1000;
    var n = 0;
    var u = 0;
    api = createApi(
      store,
      users,
      genId: () => 'id${++n}',
      genUserId: () => 'u${++u}',
      nowMs: () => agora,
      // Custo baixo so nos testes; producao usa 120000.
      passwordIterations: 2,
    );
    final body = await jsonOf(await registrar('a@exemplo.com'));
    tokenA = body['token'] as String;
    userIdA = (body['user'] as Map)['id'] as String;
  });

  Future<Response> upload(List<int> body,
          {String? guid, String? token}) async =>
      api(Request(
        'POST',
        Uri.parse('http://x/uploads'),
        body: body,
        headers: {
          ...bearer(token ?? tokenA),
          if (guid != null) 'x-activity-guid': guid,
        },
      ));

  test('GET /health responde ok sem token', () async {
    final r = await api(Request('GET', Uri.parse('http://x/health')));
    expect(r.statusCode, 200);
    expect((await jsonOf(r))['status'], 'ok');
  });

  group('cadastro', () {
    test('201 com token e usuario; email normalizado', () async {
      final r =
          await registrar('  Maria@Exemplo.COM ', displayName: '  Maria ');
      expect(r.statusCode, 201);
      final body = await jsonOf(r);
      final token = body['token'] as String;
      // 32 bytes em base64url sem padding = 43 caracteres.
      expect(token, hasLength(43));
      expect(token, isNot(contains('=')));
      final user = body['user'] as Map<String, dynamic>;
      expect(user['id'], 'u2');
      expect(user['email'], 'maria@exemplo.com');
      expect(user['displayName'], 'Maria');
      expect(user['createdAt'], 1000);
      expect(user.containsKey('passwordHash'), isFalse);
      expect(user.keys.toSet(), {'id', 'email', 'displayName', 'createdAt'});
    });

    test('guarda hash pbkdf2 e so o sha256 do token', () async {
      final body = await jsonOf(await registrar('b@exemplo.com'));
      final u = await users.findByEmail('b@exemplo.com');
      expect(u!.passwordHash, startsWith(r'pbkdf2_sha256$2$'));
      expect(u.passwordHash, isNot(contains('senha-boa-123')));
      final token = body['token'] as String;
      expect(await users.findSession(token), isNull);
      final s = await users.findSession(hashToken(token));
      expect(s!.userId, u.id);
      expect(s.expiresAtMs, 1000 + const Duration(days: 180).inMilliseconds);
    });

    test('400 para email invalido', () async {
      for (final email in [
        '',
        'semarroba.com',
        'a@semponto',
        'a b@x.com',
        '@x.com'
      ]) {
        final r = await registrar(email);
        expect(r.statusCode, 400, reason: email);
        expect((await jsonOf(r))['error'], isA<String>());
      }
    });

    test('400 para senha com menos de 8 caracteres', () async {
      final r = await registrar('c@exemplo.com', password: '1234567');
      expect(r.statusCode, 400);
      expect((await jsonOf(r))['error'], isA<String>());
      expect(
          (await registrar('c@exemplo.com', password: '12345678')).statusCode,
          201);
    });

    test('400 para displayName vazio ou so espacos', () async {
      expect(
          (await registrar('d@exemplo.com', displayName: '')).statusCode, 400);
      expect((await registrar('d@exemplo.com', displayName: '   ')).statusCode,
          400);
      final semCampo = await postJson('/auth/register',
          {'email': 'd@exemplo.com', 'password': 'senha-boa-123'});
      expect(semCampo.statusCode, 400);
    });

    test('400 para corpo que nao e JSON', () async {
      final r = await api(Request('POST', Uri.parse('http://x/auth/register'),
          body: 'nao e json'));
      expect(r.statusCode, 400);
    });

    test('409 para email repetido, mesmo com caixa diferente', () async {
      final r = await registrar(' A@EXEMPLO.com');
      expect(r.statusCode, 409);
      expect((await jsonOf(r))['error'], isA<String>());
    });
  });

  group('login', () {
    test('200 com token novo e usuario', () async {
      final r = await postJson('/auth/login',
          {'email': 'A@Exemplo.com ', 'password': 'senha-boa-123'});
      expect(r.statusCode, 200);
      final body = await jsonOf(r);
      expect(body['token'], isNot(tokenA));
      expect((body['user'] as Map)['id'], userIdA);
      // O token novo funciona.
      expect(
          (await get('/me', token: body['token'] as String)).statusCode, 200);
    });

    test('401 com a mesma mensagem para senha errada e email inexistente',
        () async {
      final errada = await postJson('/auth/login',
          {'email': 'a@exemplo.com', 'password': 'senha-errada'});
      final inexistente = await postJson('/auth/login',
          {'email': 'ninguem@exemplo.com', 'password': 'senha-boa-123'});
      expect(errada.statusCode, 401);
      expect(inexistente.statusCode, 401);
      expect((await jsonOf(errada))['error'],
          (await jsonOf(inexistente))['error']);
    });
  });

  group('sessao', () {
    test('sem token, token desconhecido ou esquema errado = 401', () async {
      expect((await get('/me')).statusCode, 401);
      expect((await get('/me', token: 'inventado')).statusCode, 401);
      final basic = await api(Request('GET', Uri.parse('http://x/me'),
          headers: {'authorization': 'Basic $tokenA'}));
      expect(basic.statusCode, 401);
      expect((await jsonOf(basic))['error'], isA<String>());
    });

    test('logout responde 204 e revoga so aquele token', () async {
      final outro = (await jsonOf(await postJson('/auth/login', {
        'email': 'a@exemplo.com',
        'password': 'senha-boa-123'
      })))['token'] as String;
      final r = await api(Request('POST', Uri.parse('http://x/auth/logout'),
          headers: bearer(tokenA)));
      expect(r.statusCode, 204);
      expect(await r.readAsString(), isEmpty);
      expect((await get('/me', token: tokenA)).statusCode, 401);
      expect((await get('/me', token: outro)).statusCode, 200);
      // Logout de novo com o token revogado: 401.
      final again = await api(Request('POST', Uri.parse('http://x/auth/logout'),
          headers: bearer(tokenA)));
      expect(again.statusCode, 401);
    });

    test('logout sem token = 401', () async {
      final r = await api(Request('POST', Uri.parse('http://x/auth/logout')));
      expect(r.statusCode, 401);
    });

    test('token expira em 180 dias', () async {
      const int dias180 = 180 * 24 * 60 * 60 * 1000;
      agora = 1000 + dias180 - 1;
      expect((await get('/me', token: tokenA)).statusCode, 200);
      agora = 1000 + dias180;
      expect((await get('/me', token: tokenA)).statusCode, 401);
      expect((await upload([1], token: tokenA)).statusCode, 401);
    });
  });

  group('/me', () {
    test('GET traz usuario e stats zerados sem uploads', () async {
      final r = await get('/me', token: tokenA);
      expect(r.statusCode, 200);
      final body = await jsonOf(r);
      expect((body['user'] as Map)['email'], 'a@exemplo.com');
      final stats = body['stats'] as Map<String, dynamic>;
      expect(stats['activityCount'], 0);
      expect(stats['totalDistanceMeters'], 0);
      expect(stats['totalDistanceMeters'], isA<double>());
    });

    test('stats somam so os uploads do proprio usuario', () async {
      const int t0 = 1760000000000;
      await upload(
          gerarFit(startTimeUnixMs: t0, pontos: rotaSintetica(12, t0)));
      await upload([1, 2, 3]); // sem rota: conta, mas soma 0
      final tokenB = await tokenDe('b@exemplo.com');
      await upload(gerarFit(startTimeUnixMs: t0, pontos: rotaSintetica(5, t0)),
          token: tokenB);

      final esperado = (await store.listUploads(userIdA))
          .fold<double>(0, (s, r) => s + (r.lengthMeters ?? 0));
      expect(esperado, greaterThan(100));

      final stats = (await jsonOf(await get('/me', token: tokenA)))['stats']
          as Map<String, dynamic>;
      expect(stats['activityCount'], 2);
      expect(stats['totalDistanceMeters'] as num, closeTo(esperado, 1e-9));
    });

    test('PATCH troca o displayName', () async {
      final r = await api(Request('PATCH', Uri.parse('http://x/me'),
          body: jsonEncode({'displayName': '  Novo Nome '}),
          headers: bearer(tokenA)));
      expect(r.statusCode, 200);
      expect(((await jsonOf(r))['user'] as Map)['displayName'], 'Novo Nome');
      final me = await jsonOf(await get('/me', token: tokenA));
      expect((me['user'] as Map)['displayName'], 'Novo Nome');
    });

    test('PATCH com displayName vazio = 400; sem token = 401', () async {
      final vazio = await api(Request('PATCH', Uri.parse('http://x/me'),
          body: jsonEncode({'displayName': ' '}), headers: bearer(tokenA)));
      expect(vazio.statusCode, 400);
      final semToken = await api(Request('PATCH', Uri.parse('http://x/me'),
          body: jsonEncode({'displayName': 'X'})));
      expect(semToken.statusCode, 401);
    });
  });

  group('rotas protegidas exigem Bearer', () {
    test('uploads, activities e route respondem 401 sem token', () async {
      await upload([1, 2]);
      final semToken = await api(
          Request('POST', Uri.parse('http://x/uploads'), body: [1, 2, 3]));
      expect(semToken.statusCode, 401);
      expect((await get('/activities')).statusCode, 401);
      expect((await get('/uploads/id1')).statusCode, 401);
      expect((await get('/uploads/id1/route')).statusCode, 401);
      expect(await store.listUploads(userIdA), hasLength(1));
    });
  });

  group('isolamento entre usuarios', () {
    test('B nao enxerga uploads de A (404, igual a inexistente)', () async {
      const int t0 = 1760000000000;
      await upload(gerarFit(startTimeUnixMs: t0, pontos: rotaSintetica(4, t0)));
      final tokenB = await tokenDe('b@exemplo.com');

      expect((await get('/uploads/id1', token: tokenA)).statusCode, 200);
      expect((await get('/uploads/id1/route', token: tokenA)).statusCode, 200);

      final r = await get('/uploads/id1', token: tokenB);
      expect(r.statusCode, 404);
      expect((await jsonOf(r))['error'], isNotNull);
      expect((await get('/uploads/id1/route', token: tokenB)).statusCode, 404);
      final lista =
          (await jsonOf(await get('/activities', token: tokenB)))['activities']
              as List;
      expect(lista, isEmpty);
    });

    test('mesmo guid de usuarios diferentes gera uploads diferentes', () async {
      final tokenB = await tokenDe('b@exemplo.com');
      final a = await upload([1, 2, 3], guid: 'act-x');
      final b = await upload([4, 5], guid: 'act-x', token: tokenB);
      expect(a.statusCode, 201);
      expect(b.statusCode, 201);
      expect((await jsonOf(a))['uploadId'], 'id1');
      expect((await jsonOf(b))['uploadId'], 'id2');
      // Reenvio de cada um devolve o seu.
      final a2 = await upload([9], guid: 'act-x');
      final b2 = await upload([9], guid: 'act-x', token: tokenB);
      expect(a2.statusCode, 200);
      expect(b2.statusCode, 200);
      expect((await jsonOf(a2))['uploadId'], 'id1');
      expect((await jsonOf(b2))['uploadId'], 'id2');
    });
  });

  test('POST /uploads guarda e devolve uploadId', () async {
    final r = await upload([1, 2, 3, 4, 5], guid: 'act-1');
    expect(r.statusCode, 201);
    final body = await jsonOf(r);
    expect(body['uploadId'], 'id1');
    expect(body['sizeBytes'], 5);
    expect(body['activityGuid'], 'act-1');
    expect(body.containsKey('userId'), isFalse);
  });

  group('idempotencia por atividade', () {
    test('reenvio da mesma atividade devolve o upload existente com 200',
        () async {
      final first = await upload([1, 2, 3], guid: 'act-9');
      expect(first.statusCode, 201);
      final again = await upload([1, 2, 3, 4], guid: 'act-9');
      expect(again.statusCode, 200);
      final body = await jsonOf(again);
      expect(body['uploadId'], 'id1');
      expect(body['sizeBytes'], 3, reason: 'o segundo arquivo nao e gravado');
      expect(await store.listUploads(userIdA), hasLength(1));
    });

    test('atividades diferentes geram uploads diferentes', () async {
      expect((await upload([1], guid: 'a')).statusCode, 201);
      expect((await upload([1], guid: 'b')).statusCode, 201);
      expect(await store.listUploads(userIdA), hasLength(2));
    });

    test('sem guid (ou guid vazio) nao deduplica', () async {
      expect((await upload([1])).statusCode, 201);
      expect((await upload([1])).statusCode, 201);
      expect((await upload([1], guid: ' ')).statusCode, 201);
      expect((await upload([1], guid: ' ')).statusCode, 201);
      final all = await store.listUploads(userIdA);
      expect(all, hasLength(4));
      expect(all.where((r) => r.activityGuid != null), isEmpty);
    });
  });

  test('POST /uploads vazio responde 400', () async {
    final r = await upload(<int>[]);
    expect(r.statusCode, 400);
  });

  test('GET /uploads/<id> devolve o registro ou 404', () async {
    await upload([9, 9]);
    final ok = await get('/uploads/id1', token: tokenA);
    expect(ok.statusCode, 200);
    expect((await jsonOf(ok))['status'], 'received');

    final nf = await get('/uploads/zzz', token: tokenA);
    expect(nf.statusCode, 404);
  });

  test('GET /activities lista o que foi recebido', () async {
    await upload([1]);
    await upload([2]);
    final body = await jsonOf(await get('/activities', token: tokenA));
    expect((body['activities'] as List).length, 2);
  });

  group('rota e metricas', () {
    const int t0 = 1760000000000;

    Future<Response> enviar(Uint8List fit) => upload(fit);

    test('GET /uploads/<id>/route devolve Feature GeoJSON com N pontos',
        () async {
      final Uint8List fit =
          gerarFit(startTimeUnixMs: t0, pontos: rotaSintetica(12, t0));
      await enviar(fit);

      final r = await get('/uploads/id1/route', token: tokenA);
      expect(r.statusCode, 200);
      final body = await jsonOf(r);
      expect(body['type'], 'Feature');

      final geometry = body['geometry'] as Map<String, dynamic>;
      expect(geometry['type'], 'LineString');
      final coords = geometry['coordinates'] as List;
      expect(coords.length, 12);

      // Ordem GeoJSON: [longitude, latitude].
      final primeiro = (coords.first as List).cast<num>();
      expect(primeiro[0], closeTo(-46.656, 1e-4)); // longitude
      expect(primeiro[1], closeTo(-23.561, 1e-4)); // latitude
      final ultimo = (coords.last as List).cast<num>();
      expect(ultimo[0], closeTo(-46.656 - 11 * 0.00015, 1e-4));
      expect(ultimo[1], closeTo(-23.561 + 11 * 0.0001, 1e-4));

      final props = body['properties'] as Map<String, dynamic>;
      expect(props['pointCount'], 12);
      // 11 segmentos de ~19 m: algo entre 100 e 500 metros.
      expect(props['lengthMeters'] as num, greaterThan(100));
      expect(props['lengthMeters'] as num, lessThan(500));
    });

    test('upload sem rota utilizavel responde 204', () async {
      // Corpo que nao e um FIT valido: upload vale, rota nao existe.
      await upload([1, 2, 3]);
      final r = await get('/uploads/id1/route', token: tokenA);
      expect(r.statusCode, 204);
      expect(await r.readAsString(), isEmpty);
    });

    test('FIT com um unico ponto tambem responde 204', () async {
      await enviar(gerarFit(startTimeUnixMs: t0, pontos: rotaSintetica(1, t0)));
      final r = await get('/uploads/id1/route', token: tokenA);
      expect(r.statusCode, 204);
    });

    test('id inexistente responde 404', () async {
      final r = await get('/uploads/zzz/route', token: tokenA);
      expect(r.statusCode, 404);
      expect((await jsonOf(r))['error'], isNotNull);
    });

    test('GET /uploads/<id> traz pointCount e lengthMeters', () async {
      await enviar(gerarFit(startTimeUnixMs: t0, pontos: rotaSintetica(5, t0)));
      final body = await jsonOf(await get('/uploads/id1', token: tokenA));
      // Campos antigos continuam no lugar.
      expect(body['id'], 'id1');
      expect(body['uploadId'], 'id1');
      expect(body['status'], 'received');
      expect(body['receivedAt'], 1000);
      expect(body['sizeBytes'], greaterThan(0));
      // Campos novos.
      expect(body['pointCount'], 5);
      expect(body['lengthMeters'] as num, greaterThan(0));
    });

    test('GET /activities traz os campos novos (null quando nao ha rota)',
        () async {
      await enviar(gerarFit(startTimeUnixMs: t0, pontos: rotaSintetica(4, t0)));
      await upload([7, 7]);

      final r = await get('/activities', token: tokenA);
      final lista = (await jsonOf(r))['activities'] as List;
      expect(lista.length, 2);

      final porId = <String, Map<String, dynamic>>{
        for (final item in lista.cast<Map<String, dynamic>>())
          item['id'] as String: item,
      };

      expect(porId['id1']!['pointCount'], 4);
      expect(porId['id1']!['lengthMeters'] as num, greaterThan(0));

      expect(porId['id2']!.containsKey('pointCount'), isTrue);
      expect(porId['id2']!['pointCount'], isNull);
      expect(porId['id2']!['lengthMeters'], isNull);
    });
  });
}
