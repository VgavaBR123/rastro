// Implementacao do ActivityStore sobre PostgreSQL/PostGIS.
library;

import 'dart:convert';
import 'dart:typed_data';

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
      'REFERENCES users(id) ON DELETE CASCADE',
  // Idempotencia passou a ser por (usuario, atividade): o indice antigo, so
  // por activity_guid, impediria dois usuarios de usarem o mesmo guid.
  'DROP INDEX IF EXISTS uq_uploads_activity_guid',
  'CREATE UNIQUE INDEX IF NOT EXISTS uq_uploads_user_activity_guid '
      'ON uploads (user_id, activity_guid) WHERE activity_guid IS NOT NULL',
  'CREATE INDEX IF NOT EXISTS idx_uploads_user_received '
      'ON uploads (user_id, received_at DESC)',
  // Exclusao de conta: uploads saem junto com o usuario. Volumes antigos
  // tinham a FK sem cascata; troca so se ainda nao for CASCADE.
  r'''DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT conname FROM pg_constraint
    WHERE conrelid = 'uploads'::regclass AND confrelid = 'users'::regclass
      AND contype = 'f' AND confdeltype <> 'c'
  LOOP
    EXECUTE format('ALTER TABLE uploads DROP CONSTRAINT %I', r.conname);
  END LOOP;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint
    WHERE conrelid = 'uploads'::regclass AND confrelid = 'users'::regclass
      AND contype = 'f') THEN
    ALTER TABLE uploads ADD CONSTRAINT uploads_user_id_fkey
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
  END IF;
END $$''',
  // Conserta uploads gravados antes da correcao do tipo do parametro `fit`:
  // o bytea guardava o texto do array ("{14,32,...}"). Um FIT de verdade
  // nunca comeca com '{' (o 1o byte e o tamanho do header, 12 ou 14), entao
  // so linhas nesse formato sao convertidas de volta para os bytes.
  // ATENCAO: o filtro usa encode(fit, 'escape'), que aceita qualquer byte. O
  // Postgres nao garante a ordem de avaliacao do AND no WHERE; com
  // convert_from(fit, 'UTF8') ali, um FIT binario de verdade (tem 0x00)
  // derrubava a migracao e o servidor nao subia mais.
  r'''UPDATE uploads SET fit = decode((
    SELECT string_agg(lpad(to_hex(t.b), 2, '0'), '' ORDER BY t.i)
    FROM unnest(encode(fit, 'escape')::int[]) WITH ORDINALITY AS t(b, i)
  ), 'hex')
WHERE encode(fit, 'escape') ~ '^\{[0-9]{1,3}(,[0-9]{1,3})*\}$'
''',
  // Metadados da atividade (headers do upload e derivados do FIT).
  'ALTER TABLE uploads ADD COLUMN IF NOT EXISTS activity_type TEXT NULL',
  'ALTER TABLE uploads ADD COLUMN IF NOT EXISTS name TEXT NULL',
  'ALTER TABLE uploads ADD COLUMN IF NOT EXISTS start_time BIGINT NULL',
  'ALTER TABLE uploads ADD COLUMN IF NOT EXISTS elapsed_time_ms BIGINT NULL',
  'ALTER TABLE uploads ADD COLUMN IF NOT EXISTS timer_time_ms BIGINT NULL',
  'ALTER TABLE uploads ADD COLUMN IF NOT EXISTS distance_meters '
      'DOUBLE PRECISION NULL',
  // Paginacao por keyset na ordem da listagem.
  'CREATE INDEX IF NOT EXISTS idx_uploads_user_sort ON uploads '
      '(user_id, (COALESCE(start_time, received_at)) DESC, id COLLATE "C" DESC)',
  // Recuperacao de senha: um pedido por usuario, so o hash do codigo.
  'CREATE TABLE IF NOT EXISTS password_resets ('
      'user_id TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE, '
      'code_hash TEXT NOT NULL, '
      'created_at BIGINT NOT NULL, '
      'expires_at BIGINT NOT NULL, '
      'attempts INTEGER NOT NULL DEFAULT 0)',
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
  Future<bool> ping() async {
    final result = await _conn.execute('SELECT 1');
    return result.isNotEmpty;
  }

  @override
  Future<UploadRecord> saveUpload(List<int> fitBytes,
      {required String userId,
      String? activityGuid,
      ActivityMetadata metadata = const ActivityMetadata(),
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
      // Tipo explicito: sem ele o driver infere List<int> como int[] e o
      // bytea recebia o texto "{14,32,...}" em vez dos bytes do arquivo.
      'fit': TypedValue(Type.byteArray, Uint8List.fromList(fitBytes)),
      'type': metadata.activityType,
      'start': metadata.startTimeMs,
      'elapsed': metadata.elapsedTimeMs,
      'timer': metadata.timerTimeMs,
      'distance': metadata.distanceMeters,
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
        '(id, user_id, status, received_at, size_bytes, activity_guid, fit, route, point_count, '
        'activity_type, start_time, elapsed_time_ms, timer_time_ms, distance_meters) '
        'VALUES (@id, @user_id, @status, @received_at, @size, @guid, @fit, $routeExpr, @points, '
        '@type, @start, @elapsed, @timer, @distance) '
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
      activityType: metadata.activityType,
      startTimeMs: metadata.startTimeMs,
      elapsedTimeMs: metadata.elapsedTimeMs,
      timerTimeMs: metadata.timerTimeMs,
      distanceMeters: metadata.distanceMeters,
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

  /// Ordem da listagem; id em "C" para bater com a comparacao do keyset e
  /// com o indice idx_uploads_user_sort.
  static const String _ordem =
      'ORDER BY COALESCE(start_time, received_at) DESC, id COLLATE "C" DESC';

  @override
  Future<List<UploadRecord>> listUploads(String userId) async {
    final result = await _conn.execute(
      Sql.named('${_selectUploads}WHERE user_id = @user_id $_ordem'),
      parameters: {'user_id': userId},
    );
    return [for (final row in result) _fromRow(row.toColumnMap())];
  }

  @override
  Future<List<UploadRecord>> listPage(String userId,
      {required int limit, ActivityCursor? after}) async {
    final String filtro = after == null
        ? ''
        : 'AND (COALESCE(start_time, received_at), id COLLATE "C") '
            '< (@k::bigint, @cid::text COLLATE "C") ';
    final result = await _conn.execute(
      Sql.named('${_selectUploads}WHERE user_id = @user_id $filtro'
          '$_ordem LIMIT @limit'),
      parameters: {
        'user_id': userId,
        'limit': limit,
        if (after != null) 'k': after.sortKey,
        if (after != null) 'cid': after.id,
      },
    );
    return [for (final row in result) _fromRow(row.toColumnMap())];
  }

  @override
  Future<UploadRecord?> updateName(String id,
      {required String userId, String? name}) async {
    final result = await _conn.execute(
      Sql.named('UPDATE uploads SET name = @name::text '
          'WHERE id = @id AND user_id = @user_id RETURNING id'),
      parameters: {'id': id, 'user_id': userId, 'name': name},
    );
    if (result.isEmpty) return null;
    return getUpload(id, userId: userId);
  }

  @override
  Future<bool> deleteUpload(String id, {required String userId}) async {
    final result = await _conn.execute(
      Sql.named('DELETE FROM uploads WHERE id = @id AND user_id = @user_id '
          'RETURNING id'),
      parameters: {'id': id, 'user_id': userId},
    );
    return result.isNotEmpty;
  }

  @override
  Future<List<int>?> getFit(String id, {required String userId}) async {
    final result = await _conn.execute(
      Sql.named(
          'SELECT fit FROM uploads WHERE id = @id AND user_id = @user_id'),
      parameters: {'id': id, 'user_id': userId},
    );
    if (result.isEmpty) return null;
    return result.first.toColumnMap()['fit'] as List<int>?;
  }

  @override
  Future<void> deleteAllForUser(String userId) async {
    await _conn.execute(
      Sql.named('DELETE FROM uploads WHERE user_id = @user_id'),
      parameters: {'user_id': userId},
    );
  }

  @override
  Future<UserStats> statsFor(String userId) async {
    // Distancia efetiva por atividade: a informada pelo app, senao a da rota.
    final result = await _conn.execute(
      Sql.named('SELECT activity_type, COUNT(*) AS n, '
          'COALESCE(SUM(COALESCE(distance_meters, '
          'ST_Length(route::geography), 0)), 0) AS total, '
          'COALESCE(SUM(timer_time_ms), 0) AS timer '
          'FROM uploads WHERE user_id = @user_id GROUP BY activity_type'),
      parameters: {'user_id': userId},
    );
    var n = 0;
    var total = 0.0;
    var timer = 0;
    final Map<String, TypeStats> porTipo = {};
    for (final row in result) {
      final m = row.toColumnMap();
      final int qtd = (m['n'] as num).toInt();
      final double dist = _comoDouble(m['total']) ?? 0;
      n += qtd;
      total += dist;
      timer += _comoInt(m['timer']) ?? 0;
      final String? tipo = m['activity_type'] as String?;
      if (tipo != null) porTipo[tipo] = TypeStats(qtd, dist);
    }
    return UserStats(n, total, totalTimerTimeMs: timer, byType: porTipo);
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
      'activity_type, name, start_time, elapsed_time_ms, timer_time_ms, distance_meters, '
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
        activityType: m['activity_type'] as String?,
        name: m['name'] as String?,
        startTimeMs: _comoInt(m['start_time']),
        elapsedTimeMs: _comoInt(m['elapsed_time_ms']),
        timerTimeMs: _comoInt(m['timer_time_ms']),
        distanceMeters: _comoDouble(m['distance_meters']),
      );

  /// SUM de BIGINT volta numeric; o driver pode entregar como string.
  static int? _comoInt(Object? valor) {
    if (valor == null) return null;
    if (valor is int) return valor;
    if (valor is num) return valor.toInt();
    return int.tryParse(valor.toString());
  }

  /// ST_Length pode voltar como double ou numeric dependendo do driver.
  static double? _comoDouble(Object? valor) {
    if (valor == null) return null;
    if (valor is double) return valor;
    if (valor is num) return valor.toDouble();
    return double.tryParse(valor.toString());
  }
}
