// Voltas (laps) e repasse do acelerometro na RecordingSession.
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/recording/domain/auto_pause.dart';
import 'package:strava_estudo_app/recording/domain/motion_auto_pause.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/domain/recording_session.dart';

import '../../fixtures/sample_route.dart';
import '../fakes.dart';

void main() {
  group('RecordingSession.lap', () {
    test('fecha a volta corrente e a proxima comeca no fim dela', () {
      final route = sampleRoute();
      final s = RecordingSession(
        activityType: ActivityType.run,
        autoPauseEnabled: false,
      )..start(0);
      for (final p in route.take(4)) {
        s.addSample(p);
      }
      final d1 = s.stats.distanceMeters;
      final t1 = s.stats.timerMs;

      final lap1 = s.lap(3000)!;
      expect(lap1.number, 1);
      expect(lap1.startTimerMs, 0);
      expect(lap1.startDistanceMeters, 0);
      expect(lap1.endDistanceMeters, d1);
      expect(lap1.endTimerMs, t1);
      expect(lap1.distanceMeters, greaterThan(0));

      for (final p in route.skip(4).take(4)) {
        s.addSample(p);
      }
      final lap2 = s.lap(7000)!;
      expect(lap2.number, 2);
      expect(lap2.startDistanceMeters, lap1.endDistanceMeters);
      expect(lap2.startTimerMs, lap1.endTimerMs);
      expect(lap2.endDistanceMeters, s.stats.distanceMeters);
      expect(s.laps, hasLength(2));

      // Volta corrente aberta logo apos fechar: numero 3, sem distancia.
      expect(s.currentLap.number, 3);
      expect(s.currentLap.distanceMeters, 0);
    });

    test('instante do pedido depois da ultima amostra avanca o cronometro', () {
      final s = RecordingSession(
        activityType: ActivityType.ride,
        autoPauseEnabled: false,
      )..start(0);
      s.addSample(sampleRoute().first);
      final lap = s.lap(5000)!;
      expect(lap.endTimerMs, 5000);
      expect(lap.endElapsedMs, 5000);
    });

    test('sem sessão ativa não fecha volta', () {
      final s = RecordingSession(activityType: ActivityType.run);
      expect(s.lap(0), isNull);
      s.start(0);
      s.finish();
      expect(s.lap(10), isNull);
    });

    test('restore continua a numeracao das voltas salvas', () {
      final s = RecordingSession(
        activityType: ActivityType.run,
        autoPauseEnabled: false,
      );
      s.restore(
        const [],
        monotonicMs: 0,
        elapsedMs: 60000,
        completedLaps: const [
          LapRecord(
            number: 1,
            startTimerMs: 0,
            endTimerMs: 30000,
            endElapsedMs: 30000,
            startDistanceMeters: 0,
            endDistanceMeters: 100,
          ),
        ],
      );
      expect(s.currentLap.number, 2);
      expect(s.currentLap.startDistanceMeters, 100);
      expect(s.currentLap.startTimerMs, 30000);
      expect(s.lap(1000)!.number, 2);
    });
  });

  group('RecordingSession.addAccel', () {
    test('repassa ao detector por movimento', () {
      final spy = SpyMotionDetector();
      final s = RecordingSession(
        activityType: ActivityType.run,
        autoPauseDetector: spy,
      )..start(0);
      expect(s.usesMotionAutoPause, isTrue);
      s.addAccel(const AccelSample(10, 0, 0, 9.8));
      s.addAccel(const AccelSample(60, 1, 0, 9.8));
      expect(spy.received.map((a) => a.monotonicMs), [10, 60]);
    });

    test('com detector por velocidade não usa o acelerometro', () {
      final s = RecordingSession(
        activityType: ActivityType.ride,
        autoPauseDetector: SpeedAutoPauseDetector(),
      )..start(0);
      expect(s.usesMotionAutoPause, isFalse);
      s.addAccel(const AccelSample(10, 0, 0, 9.8)); // nao lanca
    });

    test('pausa automática desligada não liga o sensor', () {
      final s = RecordingSession(
        activityType: ActivityType.run,
        autoPauseEnabled: false,
        autoPauseDetector: SpyMotionDetector(),
      );
      expect(s.usesMotionAutoPause, isFalse);
    });
  });
}
