// Testes do SyncService com banco em memoria (shift-left) e um uploader falso.
// Cobre o fluxo da fila: sucesso -> synced, falha -> failed (sem abortar lote),
// e sanidade do FIT gerado.
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/sync/upload/activity_uploader.dart';
import 'package:strava_estudo_app/sync/upload/fit_activity_builder.dart';
import 'package:strava_estudo_app/sync/upload/sync_service.dart';

/// Uploader falso: grava os guids enviados e o ultimo FIT recebido. Com
/// `shouldFail=true` lanca UploadException para simular falha de transporte.
class FakeUploader implements ActivityUploader {
  final bool shouldFail;
  final List<String> uploadedGuids = <String>[];
  Uint8List? lastFitBytes;

  FakeUploader({this.shouldFail = false});

  @override
  Future<String> upload(Uint8List fitBytes, {required String activityGuid}) async {
    if (shouldFail) {
      throw UploadException('falha simulada');
    }
    uploadedGuids.add(activityGuid);
    lastFitBytes = fitBytes;
    return 'upload-$activityGuid';
  }
}

/// Semeia uma atividade finalizada e pendente com alguns waypoints aceitos.
Future<void> seedPendingActivity(RecordingDatabase db, String guid) async {
  await db.into(db.activities).insert(
        ActivitiesCompanion.insert(
          guid: guid,
          activityType: ActivityType.run,
          startTimestampMs: 1000000,
          endTimestampMs: const Value(1000000 + 3000),
          isFinished: const Value(true),
          syncState: SyncState.pending,
        ),
      );

  await db.batch((b) {
    b.insertAll(db.waypoints, <WaypointsCompanion>[
      WaypointsCompanion.insert(
        activityGuid: guid,
        seq: 0,
        latitude: -23.5,
        longitude: -46.6,
        altitudeMeters: const Value(800),
        speedMetersPerSecond: const Value(2.5),
        elapsedTimeMs: 0,
        timerTimeMs: 0,
        cumulativeDistanceMeters: 0,
        classification: 0,
      ),
      WaypointsCompanion.insert(
        activityGuid: guid,
        seq: 1,
        latitude: -23.5001,
        longitude: -46.6001,
        altitudeMeters: const Value(802),
        speedMetersPerSecond: const Value(2.7),
        elapsedTimeMs: 3000,
        timerTimeMs: 3000,
        cumulativeDistanceMeters: 11,
        classification: 0,
      ),
    ]);
  });
}

void main() {
  late RecordingDatabase db;

  setUp(() {
    db = RecordingDatabase(NativeDatabase.memory());
  });

  tearDown(() async => db.close());

  test('sucesso: processPending retorna 1, uploader recebe o guid, header synced',
      () async {
    await seedPendingActivity(db, 'a1');
    final FakeUploader uploader = FakeUploader();
    final SyncService service = SyncService(db, uploader);

    final int synced = await service.processPending();

    expect(synced, 1);
    expect(uploader.uploadedGuids, <String>['a1']);

    final Activity header =
        await (db.select(db.activities)..where((t) => t.guid.equals('a1')))
            .getSingle();
    expect(header.syncState, SyncState.synced);
  });

  test('falha: header fica failed e processPending retorna 0', () async {
    await seedPendingActivity(db, 'a1');
    final FakeUploader uploader = FakeUploader(shouldFail: true);
    final SyncService service = SyncService(db, uploader);

    final int synced = await service.processPending();

    expect(synced, 0);
    expect(uploader.uploadedGuids, isEmpty);

    final Activity header =
        await (db.select(db.activities)..where((t) => t.guid.equals('a1')))
            .getSingle();
    expect(header.syncState, SyncState.failed);
  });

  test('FIT gerado nao e vazio', () async {
    await seedPendingActivity(db, 'a1');
    final Activity header =
        await (db.select(db.activities)..where((t) => t.guid.equals('a1')))
            .getSingle();

    final Uint8List fit = await buildActivityFit(db, header);

    expect(fit.length, greaterThan(14));
  });

  test('prepareRound devolve failed e uploading para pending, e so eles',
      () async {
    for (final g in ['p', 'u', 'f', 's']) {
      await seedPendingActivity(db, g);
    }
    await db.setSyncState('u', SyncState.uploading);
    await db.setSyncState('f', SyncState.failed);
    await db.setSyncState('s', SyncState.synced);
    // Gravacao em andamento (nao finalizada) nunca entra na fila.
    await db.into(db.activities).insert(ActivitiesCompanion.insert(
          guid: 'rec',
          activityType: ActivityType.run,
          startTimestampMs: 1,
          syncState: SyncState.uploading,
        ));

    await SyncService(db, FakeUploader()).prepareRound('u1');

    final byGuid = {
      for (final a in await db.select(db.activities).get()) a.guid: a.syncState,
    };
    expect(byGuid, {
      'p': SyncState.pending,
      'u': SyncState.pending,
      'f': SyncState.pending,
      's': SyncState.synced,
      'rec': SyncState.uploading,
    });
  });
}
