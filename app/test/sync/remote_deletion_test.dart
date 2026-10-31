// Excluir no aparelho leva a exclusao ao servidor: na hora se houver rede,
// ou depois, pela fila, se nao houver. Nada fica apagado aqui e esquecido la.
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/persistence/recording_repository.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/domain/waypoint.dart' as dom;
import 'package:strava_estudo_app/sync/sync_controller.dart';
import 'package:strava_estudo_app/sync/upload/activity_uploader.dart';
import 'package:strava_estudo_app/sync/upload/dio_activity_uploader.dart';
import 'package:strava_estudo_app/sync/upload/sync_service.dart';

import '../auth/auth_test.dart' show RouteAdapter;

/// Uploader + deleter falso; `offline` faz o delete falhar como sem rede.
class FakeServer implements ActivityUploader, RemoteActivityDeleter {
  final List<String> deleted = [];
  bool offline = false;

  @override
  Future<String> upload(Uint8List fitBytes,
          {required String activityGuid, UploadMetadata? metadata}) async =>
      'srv-$activityGuid';

  @override
  Future<void> deleteRemote(String remoteId) async {
    if (offline) throw UploadException('sem rede');
    deleted.add(remoteId);
  }
}

Future<void> seed(RecordingRepository repo, String guid, {String? owner}) async {
  await repo.startActivity(
      guid: guid, type: ActivityType.run, startTimestampMs: 1000, ownerUserId: owner);
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
  late FakeServer server;
  late SyncController ctrl;

  setUp(() {
    db = RecordingDatabase(NativeDatabase.memory());
    repo = RecordingRepository(db);
    server = FakeServer();
    ctrl = SyncController(SyncService(db, server), db, currentUserId: () async => 'ana');
  });
  tearDown(() => db.close());

  test('sync guarda o id do servidor; excluir enfileira e o sync apaga la', () async {
    await seed(repo, 'a', owner: 'ana');
    await ctrl.syncNow();
    expect((await repo.activity('a'))!.remoteId, 'srv-a');

    await repo.deleteActivity('a', nowMs: 5);
    expect(await repo.activity('a'), isNull);
    expect((await db.pendingRemoteDeletions()).single.remoteId, 'srv-a');

    await ctrl.syncNow();
    expect(server.deleted, ['srv-a']);
    expect(await db.pendingRemoteDeletions(), isEmpty);
  });

  test('sem rede a exclusao espera na fila e sai na proxima rodada', () async {
    await seed(repo, 'a', owner: 'ana');
    await ctrl.syncNow();
    await repo.deleteActivity('a', nowMs: 5);

    server.offline = true;
    await ctrl.syncNow();
    expect(await db.pendingRemoteDeletions(), hasLength(1));

    server.offline = false;
    await ctrl.syncNow();
    expect(server.deleted, ['srv-a']);
    expect(await db.pendingRemoteDeletions(), isEmpty);
  });

  test('atividade que nunca subiu não gera exclusao remota', () async {
    await seed(repo, 'local');
    await repo.deleteActivity('local', nowMs: 5);
    expect(await db.pendingRemoteDeletions(), isEmpty);
  });

  test('exclusoes de outra conta esperam o dono', () async {
    await seed(repo, 'a', owner: 'ana');
    await ctrl.syncNow();
    await repo.deleteActivity('a', nowMs: 5);

    final bia = SyncController(SyncService(db, server), db, currentUserId: () async => 'bia');
    await bia.syncNow();
    expect(server.deleted, isEmpty);
    expect(await db.pendingRemoteDeletions(), hasLength(1));
  });

  group('DioActivityUploader', () {
    DioActivityUploader with_(RouteAdapter a) => DioActivityUploader(
        Dio()..httpClientAdapter = a, 'http://srv',
        token: () async => 'tok');

    test('upload manda os metadados nos headers do contrato', () async {
      final a = RouteAdapter({'POST /uploads': (201, {'uploadId': 'up9'})});
      final id = await with_(a).upload(Uint8List.fromList([1]),
          activityGuid: 'g',
          metadata: const UploadMetadata(
            activityType: 'ride',
            startTimeMs: 1700000000000,
            timerTimeMs: 3600000,
            distanceMeters: 25000.5,
          ));
      expect(id, 'up9');
      final h = a.requests.single.headers;
      expect(h['x-activity-type'], 'ride');
      expect(h['x-start-time'], '1700000000000');
      expect(h['x-timer-time-ms'], '3600000');
      expect(h['x-distance-meters'], '25000.5');
    });

    test('delete: 204 e 404 sao sucesso; 401 vira sessão inválida', () async {
      final a = RouteAdapter({'DELETE /activities/up9': (204, null)});
      await with_(a).deleteRemote('up9');
      expect(a.requests.single.headers['Authorization'], 'Bearer tok');

      await with_(RouteAdapter({})).deleteRemote('sumiu'); // 404 padrao

      await expectLater(
        with_(RouteAdapter({'DELETE /activities/x': (401, {'error': 'x'})})).deleteRemote('x'),
        throwsA(isA<UnauthorizedUploadException>()),
      );
    });
  });
}
