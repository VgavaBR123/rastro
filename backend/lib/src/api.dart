// Monta o roteador HTTP da API. Handlers recebem um ActivityStore, entao dao
// para testar sem banco. Contrato com o app: POST /uploads recebe o arquivo FIT
// como corpo (application/octet-stream) e devolve { "uploadId": ... }.
library;

import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'activity_store.dart';

Response _json(Object data, {int status = 200}) => Response(
      status,
      body: jsonEncode(data),
      headers: {'content-type': 'application/json'},
    );

Future<List<int>> _readBytes(Request req) async {
  final out = <int>[];
  await for (final chunk in req.read()) {
    out.addAll(chunk);
  }
  return out;
}

Handler createApi(
  ActivityStore store, {
  String Function()? genId,
  int Function()? nowMs,
}) {
  final newId = genId ?? _defaultId;
  final now = nowMs ?? () => DateTime.now().millisecondsSinceEpoch;
  final router = Router();

  router.get('/health', (Request req) => _json({'status': 'ok'}));

  router.post('/uploads', (Request req) async {
    final bytes = await _readBytes(req);
    if (bytes.isEmpty) {
      return _json({'error': 'arquivo vazio'}, status: 400);
    }
    final header = req.headers['x-activity-guid']?.trim();
    final guid = (header == null || header.isEmpty) ? null : header;
    // Idempotente por atividade: reenvio da mesma atividade devolve o upload
    // que ja existe com 200, em vez de criar outro com 201.
    final id = newId();
    final rec = await store.saveUpload(bytes,
        activityGuid: guid, nowMs: now(), id: id);
    return _json(rec.toJson(), status: rec.id == id ? 201 : 200);
  });

  router.get('/uploads/<id>', (Request req, String id) async {
    final rec = await store.getUpload(id);
    if (rec == null) return _json({'error': 'nao encontrado'}, status: 404);
    return _json(rec.toJson());
  });

  // Rota como Feature GeoJSON. Tres situacoes distintas:
  //  - upload inexistente            -> 404
  //  - upload existe mas sem rota     -> 204 (o recurso existe, so nao tem
  //    representacao; 404 aqui faria o cliente achar que o upload sumiu)
  //  - upload com rota                -> 200 com a Feature
  router.get('/uploads/<id>/route', (Request req, String id) async {
    final rec = await store.getUpload(id);
    if (rec == null) return _json({'error': 'nao encontrado'}, status: 404);
    final rota = await store.getRoute(id);
    if (rota == null) return Response(204);
    return _json(rota.toFeatureJson());
  });

  router.get('/activities', (Request req) async {
    final list = await store.listUploads();
    return _json({'activities': [for (final r in list) r.toJson()]});
  });

  return router.call;
}

int _seq = 0;
String _defaultId() {
  _seq++;
  final ts = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  return 'up_${ts}_$_seq';
}
