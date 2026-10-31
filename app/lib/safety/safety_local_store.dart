// Registro local das sessoes do Rastro Seguro (F08) criadas neste aparelho,
// no banco da gravacao (tabela safety_local_sessions, migracao 13 -> 14).
library;

import 'package:drift/drift.dart';

import '../persistence/database.dart';

class SafetyLocalStore {
  final RecordingDatabase _db;
  SafetyLocalStore(this._db);

  Future<void> created({
    required String sessionId,
    required String activityGuid,
    required String? ownerUserId,
    required int nowMs,
  }) => _db
      .into(_db.safetyLocalSessions)
      .insertOnConflictUpdate(
        SafetyLocalSessionsCompanion.insert(
          sessionId: sessionId,
          activityGuid: activityGuid,
          ownerUserId: Value(ownerUserId),
          createdAtMs: nowMs,
        ),
      );

  Future<bool> isLocal(String sessionId) async =>
      await (_db.select(_db.safetyLocalSessions)..where((t) => t.sessionId.equals(sessionId))).getSingleOrNull() !=
      null;

  Future<void> markPendingArrival(String sessionId) =>
      (_db.update(_db.safetyLocalSessions)..where((t) => t.sessionId.equals(sessionId))).write(
        const SafetyLocalSessionsCompanion(pendingArrival: Value(true)),
      );

  /// "arrived" que ainda nao chegou ao backend (de [ownerUserId], se dado).
  Future<List<SafetyLocalSessionRow>> pendingArrivals({String? ownerUserId}) {
    final q = _db.select(_db.safetyLocalSessions)..where((t) => t.pendingArrival.equals(true));
    if (ownerUserId != null) q.where((t) => t.ownerUserId.equals(ownerUserId));
    return q.get();
  }

  /// Sessao encerrada no backend (ou que nao existe mais): sai do registro.
  Future<void> ended(String sessionId) =>
      (_db.delete(_db.safetyLocalSessions)..where((t) => t.sessionId.equals(sessionId))).go();

  /// Ate onde os alertas ja viraram notificacao local (createdAt, epoch ms).
  Future<int> alertsSeenMs() async =>
      (await (_db.select(_db.safetyMeta)..where((t) => t.key.equals(_kAlertsSeen))).getSingleOrNull())?.intValue ?? 0;

  Future<void> setAlertsSeenMs(int ms) =>
      _db.into(_db.safetyMeta).insertOnConflictUpdate(SafetyMetaCompanion.insert(key: _kAlertsSeen, intValue: ms));

  static const String _kAlertsSeen = 'alerts_seen_ms';
}
