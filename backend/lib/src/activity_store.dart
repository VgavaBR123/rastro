// Abstracao de armazenamento das atividades recebidas. Permite testar os
// handlers com um store em memoria, sem precisar do Postgres.
library;

class UploadRecord {
  final String id;
  final String status; // received | processed | error
  final int receivedAtMs;
  final int sizeBytes;
  final String? activityGuid;

  const UploadRecord({
    required this.id,
    required this.status,
    required this.receivedAtMs,
    required this.sizeBytes,
    this.activityGuid,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'uploadId': id,
        'status': status,
        'receivedAt': receivedAtMs,
        'sizeBytes': sizeBytes,
        if (activityGuid != null) 'activityGuid': activityGuid,
      };
}

abstract class ActivityStore {
  /// Guarda o arquivo FIT recebido e devolve o uploadId gerado.
  Future<UploadRecord> saveUpload(List<int> fitBytes, {String? activityGuid, required int nowMs, required String id});
  Future<UploadRecord?> getUpload(String id);
  Future<List<UploadRecord>> listUploads();
}

/// Implementacao em memoria (testes e dev sem banco).
class InMemoryActivityStore implements ActivityStore {
  final Map<String, UploadRecord> _records = {};
  final Map<String, List<int>> _blobs = {};

  @override
  Future<UploadRecord> saveUpload(List<int> fitBytes,
      {String? activityGuid, required int nowMs, required String id}) async {
    final rec = UploadRecord(
      id: id,
      status: 'received',
      receivedAtMs: nowMs,
      sizeBytes: fitBytes.length,
      activityGuid: activityGuid,
    );
    _records[id] = rec;
    _blobs[id] = fitBytes;
    return rec;
  }

  @override
  Future<UploadRecord?> getUpload(String id) async => _records[id];

  @override
  Future<List<UploadRecord>> listUploads() async {
    final list = _records.values.toList()
      ..sort((a, b) => b.receivedAtMs.compareTo(a.receivedAtMs));
    return list;
  }
}
