// Fechamento gentil (F04) no upload: RPE e humor sobem nos metadados
// (headers x-rpe e x-mood do contrato), so quando informados.
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/sync/upload/activity_uploader.dart';
import 'package:strava_estudo_app/sync/upload/dio_activity_uploader.dart';
import 'package:strava_estudo_app/sync/upload/sync_service.dart';

class CapturingUploader implements ActivityUploader {
  UploadMetadata? metadata;

  @override
  Future<String> upload(
    Uint8List fitBytes, {
    required String activityGuid,
    UploadMetadata? metadata,
  }) async {
    this.metadata = metadata;
    return 'r-$activityGuid';
  }
}

Future<void> seed(RecordingDatabase db, {int? rpe, String? mood}) =>
    db.into(db.activities).insert(
      ActivitiesCompanion.insert(
        guid: 'a',
        activityType: ActivityType.run,
        startTimestampMs: 1000000,
        isFinished: const Value(true),
        syncState: SyncState.pending,
        distanceMeters: const Value(5000),
        timerTimeMs: const Value(1800000),
        rpe: Value(rpe),
        mood: Value(mood),
      ),
    );

void main() {
  late RecordingDatabase db;
  setUp(() => db = RecordingDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('headers x-rpe e x-mood so quando presentes', () {
    final h = metadataHeaders(const UploadMetadata(rpe: 6, mood: 'tired'));
    expect(h['x-rpe'], '6');
    expect(h['x-mood'], 'tired');
    final none = metadataHeaders(const UploadMetadata(activityType: 'run'));
    expect(none.containsKey('x-rpe'), isFalse);
    expect(none.containsKey('x-mood'), isFalse);
  });

  test('SyncService envia o RPE e o humor da atividade', () async {
    await seed(db, rpe: 8, mood: 'great');
    final up = CapturingUploader();
    await SyncService(db, up).processPending();
    expect(up.metadata!.rpe, 8);
    expect(up.metadata!.mood, 'great');
  });

  test('sem RPE nem humor: metadados nulos', () async {
    await seed(db);
    final up = CapturingUploader();
    await SyncService(db, up).processPending();
    expect(up.metadata!.rpe, isNull);
    expect(up.metadata!.mood, isNull);
  });
}
