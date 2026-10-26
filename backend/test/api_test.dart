// Testes dos handlers da API com store em memoria (sem Postgres).
import 'dart:convert';
import 'dart:typed_data';

import 'package:shelf/shelf.dart';
import 'package:strava_estudo_backend/src/activity_store.dart';
import 'package:strava_estudo_backend/src/api.dart';
import 'package:test/test.dart';

import 'fit_fixture.dart';

void main() {
  late InMemoryActivityStore store;
  late Handler api;

  setUp(() {
    store = InMemoryActivityStore();
    var n = 0;
    api = createApi(store, genId: () => 'id${++n}', nowMs: () => 1000);
  });

  Future<Map<String, dynamic>> jsonOf(Response r) async =>
      jsonDecode(await r.readAsString()) as Map<String, dynamic>;

  test('GET /health responde ok', () async {
    final r = await api(Request('GET', Uri.parse('http://x/health')));
    expect(r.statusCode, 200);
    expect((await jsonOf(r))['status'], 'ok');
  });

  test('POST /uploads guarda e devolve uploadId', () async {
    final r = await api(Request(
      'POST',
      Uri.parse('http://x/uploads'),
      body: [1, 2, 3, 4, 5],
      headers: {'x-activity-guid': 'act-1'},
    ));
    expect(r.statusCode, 201);
    final body = await jsonOf(r);
    expect(body['uploadId'], 'id1');
    expect(body['sizeBytes'], 5);
    expect(body['activityGuid'], 'act-1');
  });

  group('idempotencia por atividade', () {
    Future<Response> post(List<int> body, {String? guid}) async => api(Request(
          'POST',
          Uri.parse('http://x/uploads'),
          body: body,
          headers: {if (guid != null) 'x-activity-guid': guid},
        ));

    test('reenvio da mesma atividade devolve o upload existente com 200',
        () async {
      final first = await post([1, 2, 3], guid: 'act-9');
      expect(first.statusCode, 201);
      final again = await post([1, 2, 3, 4], guid: 'act-9');
      expect(again.statusCode, 200);
      final body = await jsonOf(again);
      expect(body['uploadId'], 'id1');
      expect(body['sizeBytes'], 3, reason: 'o segundo arquivo nao e gravado');
      expect(await store.listUploads(), hasLength(1));
    });

    test('atividades diferentes geram uploads diferentes', () async {
      expect((await post([1], guid: 'a')).statusCode, 201);
      expect((await post([1], guid: 'b')).statusCode, 201);
      expect(await store.listUploads(), hasLength(2));
    });

    test('sem guid (ou guid vazio) nao deduplica', () async {
      expect((await post([1])).statusCode, 201);
      expect((await post([1])).statusCode, 201);
      expect((await post([1], guid: ' ')).statusCode, 201);
      expect((await post([1], guid: ' ')).statusCode, 201);
      final all = await store.listUploads();
      expect(all, hasLength(4));
      expect(all.where((r) => r.activityGuid != null), isEmpty);
    });
  });

  test('POST /uploads vazio responde 400', () async {
    final r = await api(
        Request('POST', Uri.parse('http://x/uploads'), body: <int>[]));
    expect(r.statusCode, 400);
  });

  test('GET /uploads/<id> devolve o registro ou 404', () async {
    await api(Request('POST', Uri.parse('http://x/uploads'), body: [9, 9]));
    final ok = await api(Request('GET', Uri.parse('http://x/uploads/id1')));
    expect(ok.statusCode, 200);
    expect((await jsonOf(ok))['status'], 'received');

    final nf = await api(Request('GET', Uri.parse('http://x/uploads/zzz')));
    expect(nf.statusCode, 404);
  });

  test('GET /activities lista o que foi recebido', () async {
    await api(Request('POST', Uri.parse('http://x/uploads'), body: [1]));
    await api(Request('POST', Uri.parse('http://x/uploads'), body: [2]));
    final r = await api(Request('GET', Uri.parse('http://x/activities')));
    final body = await jsonOf(r);
    expect((body['activities'] as List).length, 2);
  });

  group('rota e metricas', () {
    const int t0 = 1760000000000;

    Future<Response> enviar(Uint8List fit) async => api(Request(
          'POST',
          Uri.parse('http://x/uploads'),
          body: fit,
        ));

    test('GET /uploads/<id>/route devolve Feature GeoJSON com N pontos',
        () async {
      final Uint8List fit =
          gerarFit(startTimeUnixMs: t0, pontos: rotaSintetica(12, t0));
      await enviar(fit);

      final r =
          await api(Request('GET', Uri.parse('http://x/uploads/id1/route')));
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
      await api(
          Request('POST', Uri.parse('http://x/uploads'), body: [1, 2, 3]));
      final r =
          await api(Request('GET', Uri.parse('http://x/uploads/id1/route')));
      expect(r.statusCode, 204);
      expect(await r.readAsString(), isEmpty);
    });

    test('FIT com um unico ponto tambem responde 204', () async {
      await enviar(gerarFit(startTimeUnixMs: t0, pontos: rotaSintetica(1, t0)));
      final r =
          await api(Request('GET', Uri.parse('http://x/uploads/id1/route')));
      expect(r.statusCode, 204);
    });

    test('id inexistente responde 404', () async {
      final r =
          await api(Request('GET', Uri.parse('http://x/uploads/zzz/route')));
      expect(r.statusCode, 404);
      expect((await jsonOf(r))['error'], isNotNull);
    });

    test('GET /uploads/<id> traz pointCount e lengthMeters', () async {
      await enviar(gerarFit(startTimeUnixMs: t0, pontos: rotaSintetica(5, t0)));
      final r = await api(Request('GET', Uri.parse('http://x/uploads/id1')));
      final body = await jsonOf(r);
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
      await api(Request('POST', Uri.parse('http://x/uploads'), body: [7, 7]));

      final r = await api(Request('GET', Uri.parse('http://x/activities')));
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
