// Testes dos handlers da API com store em memoria (sem Postgres).
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:strava_estudo_backend/src/activity_store.dart';
import 'package:strava_estudo_backend/src/api.dart';
import 'package:test/test.dart';

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

  test('POST /uploads vazio responde 400', () async {
    final r = await api(Request('POST', Uri.parse('http://x/uploads'), body: <int>[]));
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
}
