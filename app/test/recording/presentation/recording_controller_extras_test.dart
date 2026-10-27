// RecordingController com as bordas novas: voltas, notificacao (servico fake),
// acelerometro, bateria e calorias.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/persistence/recording_repository.dart';
import 'package:strava_estudo_app/recording/domain/auto_pause.dart';
import 'package:strava_estudo_app/recording/domain/calories.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/motion_auto_pause.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/domain/waypoint.dart' as dom;
import 'package:strava_estudo_app/recording/presentation/recording_controller.dart';
import 'package:strava_estudo_app/recording/service/recording_service.dart';

import '../../fixtures/sample_route.dart';
import '../fakes.dart';

void main() {
  late RecordingDatabase db;
  late RecordingRepository repo;
  late FakeLocationSource source;
  late FakeRecordingService service;
  late FakeAccelerometerSource accel;
  late FakeBatteryLevelSource battery;
  late RecordingController ctrl;
  SpyMotionDetector? spy;

  RecordingController build({double? weight, bool metric = true}) =>
      RecordingController(
        source: source,
        repo: repo,
        service: service,
        accelerometer: accel,
        battery: battery,
        now: () => 1000,
        weightKg: () => weight,
        useMetric: () => metric,
        autoPauseFactory: (type) {
          if (type != ActivityType.run) return SpeedAutoPauseDetector();
          return spy = SpyMotionDetector();
        },
      );

  setUp(() {
    db = RecordingDatabase(NativeDatabase.memory());
    repo = RecordingRepository(db);
    source = FakeLocationSource();
    service = FakeRecordingService();
    accel = FakeAccelerometerSource();
    battery = FakeBatteryLevelSource([87, 74]);
    spy = null;
    ctrl = build(weight: 70);
  });

  tearDown(() async {
    ctrl.dispose();
    await db.close();
  });

  Future<void> feed(Iterable<int> idx) async {
    final r = sampleRoute();
    for (final i in idx) {
      source.add(r[i]);
    }
    await pumpEventQueue(times: 30);
  }

  group('voltas', () {
    test('lap fecha a volta, persiste e a numeracao segue', () async {
      await ctrl.start(ActivityType.ride, autoPauseEnabled: false);
      await feed([0, 1, 2, 3]);
      final lap1 = (await ctrl.lap())!;
      expect(lap1.number, 1);
      expect(ctrl.state.currentLap.number, 2);
      expect(ctrl.state.completedLaps, 1);

      await feed([4, 6, 7]);
      final lap2 = (await ctrl.lap())!;
      expect(lap2.number, 2);
      expect(lap2.startDistanceMeters, lap1.endDistanceMeters);

      final saved = await repo.laps(ctrl.activityGuid!);
      expect(saved.map((l) => l.number), [1, 2]);
      expect(saved[0].endDistanceMeters, closeTo(lap1.endDistanceMeters, 1e-9));
      expect(saved[1].startTimerMs, lap1.endTimerMs);
      expect(saved[1].endTimerMs, lap2.endTimerMs);
      await ctrl.stop();
    });

    test('sem gravacao ativa lap nao faz nada', () async {
      expect(await ctrl.lap(), isNull);
    });

    test(
      'retomada apos crash continua a numeracao das voltas salvas',
      () async {
        final start = DateTime.now()
            .subtract(const Duration(minutes: 5))
            .millisecondsSinceEpoch;
        await repo.startActivity(
          guid: 'x',
          type: ActivityType.ride,
          startTimestampMs: start,
        );
        dom.Waypoint wp(double lon, double d, int t) => dom.Waypoint(
          position: GeoPoint(latitude: 0, longitude: lon),
          cumulativeDistanceMeters: d,
          elapsedTimeMs: t,
          timerTimeMs: t,
          classification: dom.WaypointClassification.accept,
          horizontalAccuracyMeters: 5,
        );
        await repo.appendWaypoints('x', [wp(0, 0, 0), wp(0.001, 111, 60000)]);
        await repo.saveLap(
          'x',
          number: 1,
          startTimerMs: 0,
          endTimerMs: 30000,
          endElapsedMs: 30000,
          startDistanceMeters: 0,
          endDistanceMeters: 50,
        );
        final interrupted = (await repo.interrupted()).single;

        final c = RecordingController(
          source: source,
          repo: repo,
          service: service,
          now: () => DateTime.now().millisecondsSinceEpoch,
        );
        addTearDown(c.dispose);
        await c.resumeInterrupted(interrupted);
        expect(c.state.currentLap.number, 2);
        expect(c.state.completedLaps, 1);
        final lap = (await c.lap())!;
        expect(lap.number, 2);
        expect(lap.startDistanceMeters, 50);
        expect(lap.endDistanceMeters, 111);
        expect((await repo.laps('x')).map((l) => l.number), [1, 2]);
        // A retomada tambem sobe o servico da notificacao.
        expect(service.started, isNotEmpty);
        await c.stop();
      },
    );
  });

  group('notificacao (servico fake)', () {
    test('sobe o servico no inicio e derruba no fim', () async {
      await ctrl.start(ActivityType.ride, autoPauseEnabled: false);
      expect(service.started, hasLength(1));
      expect(service.started.single.title, 'Pedal em andamento');
      expect(service.started.single.paused, isFalse);
      await ctrl.stop();
      expect(service.stops, 1);
    });

    test('botoes da notificacao chegam ao controller', () async {
      await ctrl.start(ActivityType.ride, autoPauseEnabled: false);
      await feed([0, 1, 2]);

      service.press(RecordingCommand.pause);
      await pumpEventQueue();
      expect(ctrl.state.state, RecordingState.manuallyPaused);
      expect(service.updates.last.paused, isTrue);
      expect(service.updates.last.title, 'Pedal pausada');

      service.press(RecordingCommand.resume);
      await pumpEventQueue();
      expect(ctrl.state.state, RecordingState.recording);
      expect(service.updates.last.paused, isFalse);

      service.press(RecordingCommand.lap);
      await pumpEventQueue(times: 20);
      expect(ctrl.state.completedLaps, 1);
      expect(await repo.laps(ctrl.activityGuid!), hasLength(1));

      final guid = ctrl.activityGuid!;
      service.press(RecordingCommand.stop);
      await pumpEventQueue(times: 30);
      expect(ctrl.state.state, RecordingState.finished);
      expect(service.stops, 1);
      expect((await repo.activity(guid))!.isFinished, isTrue);
    });

    test(
      'texto com distancia e tempo, atualizado no maximo a cada 3 s',
      () async {
        await ctrl.start(ActivityType.ride, autoPauseEnabled: false);
        // Amostras a cada 1 s (0..10 s): atualiza em 0, 3, 6 e 9 s.
        await feed(List.generate(11, (i) => i));
        expect(service.updates, hasLength(4));
        final last = service.updates.last;
        expect(last.text, contains('m'));
        expect(last.text, contains('0:09'));
        await ctrl.stop();
      },
    );

    test('unidade imperial no texto', () async {
      ctrl.dispose();
      ctrl = build(metric: false);
      await ctrl.start(ActivityType.ride, autoPauseEnabled: false);
      await feed([0, 1]);
      expect(service.updates.last.text, contains('mi'));
      await ctrl.stop();
    });
  });

  group('acelerometro', () {
    test(
      'corrida com pausa por movimento repassa as amostras a sessao',
      () async {
        await ctrl.start(ActivityType.run, autoPauseEnabled: true);
        expect(accel.listens, 1);
        accel.add(const AccelSample(100, 0.1, 0.2, 9.7));
        accel.add(const AccelSample(150, 0.3, 0.1, 9.9));
        await pumpEventQueue();
        expect(spy!.received.map((a) => a.monotonicMs), [100, 150]);

        await ctrl.stop();
        expect(accel.hasListener, isFalse); // sensor desligado no fim
      },
    );

    test('sem pausa automatica nao liga o sensor', () async {
      await ctrl.start(ActivityType.run, autoPauseEnabled: false);
      expect(accel.listens, 0);
      await ctrl.stop();
    });
  });

  group('bateria e calorias no cabecalho', () {
    test('nivel no inicio e no fim; calorias pelo peso', () async {
      await ctrl.start(ActivityType.run, autoPauseEnabled: false);
      final guid = ctrl.activityGuid!;
      expect((await repo.activity(guid))!.startBatteryLevel, 87);
      await feed(List.generate(11, (i) => i));
      await ctrl.stop();

      final a = (await repo.activity(guid))!;
      expect(a.startBatteryLevel, 87);
      expect(a.endBatteryLevel, 74);
      final expected = estimateCaloriesKcal(
        type: ActivityType.run,
        timerTimeMs: a.timerTimeMs,
        distanceMeters: a.distanceMeters,
        weightKg: 70,
      );
      expect(a.calories, expected);
      expect(a.calories, isNotNull);
    });

    test('sem peso nao grava calorias', () async {
      ctrl.dispose();
      ctrl = build(weight: null);
      await ctrl.start(ActivityType.run, autoPauseEnabled: false);
      final guid = ctrl.activityGuid!;
      await feed([0, 1, 2]);
      await ctrl.stop();
      expect((await repo.activity(guid))!.calories, isNull);
    });
  });
}
