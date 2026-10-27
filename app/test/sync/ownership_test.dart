// Dono da atividade: as pendentes de uma conta nao sobem na conta de outra
// que entrar no mesmo aparelho; as gravadas sem conta vao para quem sincronizar.
import 'dart:async';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/persistence/recording_repository.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/location_sample.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/domain/waypoint.dart' as dom;
import 'package:strava_estudo_app/recording/presentation/recording_controller.dart';
import 'package:strava_estudo_app/recording/source/location_source.dart';
import 'package:strava_estudo_app/sync/sync_controller.dart';
import 'package:strava_estudo_app/sync/upload/activity_uploader.dart';
import 'package:strava_estudo_app/sync/upload/sync_service.dart';

class RecordingUploader implements ActivityUploader {
  final List<String> guids = [];
  @override
  Future<String> upload(Uint8List fitBytes,
      {required String activityGuid, UploadMetadata? metadata}) async {
    guids.add(activityGuid);
    return 'up-$activityGuid';
  }
}

class _Source implements LocationSource {
  final _c = StreamController<LocationSample>();
  @override
  Future<bool> ensurePermission() async => true;
  @override
  Stream<LocationSample> positions() => _c.stream;
  @override
  Future<void> stop() async => _c.close();
}

Future<void> seed(RecordingRepository repo, String guid, {String? owner}) async {
  await repo.startActivity(
    guid: guid,
    type: ActivityType.run,
    startTimestampMs: 1000,
    ownerUserId: owner,
  );
  await repo.appendWaypoints(guid, [
    dom.Waypoint(
      position: const GeoPoint(latitude: 0, longitude: 0),
      cumulativeDistanceMeters: 10,
      elapsedTimeMs: 0,
      timerTimeMs: 0,
      classification: dom.WaypointClassification.accept,
      horizontalAccuracyMeters: 5,
    ),
  ]);
  await repo.finish(guid, 2000, distanceMeters: 10, timerTimeMs: 1000);
}

void main() {
  late RecordingDatabase db;
  late RecordingRepository repo;
  setUp(() {
    db = RecordingDatabase(NativeDatabase.memory());
    repo = RecordingRepository(db);
  });
  tearDown(() => db.close());

  Future<String?> ownerOf(String guid) async => (await repo.activity(guid))!.ownerUserId;

  test('gravacao guarda a conta logada como dona', () async {
    final ctrl = RecordingController(
      source: _Source(),
      repo: repo,
      now: () => 5000,
      currentUserId: () => 'ana',
    );
    addTearDown(ctrl.dispose);
    await ctrl.start(ActivityType.run, autoPauseEnabled: false);
    expect(await ownerOf(ctrl.activityGuid!), 'ana');
  });

  test('sync de B nao envia as pendentes de A e reivindica as sem dono', () async {
    await seed(repo, 'de-ana', owner: 'ana');
    await seed(repo, 'sem-dono');
    await seed(repo, 'de-bia', owner: 'bia');
    final up = RecordingUploader();
    final c = SyncController(SyncService(db, up), db, currentUserId: () async => 'bia');

    await c.syncNow();

    expect(up.guids, unorderedEquals(['sem-dono', 'de-bia']));
    expect(c.state.message, contains('2 sincronizada'));
    expect(await ownerOf('sem-dono'), 'bia');
    final ana = (await repo.activity('de-ana'))!;
    expect(ana.ownerUserId, 'ana');
    expect(ana.syncState, SyncState.pending, reason: 'espera a Ana entrar de novo');
  });

  test('quando A volta, as dela sobem', () async {
    await seed(repo, 'de-ana', owner: 'ana');
    final up = RecordingUploader();
    await SyncController(SyncService(db, up), db, currentUserId: () async => 'bia')
        .syncNow();
    expect(up.guids, isEmpty);

    await SyncController(SyncService(db, up), db, currentUserId: () async => 'ana')
        .syncNow();
    expect(up.guids, ['de-ana']);
  });

  test('gravacao em andamento sem dono nao e reivindicada', () async {
    await repo.startActivity(guid: 'rec', type: ActivityType.run, startTimestampMs: 1);
    expect(await db.claimUnownedActivities('bia'), 0);
    expect(await ownerOf('rec'), isNull);
  });
}
