// Rastro Seguro (F08) no banco: registro das sessoes criadas NESTE aparelho
// (para a recuperacao so encerrar o que e daqui), arrived pendente que
// sobrevive ao app fechado, e a migracao 13 -> 14 sobre arquivo real.
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/safety/safety_local_store.dart';

void main() {
  group('registro local', () {
    late RecordingDatabase db;
    late SafetyLocalStore store;
    setUp(() {
      db = RecordingDatabase(NativeDatabase.memory());
      store = SafetyLocalStore(db);
    });
    tearDown(() => db.close());

    test('sessao criada aqui fica registrada; arrived pendente; removida no fim', () async {
      await store.created(sessionId: 'ss_1', activityGuid: 'act_1', ownerUserId: 'u1', nowMs: 10);
      expect(await store.isLocal('ss_1'), isTrue);
      expect(await store.isLocal('ss_outro'), isFalse);
      expect(await store.pendingArrivals(), isEmpty);
      await store.markPendingArrival('ss_1');
      final p = (await store.pendingArrivals()).single;
      expect(p.sessionId, 'ss_1');
      expect(p.ownerUserId, 'u1');
      await store.ended('ss_1');
      expect(await store.isLocal('ss_1'), isFalse);
      expect(await store.pendingArrivals(), isEmpty);
    });

    test('cursor dos alertas ja notificados', () async {
      expect(await store.alertsSeenMs(), 0);
      await store.setAlertsSeenMs(500);
      expect(await store.alertsSeenMs(), 500);
    });

    test('pendentes de uma conta so', () async {
      await store.created(sessionId: 'a', activityGuid: 'g1', ownerUserId: 'u1', nowMs: 1);
      await store.created(sessionId: 'b', activityGuid: 'g2', ownerUserId: 'u2', nowMs: 2);
      await store.markPendingArrival('a');
      await store.markPendingArrival('b');
      expect([for (final p in await store.pendingArrivals(ownerUserId: 'u2')) p.sessionId], ['b']);
    });
  });

  test('migracao 13 -> 14 cria o registro sem perder dados', () async {
    final dir = Directory.systemTemp.createTempSync('rastro_mig14');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/rec.sqlite');

    var fileDb = RecordingDatabase(NativeDatabase(file));
    await fileDb.upsertActivity(
      ActivitiesCompanion.insert(
        guid: 'old',
        activityType: ActivityType.run,
        startTimestampMs: 1000,
        isFinished: const Value(true),
        syncState: SyncState.pending,
        title: const Value('Corrida antiga'),
      ),
    );
    await fileDb.close();

    fileDb = RecordingDatabase(
      NativeDatabase(
        file,
        setup: (raw) {
          final v = raw.select('PRAGMA user_version').first.values.first;
          if (v != 14) return;
          raw.execute('DROP TABLE safety_local_sessions');
          raw.execute('DROP TABLE safety_meta');
          raw.execute('PRAGMA user_version = 13');
        },
      ),
    );
    addTearDown(fileDb.close);
    final rows = await fileDb.finishedActivitiesAscending();
    expect(rows.single.title, 'Corrida antiga');
    final store = SafetyLocalStore(fileDb);
    await store.created(sessionId: 'ss_9', activityGuid: 'old', ownerUserId: null, nowMs: 5);
    expect(await store.isLocal('ss_9'), isTrue);
  });
}
