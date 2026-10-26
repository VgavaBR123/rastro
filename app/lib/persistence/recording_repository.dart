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

/// Converte uma linha do banco de volta em Waypoint de dominio.
dom.Waypoint waypointFromRow(Waypoint row) {
  return dom.Waypoint(
    position: GeoPoint(
      latitude: row.latitude,
      longitude: row.longitude,
      altitudeMeters: row.altitudeMeters,
    ),
    cumulativeDistanceMeters: row.cumulativeDistanceMeters,
    elapsedTimeMs: row.elapsedTimeMs,
    timerTimeMs: row.timerTimeMs,
    classification: dom.WaypointClassification.values[row.classification],
    horizontalAccuracyMeters: row.horizontalAccuracyMeters,
    verticalAccuracyMeters: row.verticalAccuracyMeters,
    speedMetersPerSecond: row.speedMetersPerSecond,
  );
}

/// Atividade que ficou sem finalizar (app morto, reboot) e o que ja foi salvo
/// dela, para a UI oferecer retomar, salvar ou descartar.
class InterruptedActivity {
  final Activity activity;

  /// Pontos aceitos persistidos, em ordem.
  final List<dom.Waypoint> acceptedPoints;

  const InterruptedActivity(this.activity, this.acceptedPoints);

  double get distanceMeters =>
      acceptedPoints.isEmpty ? 0 : acceptedPoints.last.cumulativeDistanceMeters;
  int get timerMs => acceptedPoints.isEmpty ? 0 : acceptedPoints.last.timerTimeMs;
  int get elapsedMs => acceptedPoints.isEmpty ? 0 : acceptedPoints.last.elapsedTimeMs;
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

  /// Atividades interrompidas com os pontos ja salvos, mais recentes primeiro.
  /// [exceptGuid] exclui a gravacao em andamento neste processo, se houver.
  Future<List<InterruptedActivity>> interrupted({String? exceptGuid}) async {
    final heads = (await db.unfinishedActivities())
        .where((a) => a.guid != exceptGuid)
        .toList()
      ..sort((a, b) => b.startTimestampMs.compareTo(a.startTimestampMs));
    return [
      for (final a in heads)
        InterruptedActivity(a, await _acceptedPoints(a.guid)),
    ];
  }

  /// Prepara a continuacao de uma atividade interrompida: os proximos pontos
  /// seguem a sequencia dos que ja estao no banco.
  Future<void> resumeActivity(String guid) async {
    final rows = await db.waypointsForActivity(guid);
    _seq[guid] = rows.isEmpty ? 0 : rows.last.seq + 1;
  }

  /// Finaliza uma atividade interrompida com o que foi salvo ate o crash. O
  /// fim e o instante do ultimo ponto (o tempo depois dele nao foi gravado).
  Future<void> finishInterrupted(InterruptedActivity interrupted) {
    final a = interrupted.activity;
    return finish(
      a.guid,
      a.startTimestampMs + interrupted.elapsedMs,
      distanceMeters: interrupted.distanceMeters,
      timerTimeMs: interrupted.timerMs,
    );
  }

  Future<List<dom.Waypoint>> _acceptedPoints(String guid) async {
    final rows = await db.waypointsForActivity(guid);
    return [
      for (final r in rows)
        if (r.classification == dom.WaypointClassification.accept.index)
          waypointFromRow(r),
    ];
  }

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
