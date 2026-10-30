// Gravacao blindada (F01) no RecordingController: heartbeat persistido,
// lacunas de GPS e de processo, aviso na UI e na notificacao, e a lacuna da
// recuperacao apos crash. Relogio e batimentos controlados pelo teste.
import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/persistence/recording_repository.dart';
import 'package:strava_estudo_app/recording/domain/gap_monitor.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/location_sample.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/presentation/recording_controller.dart';

import '../fakes.dart';

/// Repositorio que falha nas escritas de batimento (banco fechado, disco
/// cheio) ou segura as de "gravando" ate o teste liberar.
class TroubledRepository extends RecordingRepository {
  TroubledRepository(super.db);

  bool failHeartbeat = false;
  Completer<void>? holdRunningBeat;

  @override
  Future<void> heartbeat(
    String guid, {
    required int nowMs,
    required bool paused,
    required int discardedPoints,
  }) async {
    if (failHeartbeat) throw StateError('disco cheio');
    final hold = holdRunningBeat;
    if (!paused && hold != null) await hold.future;
    return super.heartbeat(
      guid,
      nowMs: nowMs,
      paused: paused,
      discardedPoints: discardedPoints,
    );
  }
}

LocationSample sample(int i, {double acc = 5}) => LocationSample(
  position: GeoPoint(latitude: 0, longitude: 0.0001 * i, altitudeMeters: 100),
  wallClockMs: 1000 * i,
  monotonicMs: 1000 * i,
  horizontalAccuracyMeters: acc,
  verticalAccuracyMeters: 3,
  speedMetersPerSecond: 11,
);

void main() {
  late RecordingDatabase db;
  late RecordingRepository repo;
  late FakeLocationSource source;
  late FakeRecordingService service;
  late FakeHeartbeatTicker ticker;
  late RecordingController ctrl;
  var now = 0;

  setUp(() {
    now = 100000;
    db = RecordingDatabase(NativeDatabase.memory());
    repo = RecordingRepository(db);
    source = FakeLocationSource();
    service = FakeRecordingService();
    ticker = FakeHeartbeatTicker();
    ctrl = RecordingController(
      source: source,
      repo: repo,
      service: service,
      heartbeat: ticker,
      now: () => now,
    );
  });

  tearDown(() async {
    ctrl.dispose();
    await db.close();
  });

  Future<void> settle() => pumpEventQueue(times: 30);

  Future<Activity> head() async => (await repo.activity(ctrl.activityGuid!))!;

  test('batimento a cada ~5 s gravado no banco', () async {
    await ctrl.start(ActivityType.ride, autoPauseEnabled: false);
    expect(ticker.intervals, [kHeartbeatInterval]);
    expect((await head()).lastHeartbeatMs, now);

    now += 5000;
    ticker.tick();
    await settle();
    expect((await head()).lastHeartbeatMs, now);
    expect((await head()).heartbeatPaused, isFalse);
    await ctrl.stop();
    expect(ticker.hasListener, isFalse);
  });

  test('pausado nao grava batimento periodico; a pausa fica marcada', () async {
    await ctrl.start(ActivityType.ride, autoPauseEnabled: false);
    now += 1000;
    ctrl.pause();
    await settle();
    final pausedAt = now;
    expect((await head()).heartbeatPaused, isTrue);
    expect((await head()).lastHeartbeatMs, pausedAt);

    now += 60000;
    ticker.tick();
    await settle();
    expect((await head()).lastHeartbeatMs, pausedAt);
    expect(await repo.gaps(ctrl.activityGuid!), isEmpty);

    ctrl.resume();
    await settle();
    expect((await head()).heartbeatPaused, isFalse);
    await ctrl.stop();
  });

  test(
    'sem GPS por mais de 30 s: lacuna ao voltar o sinal, banner e notificacao',
    () async {
      await ctrl.start(ActivityType.ride, autoPauseEnabled: false);
      source.add(sample(0));
      await settle();

      for (var i = 0; i < 8; i++) {
        now += 5000;
        ticker.tick();
        await settle();
      }
      // 40 s sem ponto: o GPS esta mudo.
      expect(ctrl.state.gpsSignalLost, isTrue);
      expect(await repo.gaps(ctrl.activityGuid!), isEmpty);

      now += 2000;
      source.add(sample(1));
      await settle();
      expect(ctrl.state.gpsSignalLost, isFalse);
      final gaps = await repo.gaps(ctrl.activityGuid!);
      expect(gaps, hasLength(1));
      expect(gaps.single.reason, GapReason.noGpsSignal);
      expect(gaps.single.durationMs, 42000);
      expect(ctrl.state.gapNotice, gaps.single);
      expect(service.updates.last.text, contains('Lacuna de 42 s'));

      ctrl.dismissGapNotice();
      expect(ctrl.state.gapNotice, isNull);
      await settle();
      expect(service.updates.last.text, isNot(contains('Lacuna')));
      await ctrl.stop();
    },
  );

  test(
    'app congelado (sem batimento por mais de 30 s): lacuna de processo',
    () async {
      await ctrl.start(ActivityType.ride, autoPauseEnabled: false);
      now += 5000;
      ticker.tick();
      await settle();
      now += 90000;
      ticker.tick();
      await settle();
      final gaps = await repo.gaps(ctrl.activityGuid!);
      expect(gaps.single.reason, GapReason.processStopped);
      expect(gaps.single.durationMs, 90000);
      expect(ctrl.state.gapNotice?.reason, GapReason.processStopped);
      await ctrl.stop();
    },
  );

  test('pontos descartados pelo filtro sao contados e salvos no fim', () async {
    await ctrl.start(ActivityType.ride, autoPauseEnabled: false);
    source.add(sample(0));
    source.add(sample(1, acc: 300)); // precisao ruim: descartado
    source.add(sample(2));
    await settle();
    await ctrl.stop();
    final h = (await repo.health(ctrl.activityGuid!))!;
    expect(h.discardedPoints, 1);
    expect(h.avgHorizontalAccuracyMeters, 5);
  });

  test(
    'retomada apos crash: lacuna desde o ultimo batimento e aviso',
    () async {
      // Gravacao anterior que morreu com o ultimo batimento em t=100000.
      await repo.startActivity(
        guid: 'x',
        type: ActivityType.ride,
        startTimestampMs: 90000,
      );
      await repo.heartbeat(
        'x',
        nowMs: 100000,
        paused: false,
        discardedPoints: 2,
      );
      final interrupted = (await repo.interrupted()).single;

      now = 160000;
      await ctrl.resumeInterrupted(interrupted);
      await settle();

      final gaps = await repo.gaps('x');
      expect(gaps, const [
        RecordingGap(
          startMs: 100000,
          endMs: 160000,
          reason: GapReason.processStopped,
        ),
      ]);
      expect(ctrl.state.gapNotice, gaps.single);
      expect(service.started.single.text, contains('Lacuna de 1 min'));
      // Os descartes continuam da contagem salva.
      expect((await repo.activity('x'))!.discardedPointCount, 2);
      await ctrl.stop();
    },
  );

  test('retomada de gravacao que morreu pausada: sem lacuna', () async {
    await repo.startActivity(
      guid: 'y',
      type: ActivityType.ride,
      startTimestampMs: 90000,
    );
    await repo.heartbeat('y', nowMs: 100000, paused: true, discardedPoints: 0);
    final interrupted = (await repo.interrupted()).single;
    now = 500000;
    await ctrl.resumeInterrupted(interrupted);
    await settle();
    expect(await repo.gaps('y'), isEmpty);
    expect(ctrl.state.gapNotice, isNull);
    await ctrl.stop();
  });

  test('GPS mudo ate o fim: encerrar registra a lacuna aberta', () async {
    await ctrl.start(ActivityType.ride, autoPauseEnabled: false);
    source.add(sample(0));
    await settle();
    final lastPoint = now;
    for (var i = 0; i < 60; i++) {
      now += 5000;
      ticker.tick();
      await settle();
    }
    expect(ctrl.state.gpsSignalLost, isTrue);
    await ctrl.stop();
    expect(await repo.gaps(ctrl.activityGuid!), [
      RecordingGap(
        startMs: lastPoint,
        endMs: now,
        reason: GapReason.noGpsSignal,
      ),
    ]);
    expect((await repo.health(ctrl.activityGuid!))!.gapCount, 1);
  });

  test('pausar com o GPS mudo fecha a lacuna ate a pausa', () async {
    await ctrl.start(ActivityType.ride, autoPauseEnabled: false);
    source.add(sample(0));
    await settle();
    final lastPoint = now;
    for (var i = 0; i < 8; i++) {
      now += 5000;
      ticker.tick();
      await settle();
    }
    final pausedAt = now;
    ctrl.pause();
    await settle();
    expect(ctrl.state.gpsSignalLost, isFalse);
    // Tempo pausado nao conta; encerrar pausado nao duplica a lacuna.
    now += 600000;
    await ctrl.stop();
    expect(await repo.gaps(ctrl.activityGuid!), [
      RecordingGap(
        startMs: lastPoint,
        endMs: pausedAt,
        reason: GapReason.noGpsSignal,
      ),
    ]);
  });

  group('escritas que falham', () {
    late TroubledRepository troubled;
    late RecordingController c;

    setUp(() {
      troubled = TroubledRepository(db);
      c = RecordingController(
        source: source,
        repo: troubled,
        service: service,
        heartbeat: ticker,
        now: () => now,
      );
    });
    tearDown(() => c.dispose());

    test('falha do banco no batimento vai para o state.error', () async {
      await c.start(ActivityType.ride, autoPauseEnabled: false);
      troubled.failHeartbeat = true;
      now += 5000;
      ticker.tick(); // _onTick
      await settle();
      expect(c.state.error, contains('disco cheio'));
      c.pause(); // _syncPause
      await settle();
      source.add(sample(1)); // _onSample
      await settle();
      expect(c.state.error, contains('disco cheio'));
    });

    test('batimento atrasado nao sobrescreve o batimento final', () async {
      await c.start(ActivityType.ride, autoPauseEnabled: false);
      troubled.holdRunningBeat = Completer<void>();
      now += 5000;
      ticker.tick(); // batimento "gravando" fica preso no banco
      await settle();
      final stopping = c.stop();
      await settle();
      troubled.holdRunningBeat!.complete();
      await stopping;
      await settle();
      final a = (await troubled.activity(c.activityGuid!))!;
      expect(a.heartbeatPaused, isTrue);
      expect(a.isFinished, isTrue);
    });
  });
}
