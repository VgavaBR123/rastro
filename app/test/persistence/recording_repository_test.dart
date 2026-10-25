// Testes de persistencia com banco em memoria (shift-left: integra dominio + Drift).
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/persistence/recording_repository.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/domain/waypoint.dart' as dom;

dom.Waypoint wp(int t, double dist, double lat) => dom.Waypoint(
      position: GeoPoint(latitude: lat, longitude: 0, altitudeMeters: 100 + t.toDouble()),
      cumulativeDistanceMeters: dist,
      elapsedTimeMs: t,
      timerTimeMs: t,
      classification: dom.WaypointClassification.accept,
      horizontalAccuracyMeters: 5,
    );

void main() {
  late RecordingDatabase db;
  late RecordingRepository repo;

  setUp(() {
    db = RecordingDatabase(NativeDatabase.memory());
    repo = RecordingRepository(db);
  });

  tearDown(() async => db.close());

  test('grava cabecalho, anexa pontos em lote e le em ordem', () async {
    await repo.startActivity(
      guid: 'a1',
      type: ActivityType.run,
      startTimestampMs: 1000,
      startBatteryLevel: 90,
    );
    await repo.appendWaypoints('a1', [wp(0, 0, 0.0), wp(1000, 11, 0.0001)]);
    await repo.appendWaypoints('a1', [wp(2000, 22, 0.0002)]);

    final pts = await repo.waypoints('a1');
    expect(pts.length, 3);
    expect(pts.map((e) => e.seq), [0, 1, 2]); // sequencia continua entre lotes
    expect(pts.last.cumulativeDistanceMeters, 22);
    expect(pts.last.altitudeMeters, 100 + 2000);
  });

  test('atividade nao finalizada aparece na recuperacao; some apos finish', () async {
    await repo.startActivity(
      guid: 'a2',
      type: ActivityType.ride,
      startTimestampMs: 5000,
    );
    await repo.appendWaypoints('a2', [wp(0, 0, 0.0)]);

    var pend = await repo.unfinished();
    expect(pend.map((e) => e.guid), contains('a2'));
    expect(pend.first.syncState, SyncState.recording);

    await repo.finish('a2', 9000, endBattery: 70);

    pend = await repo.unfinished();
    expect(pend.map((e) => e.guid), isNot(contains('a2')));

    final header = await (db.select(db.activities)
          ..where((t) => t.guid.equals('a2')))
        .getSingle();
    expect(header.isFinished, true);
    expect(header.syncState, SyncState.pending); // foi para a fila (etapa 06)
    expect(header.endBatteryLevel, 70);
  });
}
