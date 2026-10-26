// Testes da logica do sync de fundo, sem o plugin: banco em memoria e
// uploader falso (mesmo padrao de test/sync/upload/sync_service_test.dart).
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/sync/background/background_sync.dart';
import 'package:strava_estudo_app/sync/upload/activity_uploader.dart';
import 'package:strava_estudo_app/sync/upload/sync_service.dart';

import '../upload/sync_service_test.dart' show FakeUploader, seedPendingActivity;

/// Banco em memoria que registra se foi fechado.
class TrackingDatabase extends RecordingDatabase {
  bool closed = false;
  TrackingDatabase() : super(NativeDatabase.memory());

  @override
  Future<void> close() async {
    closed = true;
    await super.close();
  }
}

/// Uploader que falha so para os guids indicados.
class SelectiveUploader implements ActivityUploader {
  final Set<String> failFor;
  final List<String> uploaded = <String>[];
  SelectiveUploader(this.failFor);

  @override
  Future<String> upload(Uint8List fitBytes, {required String activityGuid}) async {
    if (failFor.contains(activityGuid)) throw UploadException('falha');
    uploaded.add(activityGuid);
    return 'up-$activityGuid';
  }
}

Future<SyncState> stateOf(RecordingDatabase db, String guid) async =>
    (await (db.select(db.activities)..where((t) => t.guid.equals(guid)))
            .getSingle())
        .syncState;

void main() {
  group('isSyncBackendConfigured', () {
    test('placeholder e vazio nao contam como backend', () {
      expect(isSyncBackendConfigured('https://example.invalid'), isFalse);
      expect(isSyncBackendConfigured(''), isFalse);
      expect(isSyncBackendConfigured('http://localhost:8081'), isTrue);
    });
  });

  group('runBackgroundSync', () {
    late RecordingDatabase db;
    setUp(() => db = RecordingDatabase(NativeDatabase.memory()));
    tearDown(() async => db.close());

    test('fila vazia: true sem chamar o uploader', () async {
      final FakeUploader up = FakeUploader();
      expect(await runBackgroundSync(db, SyncService(db, up)), isTrue);
      expect(up.uploadedGuids, isEmpty);
    });

    test('tudo enviado: true e headers synced', () async {
      await seedPendingActivity(db, 'a1');
      await seedPendingActivity(db, 'a2');
      final FakeUploader up = FakeUploader();

      expect(await runBackgroundSync(db, SyncService(db, up)), isTrue);
      expect(up.uploadedGuids, unorderedEquals(<String>['a1', 'a2']));
      expect(await stateOf(db, 'a1'), SyncState.synced);
      expect(await stateOf(db, 'a2'), SyncState.synced);
    });

    test('falha parcial: false (retry) e so a que falhou fica failed',
        () async {
      await seedPendingActivity(db, 'ok');
      await seedPendingActivity(db, 'ruim');
      final SelectiveUploader up = SelectiveUploader(<String>{'ruim'});

      expect(await runBackgroundSync(db, SyncService(db, up)), isFalse);
      expect(await stateOf(db, 'ok'), SyncState.synced);
      expect(await stateOf(db, 'ruim'), SyncState.failed);
    });

    test('re-tenta atividades que falharam numa rodada anterior', () async {
      await seedPendingActivity(db, 'a1');
      await db.setSyncState('a1', SyncState.failed);
      final FakeUploader up = FakeUploader();

      expect(await runBackgroundSync(db, SyncService(db, up)), isTrue);
      expect(up.uploadedGuids, <String>['a1']);
      expect(await stateOf(db, 'a1'), SyncState.synced);
    });

    test('re-envia atividade presa em uploading (app morto no meio)', () async {
      await seedPendingActivity(db, 'a1');
      await db.setSyncState('a1', SyncState.uploading);
      final FakeUploader up = FakeUploader();

      expect(await runBackgroundSync(db, SyncService(db, up)), isTrue);
      expect(up.uploadedGuids, <String>['a1']);
      expect(await stateOf(db, 'a1'), SyncState.synced);
    });

    test('nao re-envia o que ja esta synced', () async {
      await seedPendingActivity(db, 'a1');
      await db.setSyncState('a1', SyncState.synced);
      final FakeUploader up = FakeUploader();

      expect(await runBackgroundSync(db, SyncService(db, up)), isTrue);
      expect(up.uploadedGuids, isEmpty);
    });
  });

  group('performBackgroundSync', () {
    test('sem backend configurado: true sem abrir o banco', () async {
      bool opened = false;
      final bool ok = await performBackgroundSync(
        baseUrl: kUnconfiguredSyncBaseUrl,
        openDatabase: () {
          opened = true;
          return TrackingDatabase();
        },
      );
      expect(ok, isTrue);
      expect(opened, isFalse);
    });

    test('sucesso: envia, devolve true e fecha o banco', () async {
      final TrackingDatabase db = TrackingDatabase();
      await seedPendingActivity(db, 'a1');
      final FakeUploader up = FakeUploader();
      String? usedUrl;

      final bool ok = await performBackgroundSync(
        baseUrl: 'http://localhost:8081',
        openDatabase: () => db,
        createUploader: (url) {
          usedUrl = url;
          return up;
        },
      );

      expect(ok, isTrue);
      expect(usedUrl, 'http://localhost:8081');
      expect(up.uploadedGuids, <String>['a1']);
      expect(db.closed, isTrue);
    });

    test('falha de upload: false e banco fechado', () async {
      final TrackingDatabase db = TrackingDatabase();
      await seedPendingActivity(db, 'a1');

      final bool ok = await performBackgroundSync(
        baseUrl: 'http://localhost:8081',
        openDatabase: () => db,
        createUploader: (_) => FakeUploader(shouldFail: true),
      );

      expect(ok, isFalse);
      expect(db.closed, isTrue);
    });

    test('excecao ao montar o uploader nao escapa e fecha o banco', () async {
      final TrackingDatabase db = TrackingDatabase();

      final bool ok = await performBackgroundSync(
        baseUrl: 'http://localhost:8081',
        openDatabase: () => db,
        createUploader: (_) => throw StateError('sem rede'),
      );

      expect(ok, isFalse);
      expect(db.closed, isTrue);
    });

    test('excecao ao abrir o banco nao escapa', () async {
      final bool ok = await performBackgroundSync(
        baseUrl: 'http://localhost:8081',
        openDatabase: () => throw StateError('disco cheio'),
      );
      expect(ok, isFalse);
    });
  });
}
