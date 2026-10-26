// Abstracao de armazenamento das atividades recebidas. Permite testar os
// handlers com um store em memoria, sem precisar do Postgres.
library;

import 'fit_decoder.dart';

class UploadRecord {
  final String id;
  final String status; // received | processed | error
  final int receivedAtMs;
  final int sizeBytes;
  final String? activityGuid;

  /// Pontos com posicao valida lidos do FIT. Null quando a decodificacao
  /// falhou (o arquivo bruto continua guardado e pode ser reprocessado).
  final int? pointCount;

  /// Comprimento da rota em metros. Null quando nao ha rota.
  final double? lengthMeters;

  const UploadRecord({
    required this.id,
    required this.status,
    required this.receivedAtMs,
    required this.sizeBytes,
    this.activityGuid,
    this.pointCount,
    this.lengthMeters,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'uploadId': id,
        'status': status,
        'receivedAt': receivedAtMs,
        'sizeBytes': sizeBytes,
        if (activityGuid != null) 'activityGuid': activityGuid,
        // Sempre presentes (podem vir null) para o cliente nao precisar
        // distinguir "campo ausente" de "sem rota".
        'pointCount': pointCount,
        'lengthMeters': lengthMeters,
      };
}

/// Rota de um upload pronta para virar GeoJSON.
class RouteData {
  /// Geometria GeoJSON: `{"type":"LineString","coordinates":[[lon,lat],...]}`.
  final Map<String, Object?> geometry;

  /// Quantidade de pontos da linha.
  final int pointCount;

  /// Comprimento da linha em metros.
  final double lengthMeters;

  const RouteData({
    required this.geometry,
    required this.pointCount,
    required this.lengthMeters,
  });

  /// Feature GeoJSON completa, no formato que a API devolve.
  Map<String, Object?> toFeatureJson() => {
        'type': 'Feature',
        'geometry': geometry,
        'properties': {
          'pointCount': pointCount,
          'lengthMeters': lengthMeters,
        },
      };
}

abstract class ActivityStore {
  /// Guarda o arquivo FIT recebido e devolve o registro. Se ja existe upload
  /// para o mesmo [activityGuid], nao grava nada e devolve o existente (com o
  /// id dele, diferente de [id]).
  Future<UploadRecord> saveUpload(List<int> fitBytes, {String? activityGuid, required int nowMs, required String id});
  Future<UploadRecord?> getUpload(String id);

  /// Upload ja recebido para a atividade [activityGuid], se houver. Base da
  /// idempotencia: o app pode reenviar a mesma atividade (retry, sync manual
  /// e de fundo ao mesmo tempo) e o servidor guarda uma so.
  Future<UploadRecord?> findByActivityGuid(String activityGuid);

  Future<List<UploadRecord>> listUploads();

  /// Rota do upload [id]. Devolve null quando o upload nao existe OU quando
  /// existe mas nao tem rota utilizavel (menos de 2 pontos / FIT ilegivel).
  /// Quem chama distingue os dois casos com [getUpload].
  Future<RouteData?> getRoute(String id);
}

/// Implementacao em memoria (testes e dev sem banco).
class InMemoryActivityStore implements ActivityStore {
  final Map<String, UploadRecord> _records = {};
  final Map<String, List<int>> _blobs = {};

  @override
  Future<UploadRecord> saveUpload(List<int> fitBytes,
      {String? activityGuid, required int nowMs, required String id}) async {
    if (activityGuid != null) {
      final existing = await findByActivityGuid(activityGuid);
      if (existing != null) return existing;
    }
    // Decodifica na entrada apenas para guardar os agregados; os bytes brutos
    // ficam em _blobs e a rota e remontada sob demanda em getRoute.
    final List<FitTrackPoint>? pontos = _decodificar(fitBytes);
    final rec = UploadRecord(
      id: id,
      status: 'received',
      receivedAtMs: nowMs,
      sizeBytes: fitBytes.length,
      activityGuid: activityGuid,
      pointCount: pontos?.length,
      lengthMeters: (pontos != null && pontos.length >= 2)
          ? comprimentoMetros(pontos)
          : null,
    );
    _records[id] = rec;
    _blobs[id] = fitBytes;
    return rec;
  }

  @override
  Future<UploadRecord?> getUpload(String id) async => _records[id];

  @override
  Future<UploadRecord?> findByActivityGuid(String activityGuid) async {
    for (final rec in _records.values) {
      if (rec.activityGuid == activityGuid) return rec;
    }
    return null;
  }

  @override
  Future<List<UploadRecord>> listUploads() async {
    final list = _records.values.toList()
      ..sort((a, b) => b.receivedAtMs.compareTo(a.receivedAtMs));
    return list;
  }

  @override
  Future<RouteData?> getRoute(String id) async {
    final List<int>? bytes = _blobs[id];
    if (bytes == null) return null;
    final List<FitTrackPoint>? pontos = _decodificar(bytes);
    if (pontos == null || pontos.length < 2) return null;
    return RouteData(
      geometry: <String, Object?>{
        'type': 'LineString',
        'coordinates': <List<double>>[
          // GeoJSON usa a ordem [longitude, latitude].
          for (final FitTrackPoint p in pontos) <double>[p.longitude, p.latitude],
        ],
      },
      pointCount: pontos.length,
      lengthMeters: comprimentoMetros(pontos),
    );
  }

  /// Decodifica sem lancar: null quando o arquivo nao e um FIT legivel.
  List<FitTrackPoint>? _decodificar(List<int> bytes) {
    try {
      return decodeFitRecords(bytes);
    } catch (_) {
      return null;
    }
  }
}
