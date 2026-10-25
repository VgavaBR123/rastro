/// Ponte entre o dominio da gravacao e o banco (Drift). Persiste o cabecalho e
/// anexa os pontos de forma incremental; oferece a base da recuperacao pos-crash.
/// Clean room a partir de relatorios/05-persistencia.md.
library;

import 'package:drift/drift.dart';

import '../recording/domain/geo.dart';
import '../recording/domain/recording_models.dart';
import '../recording/domain/waypoint.dart' as dom;
import 'database.dart';

/// Converte um Waypoint de dominio em linha do banco.
WaypointsCompanion waypointToCompanion(String activityGuid, int seq, dom.Waypoint w) {
  return WaypointsCompanion.insert(
    activityGuid: activityGuid,
    seq: seq,
    latitude: w.position.latitude,
    longitude: w.position.longitude,
    elapsedTimeMs: w.elapsedTimeMs,
    timerTimeMs: w.timerTimeMs,
    cumulativeDistanceMeters: w.cumulativeDistanceMeters,
    classification: w.classification.index,
    altitudeMeters: Value(w.position.altitudeMeters),
    horizontalAccuracyMeters: Value(w.horizontalAccuracyMeters),
    verticalAccuracyMeters: Value(w.verticalAccuracyMeters),
    speedMetersPerSecond: Value(w.speedMetersPerSecond),
  );
}

class RecordingRepository {
  final RecordingDatabase db;
  final Map<String, int> _seq = {};

  RecordingRepository(this.db);

  Future<void> startActivity({
    required String guid,
    required ActivityType type,
    required int startTimestampMs,
    bool isIndoor = false,
    bool autoPauseEnabled = true,
    int? startBatteryLevel,
  }) async {
    _seq[guid] = 0;
    await db.upsertActivity(ActivitiesCompanion.insert(
      guid: guid,
      activityType: type,
      startTimestampMs: startTimestampMs,
      syncState: SyncState.recording,
      isIndoor: Value(isIndoor),
      autoPauseEnabled: Value(autoPauseEnabled),
      startBatteryLevel: Value(startBatteryLevel),
    ));
  }

  /// Anexa um lote de pontos, mantendo a sequencia por atividade.
  Future<void> appendWaypoints(String guid, List<dom.Waypoint> points) async {
    var seq = _seq[guid] ?? 0;
    final rows = <WaypointsCompanion>[];
    for (final w in points) {
      rows.add(waypointToCompanion(guid, seq++, w));
    }
    _seq[guid] = seq;
    await db.appendWaypoints(rows);
  }

  Future<void> finish(
    String guid,
    int endTimestampMs, {
    int? endBattery,
    double? distanceMeters,
    int? timerTimeMs,
  }) {
    _seq.remove(guid);
    return db.markFinished(
      guid,
      endTimestampMs,
      endBattery: endBattery,
      distanceMeters: distanceMeters,
      timerTimeMs: timerTimeMs,
    );
  }

  /// Cabecalhos nao finalizados -- candidatos a recuperacao na subida do app.
  Future<List<Activity>> unfinished() => db.unfinishedActivities();

  /// Pontos persistidos de uma atividade, para o replay de reconstrucao.
  Future<List<Waypoint>> waypoints(String guid) => db.waypointsForActivity(guid);

  /// Atividades finalizadas, mais recentes primeiro (historico).
  Future<List<Activity>> recent({int limit = 50}) =>
      db.recentActivities(limit: limit);

  /// Remove uma atividade do historico (cabecalho + pontos).
  Future<void> deleteActivity(String guid) async {
    _seq.remove(guid);
    await db.deleteActivity(guid);
  }

  /// Trajeto (so pontos aceitos) de uma atividade, para desenhar no detalhe.
  Future<List<GeoPoint>> routePoints(String guid) async {
    final rows = await db.waypointsForActivity(guid);
    return [
      for (final w in rows)
        if (w.classification == 0)
          GeoPoint(
            latitude: w.latitude,
            longitude: w.longitude,
            altitudeMeters: w.altitudeMeters,
          ),
    ];
  }
}
