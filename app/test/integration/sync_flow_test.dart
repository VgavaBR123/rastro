// Integracao do caminho de sincronizacao: atividade persistida -> SyncService
// -> FIT construido dos pontos reais -> uploader. Fecha o shift-left do sync.
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/persistence/recording_repository.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/domain/waypoint.dart' as dom;
import 'package:strava_estudo_app/sync/upload/activity_uploader.dart';
import 'package:strava_estudo_app/sync/upload/sync_service.dart';

class CapturingUploader implements ActivityUploader {
  Uint8List? lastBytes;
  String? lastGuid;
  UploadMetadata? lastMetadata;
  @override
  Future<String> upload(Uint8List fitBytes,
      {required String activityGuid, UploadMetadata? metadata}) async {
    lastBytes = fitBytes;
    lastGuid = activityGuid;
    lastMetadata = metadata;
    return 'upload-$activityGuid';
  }
}

dom.Waypoint acc(double lat, double dist, int t) => dom.Waypoint(
      position: GeoPoint(latitude: lat, longitude: 0, altitudeMeters: 100),
      cumulativeDistanceMeters: dist,
      elapsedTimeMs: t,
      timerTimeMs: t,
      classification: dom.WaypointClassification.accept,
      horizontalAccuracyMeters: 5,
    );

void main() {
  test('atividade persistida sincroniza e gera FIT valido', () async {
    final db = RecordingDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = RecordingRepository(db);

    await repo.startActivity(
        guid: 'x', type: ActivityType.run, startTimestampMs: 1000);
    await repo.appendWaypoints('x', [acc(0.0, 0, 0), acc(0.001, 11, 1000)]);
    await repo.finish('x', 61000, distanceMeters: 11, timerTimeMs: 60000);

    final uploader = CapturingUploader();
    final service = SyncService(db, uploader);

    final count = await service.processPending();
    expect(count, 1);
    expect(uploader.lastGuid, 'x');
    // Metadados que o FIT minimo nao carrega vao junto (headers x-*).
    final m = uploader.lastMetadata!;
    expect(m.activityType, 'run');
    expect(m.startTimeMs, 1000);
    expect(m.timerTimeMs, 60000);
    expect(m.distanceMeters, 11);

    // Header FIT: bytes 8..11 == ".FIT".
    final b = uploader.lastBytes!;
    expect(b.length, greaterThan(14));
    expect(String.fromCharCodes(b.sublist(8, 12)), '.FIT');

    // Estado final sincronizado.
    final header = await (db.select(db.activities)
          ..where((t) => t.guid.equals('x')))
        .getSingle();
    expect(header.syncState, SyncState.synced);
    expect(header.remoteId, 'upload-x', reason: 'id do servidor guardado');
  });
}
