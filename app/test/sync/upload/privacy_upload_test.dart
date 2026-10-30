// Privacidade automatica (F02) no upload: o FIT enviado sai sem os pontos
// ocultos quando "Ocultar tambem no servidor" esta ligado, mantendo a
// distancia e o tempo totais nos metadados.
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/privacy/domain/privacy_zone.dart';
import 'package:strava_estudo_app/privacy/privacy_repository.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/sync/fit/fit_writer.dart';
import 'package:strava_estudo_app/sync/upload/activity_uploader.dart';
import 'package:strava_estudo_app/sync/upload/fit_activity_builder.dart';
import 'package:strava_estudo_app/sync/upload/sync_service.dart';

class CapturingUploader implements ActivityUploader {
  Uint8List? fit;
  UploadMetadata? metadata;

  @override
  Future<String> upload(
    Uint8List fitBytes, {
    required String activityGuid,
    UploadMetadata? metadata,
  }) async {
    fit = fitBytes;
    this.metadata = metadata;
    return 'r-$activityGuid';
  }
}

const int n = 300;
const double step = 0.0001; // ~11,1 m

Future<Activity> seed(RecordingDatabase db) async {
  await db.into(db.activities).insert(
    ActivitiesCompanion.insert(
      guid: 'a',
      activityType: ActivityType.run,
      startTimestampMs: 1000000,
      isFinished: const Value(true),
      syncState: SyncState.pending,
      distanceMeters: const Value(n * 11.1),
      timerTimeMs: const Value(n * 1000),
    ),
  );
  await db.batch((b) {
    b.insertAll(db.waypoints, [
      for (var i = 0; i < n; i++)
        WaypointsCompanion.insert(
          activityGuid: 'a',
          seq: i,
          latitude: 0,
          longitude: i * step,
          elapsedTimeMs: i * 1000,
          timerTimeMs: i * 1000,
          cumulativeDistanceMeters: i * 11.1,
          classification: 0,
        ),
    ]);
  });
  return (db.select(db.activities)..where((t) => t.guid.equals('a'))).getSingle();
}

void main() {
  late RecordingDatabase db;
  setUp(() => db = RecordingDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<Uint8List> fitOf(List<Waypoint> rows, Activity a) async => encodeActivityFit(
    startTimeUnixMs: a.startTimestampMs,
    records: [for (final w in rows) fitRecordFor(a, w)],
  );

  test('com zona e "ocultar no servidor": FIT so com os pontos visiveis', () async {
    final a = await seed(db);
    final privacy = PrivacyRepository(db);
    await privacy.addZone(
      const PrivacyZone(latitude: 0, longitude: 0, radiusMeters: 200, label: 'Casa'),
    );
    final up = CapturingUploader();
    await SyncService(db, up).processPending();

    final visible = await privacy.exportWaypoints(a);
    expect(visible.length, lessThan(n));
    expect(up.fit, await fitOf(visible, a));
    // Totais preservados nos metadados.
    expect(up.metadata!.distanceMeters, n * 11.1);
    expect(up.metadata!.timerTimeMs, n * 1000);
    expect(up.metadata!.startTimeMs, a.startTimestampMs);
  });

  test('"ocultar no servidor" desligado: FIT completo', () async {
    final a = await seed(db);
    await PrivacyRepository(db).addZone(
      const PrivacyZone(latitude: 0, longitude: 0, radiusMeters: 200, label: 'Casa'),
    );
    await db.saveSettings(hideOnServer: false);
    final up = CapturingUploader();
    await SyncService(db, up).processPending();
    expect(up.fit, await buildActivityFit(db, a));
    expect(up.fit, await fitOf(await db.waypointsForActivity('a'), a));
  });

  test('corte por atividade (primeiros e ultimos X m) tambem vale no upload', () async {
    await seed(db);
    await db.saveActivityDetails(
      'a',
      visibility: ActivityVisibility.onlyMe,
      hideEdgesMeters: 500,
    );
    final a = (await (db.select(db.activities)..where((t) => t.guid.equals('a'))).getSingle());
    final up = CapturingUploader();
    await SyncService(db, up).processPending();
    final visible = await PrivacyRepository(db).exportWaypoints(a);
    expect(visible.length, lessThan(n - 80));
    expect(up.fit, await fitOf(visible, a));
  });
}
