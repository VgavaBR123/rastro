// Implementacao do ActivityStore sobre PostgreSQL/PostGIS.
library;

import 'dart:convert';

import 'package:postgres/postgres.dart';

import 'activity_store.dart';
import 'fit_decoder.dart';

/// DDL idempotente aplicado ao conectar (o init.sql so roda em volume novo).
/// Ordem importa: users antes da FK de uploads.user_id.
const List<String> _schemaSql = <String>[
  'CREATE TABLE IF NOT EXISTS users ('
      'id TEXT PRIMARY KEY, '
      'email TEXT UNIQUE NOT NULL, '
      'password_hash TEXT NOT NULL, '
      'display_name TEXT NOT NULL, '
      'created_at BIGINT NOT NULL)',
  'CREATE TABLE IF NOT EXISTS sessions ('
      'token_hash TEXT PRIMARY KEY, '
      'user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE, '
      'created_at BIGINT NOT NULL, '
      'expires_at BIGINT NOT NULL)',
  'CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON sessions (user_id)',
  // Uploads anteriores as contas ficam com user_id NULL (orfaos, invisiveis
  // pela API).
  'ALTER TABLE uploads ADD COLUMN IF NOT EXISTS user_id TEXT NULL '
      'REFERENCES users(id)',
  // Idempotencia passou a ser por (usuario, atividade): o indice antigo, so
  // por activity_guid, impediria dois usuarios de usarem o mesmo guid.
  'DROP INDEX IF EXISTS uq_uploads_activity_guid',
  'CREATE UNIQUE INDEX IF NOT EXISTS uq_uploads_user_activity_guid '
      'ON uploads (user_id, activity_guid) WHERE activity_guid IS NOT NULL',
  'CREATE INDEX IF NOT EXISTS idx_uploads_user_received '
      'ON uploads (user_id, received_at DESC)',
];

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

  /// Conexao compartilhada com o PostgresUserStore.
  Connection get connection => _conn;

  /// Ajustes de esquema que o init.sql so aplica em volume novo. Idempotente.
  /// Se o banco tiver dados que violam uma regra nova (ex.: guid repetido do
  /// mesmo usuario), a criacao falha aqui com mensagem clara em vez de o
  /// upload falhar depois.
  Future<void> _ensureSchema() async {
    await _conn.runTx((tx) async {
      for (final String sql in _schemaSql) {
        await tx.execute(sql);
      }
    });
  }

  Future<void> close() => _conn.close();

  @override
  Future<UploadRecord> saveUpload(List<int> fitBytes,
      {required String userId,
      String? activityGuid,
      required int nowMs,
      required String id}) async {
    // Tenta extrair a rota do FIT. Falha na decodificacao nao pode derrubar o
    // upload: o arquivo bruto ja fica guardado em `fit` e pode ser reprocessado
    // depois. Nesse caso route e point_count ficam NULL.
    final RotaDecodificada rota = decodificarRota(fitBytes);

    final Map<String, Object?> parameters = <String, Object?>{
      'id': id,
      'user_id': userId,
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
        '(id, user_id, status, received_at, size_bytes, activity_guid, fit, route, point_count) '
        'VALUES (@id, @user_id, @status, @received_at, @size, @guid, @fit, $routeExpr, @points) '
        // Dois envios simultaneos da mesma atividade do mesmo usuario: o
        // segundo nao insere e devolvemos o registro do primeiro logo abaixo.
        'ON CONFLICT (user_id, activity_guid) WHERE activity_guid IS NOT NULL DO NOTHING '
        'RETURNING point_count, ST_Length(route::geography) AS length_meters',
      ),
      parameters: parameters,
    );
    if (inserted.isEmpty && activityGuid != null) {
      final existing = await findByActivityGuid(userId, activityGuid);
      if (existing != null) return existing;
    }
    final Map<String, dynamic> retorno = inserted.isEmpty
        ? const <String, dynamic>{}
        : inserted.first.toColumnMap();

    return UploadRecord(
      id: id,
      userId: userId,
      status: 'received',
      receivedAtMs: nowMs,
      sizeBytes: fitBytes.length,
      activityGuid: activityGuid,
      pointCount: retorno['point_count'] as int?,
      lengthMeters: _comoDouble(retorno['length_meters']),
    );
  }

  @override
  Future<UploadRecord?> getUpload(String id, {required String userId}) async {
    final result = await _conn.execute(
      Sql.named('${_selectUploads}WHERE id = @id AND user_id = @user_id'),
      parameters: {'id': id, 'user_id': userId},
    );
    if (result.isEmpty) return null;
    return _fromRow(result.first.toColumnMap());
  }

  @override
  Future<UploadRecord?> findByActivityGuid(
      String userId, String activityGuid) async {
    final result = await _conn.execute(
      Sql.named(
          '${_selectUploads}WHERE user_id = @user_id AND activity_guid = @guid'),
      parameters: {'user_id': userId, 'guid': activityGuid},
    );
    if (result.isEmpty) return null;
    return _fromRow(result.first.toColumnMap());
  }

  @override
  Future<List<UploadRecord>> listUploads(String userId) async {
    final result = await _conn.execute(
      Sql.named('${_selectUploads}WHERE user_id = @user_id '
          'ORDER BY received_at DESC LIMIT 100'),
      parameters: {'user_id': userId},
    );
    return [for (final row in result) _fromRow(row.toColumnMap())];
  }

  @override
  Future<UserStats> statsFor(String userId) async {
    final result = await _conn.execute(
      Sql.named('SELECT COUNT(*) AS n, '
          'COALESCE(SUM(ST_Length(route::geography)), 0) AS total '
          'FROM uploads WHERE user_id = @user_id'),
      parameters: {'user_id': userId},
    );
    final m = result.first.toColumnMap();
    return UserStats((m['n'] as num).toInt(), _comoDouble(m['total']) ?? 0);
  }

  @override
  Future<RouteData?> getRoute(String id, {required String userId}) async {
    final result = await _conn.execute(
      Sql.named(
        'SELECT ST_AsGeoJSON(route) AS geojson, point_count, '
        'ST_Length(route::geography) AS length_meters '
        'FROM uploads WHERE id = @id AND user_id = @user_id',
      ),
      parameters: {'id': id, 'user_id': userId},
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
      'SELECT id, user_id, status, received_at, size_bytes, activity_guid, point_count, '
      'ST_Length(route::geography) AS length_meters FROM uploads ';

  UploadRecord _fromRow(Map<String, dynamic> m) => UploadRecord(
        id: m['id'] as String,
        userId: m['user_id'] as String?,
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
