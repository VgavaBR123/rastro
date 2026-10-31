// SafetyStore sobre PostgreSQL. O DDL abaixo entra na lista de migracoes
// idempotentes do PostgresActivityStore (aplicada ao conectar) e esta
// repetido em db/init.sql para volumes novos.
library;

import 'dart:convert';

import 'package:postgres/postgres.dart';

import 'safety_store.dart';

/// Migracoes idempotentes do Rastro Seguro. Todas as tabelas tem FK para
/// users com ON DELETE CASCADE: excluir a conta leva tudo junto.
const List<String> safetySchemaSql = <String>[
  'CREATE TABLE IF NOT EXISTS safety_contacts ('
      'id TEXT PRIMARY KEY, '
      'owner_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE, '
      'contact_user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE, '
      "status TEXT NOT NULL CHECK (status IN ('pending', 'accepted')), "
      'created_at BIGINT NOT NULL, '
      'accepted_at BIGINT NULL, '
      'UNIQUE (owner_id, contact_user_id))',
  'CREATE INDEX IF NOT EXISTS idx_safety_contacts_contact '
      'ON safety_contacts (contact_user_id)',
  // Sem historico de trajeto: so a ultima posicao e o inicio da parada.
  'CREATE TABLE IF NOT EXISTS safety_sessions ('
      'id TEXT PRIMARY KEY, '
      'owner_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE, '
      'activity_guid TEXT NOT NULL, '
      "status TEXT NOT NULL CHECK (status IN ('active', 'checking', 'alerted', 'ended')), "
      'eta_ms BIGINT NOT NULL, '
      'started_at BIGINT NOT NULL, '
      'ended_at BIGINT NULL, '
      'end_reason TEXT NULL, '
      'last_signal_at BIGINT NOT NULL, '
      'last_lat DOUBLE PRECISION NULL, '
      'last_lon DOUBLE PRECISION NULL, '
      'last_accuracy_m DOUBLE PRECISION NULL, '
      'last_recorded_at BIGINT NULL, '
      'still_since BIGINT NULL, '
      "contact_ids JSONB NOT NULL DEFAULT '[]'::jsonb, "
      'check_reason TEXT NULL, '
      'check_started_at BIGINT NULL, '
      'check_deadline BIGINT NULL, '
      'alerted_at BIGINT NULL, '
      'eta_recheck_after BIGINT NULL, '
      'share_token TEXT NOT NULL UNIQUE, '
      'share_expires_at BIGINT NULL)',
  // Uma sessao nao encerrada por dona, garantido pelo banco (corrida de dois
  // POST /safety/sessions simultaneos).
  'CREATE UNIQUE INDEX IF NOT EXISTS uq_safety_sessions_owner_open '
      "ON safety_sessions (owner_id) WHERE status <> 'ended'",
  'CREATE INDEX IF NOT EXISTS idx_safety_sessions_ended '
      "ON safety_sessions (ended_at) WHERE status = 'ended'",
  'CREATE TABLE IF NOT EXISTS notifications ('
      'id TEXT PRIMARY KEY, '
      'user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE, '
      'type TEXT NOT NULL, '
      'title TEXT NOT NULL, '
      'body TEXT NOT NULL, '
      "data JSONB NOT NULL DEFAULT '{}'::jsonb, "
      'created_at BIGINT NOT NULL, '
      'read_at BIGINT NULL)',
  'CREATE INDEX IF NOT EXISTS idx_notifications_user_created '
      'ON notifications (user_id, created_at DESC, id DESC)',
  'CREATE TABLE IF NOT EXISTS push_tokens ('
      'token TEXT PRIMARY KEY, '
      'user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE, '
      "platform TEXT NOT NULL CHECK (platform IN ('android', 'ios')), "
      'updated_at BIGINT NOT NULL)',
  'CREATE INDEX IF NOT EXISTS idx_push_tokens_user ON push_tokens (user_id)',
];

class PostgresSafetyStore implements SafetyStore {
  PostgresSafetyStore(this._conn);
  final Connection _conn;

  static const String _colsContato =
      'id, owner_id, contact_user_id, status, created_at, accepted_at';

  static const String _colsSessao =
      'id, owner_id, activity_guid, status, eta_ms, started_at, ended_at, '
      'end_reason, last_signal_at, last_lat, last_lon, last_accuracy_m, '
      'last_recorded_at, still_since, contact_ids, check_reason, '
      'check_started_at, check_deadline, alerted_at, eta_recheck_after, '
      'share_token, share_expires_at';

  Future<Result> _q(String sql, [Map<String, Object?>? p]) =>
      _conn.execute(Sql.named(sql), parameters: p ?? const {});

  // ---------------------------------------------------------------- contatos

  @override
  Future<ContactRecord?> createContact(ContactRecord c) async {
    final r = await _q(
      'INSERT INTO safety_contacts ($_colsContato) '
      'VALUES (@id, @owner, @contact, @status, @created, @accepted) '
      'ON CONFLICT (owner_id, contact_user_id) DO NOTHING RETURNING id',
      {
        'id': c.id,
        'owner': c.ownerId,
        'contact': c.contactUserId,
        'status': c.status,
        'created': c.createdAtMs,
        'accepted': c.acceptedAtMs,
      },
    );
    return r.isEmpty ? null : c.copy();
  }

  @override
  Future<ContactRecord?> findContact(String id) async {
    final r =
        await _q('SELECT $_colsContato FROM safety_contacts WHERE id = @id',
            {'id': id});
    return r.isEmpty ? null : _contato(r.first.toColumnMap());
  }

  @override
  Future<List<ContactRecord>> contactsOfUser(String userId) async {
    final r = await _q(
      'SELECT $_colsContato FROM safety_contacts '
      'WHERE owner_id = @u OR contact_user_id = @u ORDER BY created_at, id',
      {'u': userId},
    );
    return [for (final row in r) _contato(row.toColumnMap())];
  }

  @override
  Future<int> countAcceptedContacts(String ownerId) async {
    final r = await _q(
      'SELECT count(*)::int AS n FROM safety_contacts '
      "WHERE owner_id = @u AND status = 'accepted'",
      {'u': ownerId},
    );
    return r.first.toColumnMap()['n'] as int;
  }

  @override
  Future<void> saveContact(ContactRecord c) async {
    await _q(
      'UPDATE safety_contacts SET status = @status, accepted_at = @accepted '
      'WHERE id = @id',
      {'id': c.id, 'status': c.status, 'accepted': c.acceptedAtMs},
    );
  }

  @override
  Future<void> deleteContact(String id) async {
    await _q('DELETE FROM safety_contacts WHERE id = @id', {'id': id});
  }

  ContactRecord _contato(Map<String, dynamic> m) => ContactRecord(
        id: m['id'] as String,
        ownerId: m['owner_id'] as String,
        contactUserId: m['contact_user_id'] as String,
        status: m['status'] as String,
        createdAtMs: m['created_at'] as int,
        acceptedAtMs: m['accepted_at'] as int?,
      );

  // ----------------------------------------------------------------- sessoes

  Map<String, Object?> _paramsSessao(SafetySessionRecord s) => {
        'id': s.id,
        'owner': s.ownerId,
        'guid': s.activityGuid,
        'status': s.status,
        'eta': s.etaMs,
        'started': s.startedAtMs,
        'ended': s.endedAtMs,
        'end_reason': s.endReason,
        'signal': s.lastSignalAtMs,
        'lat': s.lastPosition?.lat,
        'lon': s.lastPosition?.lon,
        'acc': s.lastPosition?.accuracyM,
        'rec': s.lastPosition?.recordedAtMs,
        'still': s.stillSinceMs,
        'contacts': jsonEncode(s.contactIds),
        'check_reason': s.checkReason,
        'check_started': s.checkStartedAtMs,
        'check_deadline': s.checkDeadlineMs,
        'alerted': s.alertedAtMs,
        'recheck': s.etaRecheckAfterMs,
        'token': s.shareToken,
        'share_exp': s.shareExpiresAtMs,
      };

  @override
  Future<SafetySessionRecord?> createSession(SafetySessionRecord s) async {
    // O indice unico parcial (uma sessao aberta por dona) decide a corrida:
    // ON CONFLICT DO NOTHING devolve vazio para quem perdeu.
    final r = await _q(
      'INSERT INTO safety_sessions ($_colsSessao) VALUES ('
      '@id, @owner, @guid, @status, @eta, @started, @ended, @end_reason, '
      '@signal, @lat::double precision, @lon::double precision, '
      '@acc::double precision, @rec::bigint, @still::bigint, @contacts::jsonb, '
      '@check_reason, @check_started::bigint, @check_deadline::bigint, '
      '@alerted::bigint, @recheck::bigint, @token, @share_exp::bigint) '
      "ON CONFLICT (owner_id) WHERE status <> 'ended' DO NOTHING RETURNING id",
      _paramsSessao(s),
    );
    return r.isEmpty ? null : s.copy();
  }

  @override
  Future<void> saveSession(SafetySessionRecord s) async {
    await _q(
      'UPDATE safety_sessions SET status = @status, eta_ms = @eta, '
      'ended_at = @ended::bigint, end_reason = @end_reason::text, '
      'last_signal_at = @signal, last_lat = @lat::double precision, '
      'last_lon = @lon::double precision, '
      'last_accuracy_m = @acc::double precision, '
      'last_recorded_at = @rec::bigint, still_since = @still::bigint, '
      'contact_ids = @contacts::jsonb, check_reason = @check_reason::text, '
      'check_started_at = @check_started::bigint, '
      'check_deadline = @check_deadline::bigint, alerted_at = @alerted::bigint, '
      'eta_recheck_after = @recheck::bigint, '
      'share_expires_at = @share_exp::bigint '
      'WHERE id = @id AND owner_id = @owner AND activity_guid = @guid '
      'AND started_at = @started AND share_token = @token',
      _paramsSessao(s),
    );
  }

  Future<SafetySessionRecord?> _umaSessao(
      String where, Map<String, Object?> p) async {
    final r = await _q('SELECT $_colsSessao FROM safety_sessions WHERE $where '
        'LIMIT 1', p);
    return r.isEmpty ? null : _sessao(r.first.toColumnMap());
  }

  @override
  Future<SafetySessionRecord?> findSession(String id) =>
      _umaSessao('id = @id', {'id': id});

  @override
  Future<SafetySessionRecord?> findOpenSessionOfOwner(String ownerId) =>
      _umaSessao("owner_id = @o AND status <> 'ended'", {'o': ownerId});

  @override
  Future<SafetySessionRecord?> findSessionByShareToken(String token) =>
      _umaSessao('share_token = @t', {'t': token});

  @override
  Future<List<SafetySessionRecord>> openSessions() async {
    final r = await _q(
        "SELECT $_colsSessao FROM safety_sessions WHERE status <> 'ended'");
    return [for (final row in r) _sessao(row.toColumnMap())];
  }

  @override
  Future<int> deleteSessionsEndedBefore(int ms) async {
    final r = await _q(
      "DELETE FROM safety_sessions WHERE status = 'ended' AND ended_at < @ms "
      'RETURNING id',
      {'ms': ms},
    );
    return r.length;
  }

  SafetySessionRecord _sessao(Map<String, dynamic> m) {
    final double? lat = (m['last_lat'] as num?)?.toDouble();
    final double? lon = (m['last_lon'] as num?)?.toDouble();
    final Object? ids = m['contact_ids'];
    final Object? lista = ids is String ? jsonDecode(ids) : ids;
    return SafetySessionRecord(
      id: m['id'] as String,
      ownerId: m['owner_id'] as String,
      activityGuid: m['activity_guid'] as String,
      status: m['status'] as String,
      etaMs: m['eta_ms'] as int,
      startedAtMs: m['started_at'] as int,
      endedAtMs: m['ended_at'] as int?,
      endReason: m['end_reason'] as String?,
      lastSignalAtMs: m['last_signal_at'] as int,
      lastPosition: (lat == null || lon == null)
          ? null
          : SafetyPosition(
              lat: lat,
              lon: lon,
              accuracyM: (m['last_accuracy_m'] as num?)?.toDouble(),
              recordedAtMs: m['last_recorded_at'] as int,
            ),
      stillSinceMs: m['still_since'] as int?,
      contactIds: [for (final x in (lista as List? ?? const [])) x as String],
      checkReason: m['check_reason'] as String?,
      checkStartedAtMs: m['check_started_at'] as int?,
      checkDeadlineMs: m['check_deadline'] as int?,
      alertedAtMs: m['alerted_at'] as int?,
      etaRecheckAfterMs: m['eta_recheck_after'] as int?,
      shareToken: m['share_token'] as String,
      shareExpiresAtMs: m['share_expires_at'] as int?,
    );
  }

  // ------------------------------------------------------------ notificacoes

  @override
  Future<void> addNotification(NotificationRecord n) async {
    await _q(
      'INSERT INTO notifications '
      '(id, user_id, type, title, body, data, created_at, read_at) VALUES '
      '(@id, @user, @type, @title, @body, @data::jsonb, @created, '
      '@read::bigint)',
      {
        'id': n.id,
        'user': n.userId,
        'type': n.type,
        'title': n.title,
        'body': n.body,
        'data': jsonEncode(n.data),
        'created': n.createdAtMs,
        'read': n.readAtMs,
      },
    );
  }

  @override
  Future<List<NotificationRecord>> notificationsOf(String userId,
      {int? sinceMs, required int limit}) async {
    final r = await _q(
      'SELECT id, user_id, type, title, body, data, created_at, read_at '
      'FROM notifications WHERE user_id = @u '
      'AND (@since::bigint IS NULL OR created_at > @since::bigint) '
      'ORDER BY created_at DESC, id DESC LIMIT @limit',
      {'u': userId, 'since': sinceMs, 'limit': limit},
    );
    return [
      for (final row in r)
        () {
          final m = row.toColumnMap();
          final Object? d = m['data'];
          final Object? dados = d is String ? jsonDecode(d) : d;
          return NotificationRecord(
            id: m['id'] as String,
            userId: m['user_id'] as String,
            type: m['type'] as String,
            title: m['title'] as String,
            body: m['body'] as String,
            data: Map<String, dynamic>.from(dados as Map? ?? const {}),
            createdAtMs: m['created_at'] as int,
            readAtMs: m['read_at'] as int?,
          );
        }()
    ];
  }

  @override
  Future<bool> markNotificationRead(String id,
      {required String userId, required int nowMs}) async {
    final r = await _q(
      'UPDATE notifications SET read_at = COALESCE(read_at, @now) '
      'WHERE id = @id AND user_id = @u RETURNING id',
      {'id': id, 'u': userId, 'now': nowMs},
    );
    return r.isNotEmpty;
  }

  // --------------------------------------------------------- tokens de push

  @override
  Future<void> upsertPushToken(PushTokenRecord t) async {
    await _q(
      'INSERT INTO push_tokens (token, user_id, platform, updated_at) '
      'VALUES (@t, @u, @p, @now) ON CONFLICT (token) DO UPDATE SET '
      'user_id = EXCLUDED.user_id, platform = EXCLUDED.platform, '
      'updated_at = EXCLUDED.updated_at',
      {'t': t.token, 'u': t.userId, 'p': t.platform, 'now': t.updatedAtMs},
    );
  }

  @override
  Future<void> deletePushToken(String token, {required String userId}) async {
    await _q('DELETE FROM push_tokens WHERE token = @t AND user_id = @u',
        {'t': token, 'u': userId});
  }

  @override
  Future<void> deletePushTokenAnyOwner(String token) async {
    await _q('DELETE FROM push_tokens WHERE token = @t', {'t': token});
  }

  @override
  Future<List<PushTokenRecord>> pushTokensOf(String userId) async {
    final r = await _q(
      'SELECT token, user_id, platform, updated_at FROM push_tokens '
      'WHERE user_id = @u',
      {'u': userId},
    );
    return [
      for (final row in r)
        () {
          final m = row.toColumnMap();
          return PushTokenRecord(
            token: m['token'] as String,
            userId: m['user_id'] as String,
            platform: m['platform'] as String,
            updatedAtMs: m['updated_at'] as int,
          );
        }()
    ];
  }

  @override
  Future<void> deleteAllForUser(String userId) async {
    // A FK em cascata ja apaga ao excluir o usuario; isto deixa explicito e
    // cobre a ordem em que o DELETE /me chama os stores.
    await _conn.runTx((tx) async {
      for (final String sql in [
        'DELETE FROM safety_contacts WHERE owner_id = @u OR contact_user_id = @u',
        'DELETE FROM safety_sessions WHERE owner_id = @u',
        'DELETE FROM notifications WHERE user_id = @u',
        'DELETE FROM push_tokens WHERE user_id = @u',
      ]) {
        await tx.execute(Sql.named(sql), parameters: {'u': userId});
      }
    });
  }
}
