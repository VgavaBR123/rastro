// Testes do SyncController (orquestra a fila via SyncService).
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/persistence/recording_repository.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/domain/waypoint.dart' as dom;
import 'package:strava_estudo_app/sync/sync_controller.dart';
import 'package:strava_estudo_app/sync/upload/activity_uploader.dart';
import 'package:strava_estudo_app/sync/upload/sync_service.dart';

class FakeUploader implements ActivityUploader {
  final bool fail;
  FakeUploader({this.fail = false});
  @override
  Future<String> upload(Uint8List fitBytes,
      {required String activityGuid, UploadMetadata? metadata}) async {
    if (fail) throw UploadException('boom');
    return 'ok-$activityGuid';
  }
}

dom.Waypoint acc() => dom.Waypoint(
      position: const GeoPoint(latitude: 0, longitude: 0, altitudeMeters: 100),
      cumulativeDistanceMeters: 10,
      elapsedTimeMs: 0,
      timerTimeMs: 0,
      classification: dom.WaypointClassification.accept,
      horizontalAccuracyMeters: 5,
    );

Future<void> seedPending(RecordingRepository repo, String guid) async {
  await repo.startActivity(guid: guid, type: ActivityType.run, startTimestampMs: 1000);
  await repo.appendWaypoints(guid, [acc()]);
  await repo.finish(guid, 2000, distanceMeters: 10, timerTimeMs: 1000);
}

void main() {
  late RecordingDatabase db;
  late RecordingRepository repo;
  setUp(() {
    db = RecordingDatabase(NativeDatabase.memory());
    repo = RecordingRepository(db);
  });
  tearDown(() async => db.close());

  test('sem pendentes: mensagem "Nada para sincronizar"', () async {
    final c = SyncController(SyncService(db, FakeUploader()), db,
        currentUserId: () async => 'u1');
    await c.syncNow();
    expect(c.state.running, false);
    expect(c.state.message, 'Nada para sincronizar');
  });

  test('HIS-01: cada toque gera um resultado novo, mesmo com o texto igual',
      () async {
    final c = SyncController(SyncService(db, FakeUploader()), db,
        currentUserId: () async => null);
    await c.syncNow();
    final first = c.state.messageSeq;
    await c.syncNow();
    expect(c.state.message, kSignInToSyncMessage);
    expect(c.state.messageSeq, first + 1);
  });

  test('sucesso: mensagem de sincronizadas e estado synced', () async {
    await seedPending(repo, 'a');
    final c = SyncController(SyncService(db, FakeUploader()), db,
        currentUserId: () async => 'u1');
    await c.syncNow();
    expect(c.state.message, contains('1 sincronizada'));
    final h = await (db.select(db.activities)..where((t) => t.guid.equals('a'))).getSingle();
    expect(h.syncState, SyncState.synced);
  });

  test('falha: conta como falhou e marca failed', () async {
    await seedPending(repo, 'a');
    final c = SyncController(SyncService(db, FakeUploader(fail: true)), db,
        currentUserId: () async => 'u1');
    await c.syncNow();
    expect(c.state.message, contains('falhou'));
    final h = await (db.select(db.activities)..where((t) => t.guid.equals('a'))).getSingle();
    expect(h.syncState, SyncState.failed);
  });

  test('sync manual re-tenta o que falhou ou ficou preso em uploading', () async {
    await seedPending(repo, 'f');
    await seedPending(repo, 'u');
    await db.setSyncState('f', SyncState.failed);
    await db.setSyncState('u', SyncState.uploading);
    final c = SyncController(SyncService(db, FakeUploader()), db,
        currentUserId: () async => 'u1');
    await c.syncNow();
    expect(c.state.message, contains('2 sincronizada'));
    final rows = await db.select(db.activities).get();
    expect(rows.map((r) => r.syncState), everyElement(SyncState.synced));
  });
}
