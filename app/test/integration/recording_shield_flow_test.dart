// Integracao da Gravacao blindada (F01): gravacao com heartbeat -> GPS some ->
// lacuna de GPS -> app "morre" -> recuperacao com lacuna de processo -> fim ->
// saude da atividade. Banco Drift em memoria, fakes nas bordas, relogio do
// teste.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/persistence/recording_repository.dart';
import 'package:strava_estudo_app/recording/domain/gap_monitor.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/location_sample.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/presentation/recording_controller.dart';

import '../recording/fakes.dart';

/// Rota reta para leste, ~11 m por segundo; [acc] 300 = ponto ruim.
LocationSample s(int i, {int base = 0, double acc = 5}) => LocationSample(
  position: GeoPoint(latitude: 0, longitude: 0.0001 * i, altitudeMeters: 100),
  wallClockMs: 1000 * (i - base),
  monotonicMs: 1000 * (i - base),
  horizontalAccuracyMeters: acc,
  verticalAccuracyMeters: 3,
  speedMetersPerSecond: 11,
);

void main() {
  test('lacunas de GPS e de processo chegam ao relatorio de saude', () async {
    final db = RecordingDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = RecordingRepository(db);
    var now = 1000000;
    Future<void> settle() => pumpEventQueue(times: 30);

    // 1) Primeira sessao: grava, perde o GPS por 40 s e recupera.
    final source1 = FakeLocationSource();
    final ticker1 = FakeHeartbeatTicker();
    final service1 = FakeRecordingService();
    final battery = FakeBatteryLevelSource([95, 88]);
    final c1 = RecordingController(
      source: source1,
      repo: repo,
      service: service1,
      heartbeat: ticker1,
      battery: battery,
      now: () => now,
    );
    await c1.start(ActivityType.ride, autoPauseEnabled: false);
    final guid = c1.activityGuid!;
    for (var i = 0; i < 5; i++) {
      now += 1000;
      source1.add(s(i, acc: i == 3 ? 300 : 5));
      await settle();
    }
    for (var k = 0; k < 8; k++) {
      now += 5000;
      ticker1.tick();
      await settle();
    }
    expect(c1.state.gpsSignalLost, isTrue);
    expect(service1.updates.last.text, contains('Sem sinal de GPS'));
    now += 1000;
    source1.add(s(5));
    await settle();
    expect(c1.state.gapNotice?.reason, GapReason.noGpsSignal);
    for (var k = 0; k < 2; k++) {
      now += 5000;
      ticker1.tick();
      await settle();
    }
    final lastBeat = (await repo.activity(guid))!.lastHeartbeatMs!;
    expect(lastBeat, now);

    // 2) O sistema mata o app: nada de stop; o controller some.
    c1.dispose();

    // 3) Dois minutos depois o app abre e retoma pela recuperacao.
    now += 120000;
    final interrupted = (await repo.interrupted()).single;
    expect(interrupted.activity.guid, guid);
    final source2 = FakeLocationSource();
    final service2 = FakeRecordingService();
    final c2 = RecordingController(
      source: source2,
      repo: repo,
      service: service2,
      heartbeat: FakeHeartbeatTicker(),
      battery: battery,
      now: () => now,
    );
    await c2.resumeInterrupted(interrupted);
    await settle();
    expect(c2.state.gapNotice?.reason, GapReason.processStopped);
    expect(c2.state.gapNotice?.durationMs, 120000);
    expect(service2.started.single.text, contains('Lacuna de 2 min'));
    for (var i = 6; i < 9; i++) {
      now += 1000;
      source2.add(s(i, base: 6));
      await settle();
    }
    await c2.stop();
    c2.dispose();

    // 4) Saude da atividade.
    final gaps = await repo.gaps(guid);
    expect(gaps.map((g) => g.reason), [
      GapReason.noGpsSignal,
      GapReason.processStopped,
    ]);
    final h = (await repo.health(guid))!;
    expect(h.gapCount, 2);
    expect(h.gapTotalMs, gaps[0].durationMs + 120000);
    expect(h.discardedPoints, 1);
    expect(h.avgHorizontalAccuracyMeters, 5);
    expect(h.batteryUsedPercent, 7);
    final a = (await repo.activity(guid))!;
    expect(a.isFinished, isTrue);
  });

  test(
    'GPS mudo nos ultimos minutos: lacuna aparece na saude ao encerrar',
    () async {
      final db = RecordingDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = RecordingRepository(db);
      var now = 2000000;
      Future<void> settle() => pumpEventQueue(times: 30);
      final source = FakeLocationSource();
      final ticker = FakeHeartbeatTicker();
      final service = FakeRecordingService();
      final c = RecordingController(
        source: source,
        repo: repo,
        service: service,
        heartbeat: ticker,
        now: () => now,
      );
      addTearDown(c.dispose);
      await c.start(ActivityType.run, autoPauseEnabled: false);
      final guid = c.activityGuid!;
      for (var i = 0; i < 5; i++) {
        now += 1000;
        source.add(s(i));
        await settle();
      }
      final lastPoint = now;
      // Tunel: 5 minutos sem nenhum ponto, o app vivo batendo.
      for (var k = 0; k < 60; k++) {
        now += 5000;
        ticker.tick();
        await settle();
      }
      expect(c.state.gpsSignalLost, isTrue);
      await c.stop();

      final h = (await repo.health(guid))!;
      expect(h.monitored, isTrue);
      expect(h.gapCount, 1);
      expect(h.gapTotalMs, now - lastPoint);
      expect((await repo.gaps(guid)).single.reason, GapReason.noGpsSignal);
    },
  );
}
