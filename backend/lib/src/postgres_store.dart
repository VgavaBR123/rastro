// Implementacao do ActivityStore sobre PostgreSQL/PostGIS.
library;

import 'dart:convert';

import 'package:postgres/postgres.dart';

import 'activity_store.dart';
import 'fit_decoder.dart';

const String _uniqueGuidIndexSql =
    'CREATE UNIQUE INDEX IF NOT EXISTS uq_uploads_activity_guid '
    'ON uploads (activity_guid) WHERE activity_guid IS NOT NULL';

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
    final store = PostgresActivityStore(conn);
    await store._ensureSchema();
    return store;
  }

  /// Ajustes de esquema que o init.sql so aplica em volume novo. Idempotente.
  Future<void> _ensureSchema() async {
    // Uma atividade = um upload. Parcial porque uploads sem guid sao aceitos.
    // Se o banco ja tiver guids repetidos de antes da regra, a criacao falha
    // aqui com mensagem clara em vez de o upload falhar depois.
    await _conn.execute(_uniqueGuidIndexSql);
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

    // RETURNING com ST_Length para o comprimento vir do proprio PostGIS,
    // sem segunda ida ao banco e sem recalcular em Dart.
    final inserted = await _conn.execute(
      Sql.named(
        'INSERT INTO uploads '
        '(id, status, received_at, size_bytes, activity_guid, fit, route, point_count) '
        'VALUES (@id, @status, @received_at, @size, @guid, @fit, $routeExpr, @points) '
        // Dois envios simultaneos da mesma atividade: o segundo nao insere e
        // devolvemos o registro do primeiro logo abaixo.
        'ON CONFLICT (activity_guid) WHERE activity_guid IS NOT NULL DO NOTHING '
        'RETURNING point_count, ST_Length(route::geography) AS length_meters',
      ),
      parameters: parameters,
    );
    if (inserted.isEmpty && activityGuid != null) {
      final existing = await findByActivityGuid(activityGuid);
      if (existing != null) return existing;
    }
    final Map<String, dynamic> retorno =
        inserted.isEmpty ? const <String, dynamic>{} : inserted.first.toColumnMap();

    return UploadRecord(
      id: id,
      status: 'received',
      receivedAtMs: nowMs,
      sizeBytes: fitBytes.length,
      activityGuid: activityGuid,
      pointCount: retorno['point_count'] as int?,
      lengthMeters: _comoDouble(retorno['length_meters']),
    );
  }

  @override
  Future<UploadRecord?> getUpload(String id) async {
    final result = await _conn.execute(
      Sql.named('${_selectUploads}WHERE id = @id'),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    return _fromRow(result.first.toColumnMap());
  }

  @override
  Future<UploadRecord?> findByActivityGuid(String activityGuid) async {
    final result = await _conn.execute(
      Sql.named('${_selectUploads}WHERE activity_guid = @guid'),
      parameters: {'guid': activityGuid},
    );
    if (result.isEmpty) return null;
    return _fromRow(result.first.toColumnMap());
  }

  @override
  Future<List<UploadRecord>> listUploads() async {
    final result = await _conn.execute(
      '${_selectUploads}ORDER BY received_at DESC LIMIT 100',
    );
    return [for (final row in result) _fromRow(row.toColumnMap())];
  }

  @override
  Future<RouteData?> getRoute(String id) async {
    final result = await _conn.execute(
      Sql.named(
        'SELECT ST_AsGeoJSON(route) AS geojson, point_count, '
        'ST_Length(route::geography) AS length_meters '
        'FROM uploads WHERE id = @id',
      ),
      parameters: {'id': id},
    );
    // Linha ausente (upload inexistente) e route NULL (sem rota) chegam aqui
    // como o mesmo null; quem chama separa os casos com getUpload.
    if (result.isEmpty) return null;
    final Map<String, dynamic> m = result.first.toColumnMap();
    final Object? geojson = m['geojson'];
    if (geojson == null) return null;

    final Object? decodificado = jsonDecode(geojson as String);
    if (decodificado is! Map) return null;
    final Map<String, Object?> geometria = <String, Object?>{
      for (final entry in decodificado.entries)
        entry.key.toString(): entry.value,
    };

    final Object? coords = geometria['coordinates'];
    final int pontos =
        (m['point_count'] as int?) ?? (coords is List ? coords.length : 0);

    return RouteData(
      geometry: geometria,
      pointCount: pontos,
      lengthMeters: _comoDouble(m['length_meters']) ?? 0,
    );
  }

  static const String _selectUploads =
      'SELECT id, status, received_at, size_bytes, activity_guid, point_count, '
      'ST_Length(route::geography) AS length_meters FROM uploads ';

  UploadRecord _fromRow(Map<String, dynamic> m) => UploadRecord(
        id: m['id'] as String,
        status: m['status'] as String,
        receivedAtMs: (m['received_at'] as int),
        sizeBytes: (m['size_bytes'] as int),
        activityGuid: m['activity_guid'] as String?,
        pointCount: m['point_count'] as int?,
        lengthMeters: _comoDouble(m['length_meters']),
      );

  /// ST_Length pode voltar como double ou numeric dependendo do driver.
  static double? _comoDouble(Object? valor) {
    if (valor == null) return null;
    if (valor is double) return valor;
    if (valor is num) return valor.toDouble();
    return double.tryParse(valor.toString());
  }
}
