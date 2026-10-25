// Implementacao do ActivityStore sobre PostgreSQL/PostGIS.
library;

import 'package:postgres/postgres.dart';

import 'activity_store.dart';
import 'fit_decoder.dart';

class PostgresActivityStore implements ActivityStore {
  final Connection _conn;
  PostgresActivityStore(this._conn);

  static Future<PostgresActivityStore> connect({
    required String host,
    required int port,
    required String database,
    required String username,
    required String password,
  }) async {
    final conn = await Connection.open(
      Endpoint(
        host: host,
        port: port,
        database: database,
        username: username,
        password: password,
      ),
      settings: const ConnectionSettings(sslMode: SslMode.disable),
    );
    return PostgresActivityStore(conn);
  }

  Future<void> close() => _conn.close();

  @override
  Future<UploadRecord> saveUpload(List<int> fitBytes,
      {String? activityGuid, required int nowMs, required String id}) async {
    // Tenta extrair a rota do FIT. Falha na decodificacao nao pode derrubar o
    // upload: o arquivo bruto ja fica guardado em `fit` e pode ser reprocessado
    // depois. Nesse caso route e point_count ficam NULL.
    final RotaDecodificada rota = decodificarRota(fitBytes);

    final Map<String, Object?> parameters = <String, Object?>{
      'id': id,
      'status': 'received',
      'received_at': nowMs,
      'size': fitBytes.length,
      'guid': activityGuid,
      'fit': fitBytes,
    };

    final String routeExpr;
    if (rota.wkt != null) {
      routeExpr = 'ST_SetSRID(ST_GeomFromText(@wkt), 4326)';
      parameters['wkt'] = rota.wkt;
      parameters['points'] = rota.pointCount;
    } else {
      routeExpr = 'NULL';
      parameters['points'] = rota.pointCount > 0 ? rota.pointCount : null;
    }

    await _conn.execute(
      Sql.named(
        'INSERT INTO uploads '
        '(id, status, received_at, size_bytes, activity_guid, fit, route, point_count) '
        'VALUES (@id, @status, @received_at, @size, @guid, @fit, $routeExpr, @points)',
      ),
      parameters: parameters,
    );
    return UploadRecord(
      id: id,
      status: 'received',
      receivedAtMs: nowMs,
      sizeBytes: fitBytes.length,
      activityGuid: activityGuid,
    );
  }

  @override
  Future<UploadRecord?> getUpload(String id) async {
    final result = await _conn.execute(
      Sql.named(
        'SELECT id, status, received_at, size_bytes, activity_guid FROM uploads WHERE id = @id',
      ),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    return _fromRow(result.first.toColumnMap());
  }

  @override
  Future<List<UploadRecord>> listUploads() async {
    final result = await _conn.execute(
      'SELECT id, status, received_at, size_bytes, activity_guid FROM uploads '
      'ORDER BY received_at DESC LIMIT 100',
    );
    return [for (final row in result) _fromRow(row.toColumnMap())];
  }

  UploadRecord _fromRow(Map<String, dynamic> m) => UploadRecord(
        id: m['id'] as String,
        status: m['status'] as String,
        receivedAtMs: (m['received_at'] as int),
        sizeBytes: (m['size_bytes'] as int),
        activityGuid: m['activity_guid'] as String?,
      );
}
