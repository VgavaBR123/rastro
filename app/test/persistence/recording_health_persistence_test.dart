// Gravacao blindada (F01): batimento, lacunas e saude persistidos no Drift, e a
// migracao do schema 6 para o 7.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/persistence/recording_repository.dart';
import 'package:strava_estudo_app/recording/domain/gap_monitor.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/domain/waypoint.dart' as dom;

dom.Waypoint wp(int t, double dist, {double? acc}) => dom.Waypoint(
  position: GeoPoint(latitude: 0, longitude: t / 1e7),
  cumulativeDistanceMeters: dist,
  elapsedTimeMs: t,
  timerTimeMs: t,
  classification: dom.WaypointClassification.accept,
  horizontalAccuracyMeters: acc,
);

void main() {
  group('repositorio', () {
    late RecordingDatabase db;
    late RecordingRepository repo;

    setUp(() async {
      db = RecordingDatabase(NativeDatabase.memory());
      repo = RecordingRepository(db);
      await repo.startActivity(
        guid: 'a1',
        type: ActivityType.run,
        startTimestampMs: 1000,
        startBatteryLevel: 90,
      );
    });
    tearDown(() async => db.close());

    test('batimento grava instante, pausa e descartes no cabecalho', () async {
      await repo.heartbeat(
        'a1',
        nowMs: 6000,
        paused: false,
        discardedPoints: 2,
      );
      var a = (await repo.activity('a1'))!;
      expect(a.lastHeartbeatMs, 6000);
      expect(a.heartbeatPaused, isFalse);
      expect(a.discardedPointCount, 2);

      await repo.heartbeat('a1', nowMs: 9000, paused: true, discardedPoints: 3);
      a = (await repo.activity('a1'))!;
      expect(a.lastHeartbeatMs, 9000);
      expect(a.heartbeatPaused, isTrue);
      expect(a.discardedPointCount, 3);
    });

    test('lacunas sao gravadas e lidas em ordem', () async {
      await repo.recordGap(
        'a1',
        const RecordingGap(
          startMs: 50000,
          endMs: 90000,
          reason: GapReason.noGpsSignal,
        ),
      );
      await repo.recordGap(
        'a1',
        const RecordingGap(
          startMs: 10000,
          endMs: 45000,
          reason: GapReason.processStopped,
        ),
      );
      final gaps = await repo.gaps('a1');
      expect(gaps, const [
        RecordingGap(
          startMs: 10000,
          endMs: 45000,
          reason: GapReason.processStopped,
        ),
        RecordingGap(
          startMs: 50000,
          endMs: 90000,
          reason: GapReason.noGpsSignal,
        ),
      ]);
    });

    test('saude junta lacunas, precisao, descartes e bateria', () async {
      await repo.appendWaypoints('a1', [
        wp(0, 0, acc: 4),
        wp(1000, 10, acc: 8),
      ]);
      await repo.recordGap(
        'a1',
        const RecordingGap(
          startMs: 0,
          endMs: 40000,
          reason: GapReason.noGpsSignal,
        ),
      );
      await repo.heartbeat(
        'a1',
        nowMs: 5000,
        paused: false,
        discardedPoints: 4,
      );
      await repo.finish(
        'a1',
        99000,
        endBattery: 85,
        distanceMeters: 10,
        timerTimeMs: 1000,
      );

      final h = (await repo.health('a1'))!;
      expect(h.gapCount, 1);
      expect(h.gapTotalMs, 40000);
      expect(h.avgHorizontalAccuracyMeters, 6);
      expect(h.discardedPoints, 4);
      expect(h.batteryUsedPercent, 5);
      expect(h.monitored, isTrue);
    });

    test('atividade sem batimento (anterior a F01): nao monitorada', () async {
      final h = (await repo.health('a1'))!;
      expect(h.monitored, isFalse);
    });

    test('saude de atividade inexistente e null', () async {
      expect(await repo.health('nada'), isNull);
    });

    test('apagar a atividade leva as lacunas junto', () async {
      await repo.recordGap(
        'a1',
        const RecordingGap(
          startMs: 0,
          endMs: 40000,
          reason: GapReason.noGpsSignal,
        ),
      );
      await repo.deleteActivity('a1', nowMs: 1);
      expect(await db.select(db.recordingGaps).get(), isEmpty);
    });

    test(
      'checklist de confiabilidade: comeca nao visto e fica salvo',
      () async {
        expect((await db.loadSettings()).reliabilityChecklistSeen, isFalse);
        await db.saveSettings(reliabilityChecklistSeen: true);
        expect((await db.loadSettings()).reliabilityChecklistSeen, isTrue);
      },
    );
  });

  test('migracao 6 -> 7 cria lacunas e colunas novas sem perder dados', () async {
    final dir = Directory.systemTemp.createTempSync('rastro_mig');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/rec.sqlite');

    // Banco atual com uma atividade e configuracoes.
    var db = RecordingDatabase(NativeDatabase(file));
    final repo = RecordingRepository(db);
    await repo.startActivity(
      guid: 'old',
      type: ActivityType.walk,
      startTimestampMs: 5,
    );
    await db.saveSettings(useMetric: false);
    await db.close();

    // Volta o arquivo para o schema 6: sem a tabela e as colunas da F01.
    db = RecordingDatabase(
      NativeDatabase(
        file,
        setup: (raw) {
          final v = raw.select('PRAGMA user_version').first.values.first;
          if (v != 9) return;
          // F02 e F03 vieram depois: o schema 6 tambem nao tem o que e deles.
          raw.execute('DROP TABLE privacy_zones');
          raw.execute('DROP TABLE dismissed_zone_suggestions');
          raw.execute('ALTER TABLE activities DROP COLUMN hide_edges_meters');
          raw.execute('ALTER TABLE settings_rows DROP COLUMN hide_on_server');
          raw.execute('ALTER TABLE settings_rows DROP COLUMN narrator_prefs');
          raw.execute('DROP TABLE recording_gaps');
          raw.execute('ALTER TABLE activities DROP COLUMN last_heartbeat_ms');
          raw.execute('ALTER TABLE activities DROP COLUMN heartbeat_paused');
          raw.execute(
            'ALTER TABLE activities DROP COLUMN discarded_point_count',
          );
          raw.execute(
            'ALTER TABLE settings_rows DROP COLUMN reliability_checklist_seen',
          );
          raw.execute('PRAGMA user_version = 6');
        },
      ),
    );
    addTearDown(db.close);

    final old = (await RecordingRepository(db).activity('old'))!;
    expect(old.activityType, ActivityType.walk);
    expect(old.lastHeartbeatMs, isNull);
    expect(old.heartbeatPaused, isFalse);
    expect(old.discardedPointCount, 0);
    final settings = await db.loadSettings();
    expect(settings.useMetric, isFalse);
    expect(settings.reliabilityChecklistSeen, isFalse);
    await RecordingRepository(db).recordGap(
      'old',
      const RecordingGap(
        startMs: 1,
        endMs: 40000,
        reason: GapReason.processStopped,
      ),
    );
    expect(await RecordingRepository(db).gaps('old'), hasLength(1));
  });
}
