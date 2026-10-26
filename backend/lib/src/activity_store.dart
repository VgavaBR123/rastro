// Abstracao de armazenamento das atividades recebidas. Permite testar os
// handlers com um store em memoria, sem precisar do Postgres.
library;

import 'fit_decoder.dart';

class UploadRecord {
  final String id;

  /// Dono do upload. Nao sai no JSON; a API so devolve uploads do proprio
  /// usuario. Null apenas em uploads antigos (anteriores as contas).
  final String? userId;
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
    this.userId,
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

/// Agregados de um usuario para GET /me.
class UserStats {
  final int activityCount;
  final double totalDistanceMeters;
  const UserStats(this.activityCount, this.totalDistanceMeters);

  Map<String, dynamic> toJson() => {
        'activityCount': activityCount,
        'totalDistanceMeters': totalDistanceMeters,
      };
}

/// Todas as leituras sao escopadas por usuario: upload de outro usuario se
/// comporta exatamente como upload inexistente.
abstract class ActivityStore {
  /// Guarda o arquivo FIT recebido e devolve o registro. Se ja existe upload
  /// do mesmo [userId] para o mesmo [activityGuid], nao grava nada e devolve
  /// o existente (com o id dele, diferente de [id]).
  Future<UploadRecord> saveUpload(List<int> fitBytes,
      {required String userId,
      String? activityGuid,
      required int nowMs,
      required String id});
  Future<UploadRecord?> getUpload(String id, {required String userId});

  /// Upload ja recebido de [userId] para a atividade [activityGuid], se
  /// houver. Base da idempotencia: o app pode reenviar a mesma atividade
  /// (retry, sync manual e de fundo ao mesmo tempo) e o servidor guarda uma
  /// so. O mesmo guid vindo de outro usuario e outra atividade.
  Future<UploadRecord?> findByActivityGuid(String userId, String activityGuid);

  Future<List<UploadRecord>> listUploads(String userId);

  /// Rota do upload [id]. Devolve null quando o upload nao existe (ou e de
  /// outro usuario) OU quando existe mas nao tem rota utilizavel (menos de 2
  /// pontos / FIT ilegivel). Quem chama distingue os casos com [getUpload].
  Future<RouteData?> getRoute(String id, {required String userId});

  /// Quantidade de uploads e soma do comprimento das rotas de [userId].
  Future<UserStats> statsFor(String userId);
}

/// Implementacao em memoria (testes e dev sem banco).
class InMemoryActivityStore implements ActivityStore {
  final Map<String, UploadRecord> _records = {};
  final Map<String, List<int>> _blobs = {};

  @override
  Future<UploadRecord> saveUpload(List<int> fitBytes,
      {required String userId,
      String? activityGuid,
      required int nowMs,
      required String id}) async {
    if (activityGuid != null) {
      final existing = await findByActivityGuid(userId, activityGuid);
      if (existing != null) return existing;
    }
    // Decodifica na entrada apenas para guardar os agregados; os bytes brutos
    // ficam em _blobs e a rota e remontada sob demanda em getRoute.
    final List<FitTrackPoint>? pontos = _decodificar(fitBytes);
    final rec = UploadRecord(
      id: id,
      userId: userId,
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
  Future<UploadRecord?> getUpload(String id, {required String userId}) async {
    final rec = _records[id];
    return (rec != null && rec.userId == userId) ? rec : null;
  }

  @override
  Future<UploadRecord?> findByActivityGuid(
      String userId, String activityGuid) async {
    for (final rec in _records.values) {
      if (rec.userId == userId && rec.activityGuid == activityGuid) return rec;
    }
    return null;
  }

  @override
  Future<List<UploadRecord>> listUploads(String userId) async {
    final list = _records.values.where((r) => r.userId == userId).toList()
      ..sort((a, b) => b.receivedAtMs.compareTo(a.receivedAtMs));
    return list;
  }

  @override
  Future<UserStats> statsFor(String userId) async {
    final list = await listUploads(userId);
    final double total =
        list.fold(0.0, (soma, r) => soma + (r.lengthMeters ?? 0));
    return UserStats(list.length, total);
  }

  @override
  Future<RouteData?> getRoute(String id, {required String userId}) async {
    if (await getUpload(id, userId: userId) == null) return null;
    final List<int>? bytes = _blobs[id];
    if (bytes == null) return null;
    final List<FitTrackPoint>? pontos = _decodificar(bytes);
    if (pontos == null || pontos.length < 2) return null;
    return RouteData(
      geometry: <String, Object?>{
        'type': 'LineString',
        'coordinates': <List<double>>[
          // GeoJSON usa a ordem [longitude, latitude].
          for (final FitTrackPoint p in pontos)
            <double>[p.longitude, p.latitude],
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
