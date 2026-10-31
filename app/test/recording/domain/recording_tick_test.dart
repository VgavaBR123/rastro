// GRA-01 e GRA-02 (teste no iPhone, 30/10/2026): o cronometro anda sem fix de
// GPS, o silencio do GPS vira pausa automatica (sem contar o tempo parado) e a
// corrida retoma pelo GPS quando o acelerometro diz "parado".
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/location_sample.dart';
import 'package:strava_estudo_app/recording/domain/motion_auto_pause.dart';
import 'package:strava_estudo_app/recording/domain/recording_clock.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/domain/recording_session.dart';

/// ~1 m de longitude no equador, em graus.
const double kDegPerMeter = 1 / 111319.49;

LocationSample at(
  double meters, {
  required int t,
  double? speed,
  double accuracy = 5.0,
}) => LocationSample(
  position: GeoPoint(latitude: 0, longitude: meters * kDegPerMeter),
  wallClockMs: t,
  monotonicMs: t,
  horizontalAccuracyMeters: accuracy,
  speedMetersPerSecond: speed,
);

/// Caminha a 3,5 m/s de [fromMs] ate [toMs] (1 fix por segundo), a partir de
/// [startMeters]. Devolve a posicao final.
double walk(
  RecordingSession sess, {
  required int fromMs,
  required int toMs,
  double startMeters = 0,
  double speed = 3.5,
}) {
  var m = startMeters;
  for (var t = fromMs; t <= toMs; t += 1000) {
    m = startMeters + speed * (t - fromMs) / 1000;
    sess.addSample(at(m, t: t, speed: speed));
  }
  return m;
}

void ticks(RecordingSession sess, {required int fromMs, required int toMs}) {
  for (var t = fromMs; t <= toMs; t += 1000) {
    sess.tick(t);
  }
}

void main() {
  group('RecordingClock.cancelPause', () {
    test('a pausa em curso vira tempo de cronometro', () {
      final c = RecordingClock()..start(0);
      c.tick(10000);
      c.pause(10000);
      c.tick(40000);
      expect(c.timerMs, 10000);
      c.cancelPause();
      expect(c.isPaused, isFalse);
      expect(c.timerMs, 40000);
    });
  });

  group('tick sem pausa automática', () {
    test('o cronometro anda sem nenhum fix', () {
      final sess = RecordingSession(
        activityType: ActivityType.walk,
        autoPauseEnabled: false,
      )..start(0);
      ticks(sess, fromMs: 1000, toMs: 50000);
      expect(sess.stats.timerMs, 50000);
      expect(sess.state, RecordingState.recording);
    });

    test('tick no passado não volta o relogio', () {
      final sess = RecordingSession(
        activityType: ActivityType.walk,
        autoPauseEnabled: false,
      )..start(0);
      sess.tick(5000);
      sess.tick(3000);
      expect(sess.stats.timerMs, 5000);
    });

    test('tick antes de iniciar ou depois de encerrar não faz nada', () {
      final sess = RecordingSession(
        activityType: ActivityType.walk,
        autoPauseEnabled: false,
      );
      sess.tick(5000);
      expect(sess.stats.timerMs, 0);
      sess.start(0);
      sess.tick(5000);
      sess.finish();
      sess.tick(9000);
      expect(sess.stats.timerMs, 5000);
    });
  });

  group('silencio do GPS com pausa automática', () {
    test('entre fixes o tempo corre segundo a segundo', () {
      final sess = RecordingSession(activityType: ActivityType.walk)..start(0);
      walk(sess, fromMs: 0, toMs: 10000);
      sess.tick(12000);
      expect(sess.stats.timerMs, 12000);
      expect(sess.state, RecordingState.recording);
    });

    test('parado sem fix: pausa e o tempo parado não conta', () {
      final sess = RecordingSession(activityType: ActivityType.walk)..start(0);
      final m = walk(sess, fromMs: 0, toMs: 60000);
      ticks(sess, fromMs: 61000, toMs: 60000 + kGpsSilencePauseMs - 1000);
      expect(sess.state, RecordingState.recording);
      ticks(sess, fromMs: 60000 + kGpsSilencePauseMs, toMs: 155000);
      expect(sess.state, RecordingState.autoPaused);
      // A pausa vale desde o ultimo fix: os ~95 s sem sinal nao entram.
      expect(sess.stats.timerMs, 60000);

      // Volta o fix no mesmo lugar, parado: segue em pausa.
      sess.addSample(at(m, t: 156000, speed: 0));
      sess.addSample(at(m, t: 157000, speed: 0));
      expect(sess.state, RecordingState.autoPaused);
      expect(sess.stats.timerMs, 60000);

      // Volta a andar: retoma dali, sem somar o tempo parado.
      walk(sess, fromMs: 158000, toMs: 168000, startMeters: m);
      expect(sess.state, RecordingState.recording);
      expect(sess.stats.timerMs, inInclusiveRange(69000, 71000));
      final pace = sess.stats.avgPaceSecondsPerMeter!;
      expect(pace, closeTo(1 / 3.5, 0.03));
    });

    test(
      'tunel: sem fix andando, o trecho conta inteiro ao voltar o sinal',
      () {
        final sess = RecordingSession(activityType: ActivityType.walk)
          ..start(0);
        final m = walk(sess, fromMs: 0, toMs: 60000);
        ticks(sess, fromMs: 61000, toMs: 90000);
        expect(sess.state, RecordingState.autoPaused);

        // Saiu do tunel 30 s depois, 105 m adiante: estava andando.
        walk(sess, fromMs: 91000, toMs: 95000, startMeters: m + 3.5 * 31);
        expect(sess.state, RecordingState.recording);
        expect(sess.stats.timerMs, 95000);
        expect(sess.stats.distanceMeters, closeTo(3.5 * 95, 2));
      },
    );

    test('sem nenhum fix desde o início: pausa e não conta a espera', () {
      final sess = RecordingSession(activityType: ActivityType.walk)..start(0);
      ticks(sess, fromMs: 1000, toMs: 50000);
      expect(sess.state, RecordingState.autoPaused);
      expect(sess.stats.timerMs, 0);
      walk(sess, fromMs: 51000, toMs: 61000);
      expect(sess.state, RecordingState.recording);
      expect(sess.stats.timerMs, lessThanOrEqualTo(10000));
    });

    test('pausa manual durante o silencio e retomada manual', () {
      final sess = RecordingSession(activityType: ActivityType.walk)..start(0);
      final m = walk(sess, fromMs: 0, toMs: 20000);
      ticks(sess, fromMs: 21000, toMs: 40000);
      expect(sess.state, RecordingState.autoPaused);
      sess.pauseManual(41000);
      expect(sess.state, RecordingState.manuallyPaused);
      sess.resumeManual(50000);
      expect(sess.state, RecordingState.recording);
      expect(sess.stats.timerMs, 20000);
      walk(sess, fromMs: 51000, toMs: 55000, startMeters: m + 50);
      expect(sess.state, RecordingState.recording);
      // O salto durante a pausa manual nao soma distancia.
      expect(sess.stats.distanceMeters, lessThan(3.5 * 20 + 3.5 * 5 + 2));
    });

    test('sem pausa automática o silencio não pausa', () {
      final sess = RecordingSession(
        activityType: ActivityType.walk,
        autoPauseEnabled: false,
      )..start(0);
      walk(sess, fromMs: 0, toMs: 10000);
      ticks(sess, fromMs: 11000, toMs: 120000);
      expect(sess.state, RecordingState.recording);
      expect(sess.stats.timerMs, 120000);
    });
  });

  group('corrida (acelerometro)', () {
    /// Celular parado na mesa: so a gravidade.
    void stillAccel(
      RecordingSession sess, {
      required int fromMs,
      required int toMs,
    }) {
      for (var t = fromMs; t <= toMs; t += 100) {
        sess.addAccel(AccelSample(t, 0, 0, 9.81));
      }
    }

    /// Correndo: picos alternados de ~3 m/s^2.
    void runningAccel(
      RecordingSession sess, {
      required int fromMs,
      required int toMs,
    }) {
      var i = 0;
      for (var t = fromMs; t <= toMs; t += 100) {
        sess.addAccel(AccelSample(t, 0, 0, 9.81 + ((i++).isEven ? 3 : -3)));
      }
    }

    test('GRA-02: celular parado e GPS andando a 3,5 m/s soma distância', () {
      final sess = RecordingSession(activityType: ActivityType.run)..start(0);
      for (var t = 0; t <= 60000; t += 1000) {
        stillAccel(sess, fromMs: t, toMs: t + 900);
        sess.addSample(at(3.5 * t / 1000, t: t, speed: 3.5));
      }
      expect(sess.state, RecordingState.recording);
      expect(sess.stats.distanceMeters, greaterThan(3.5 * 50));
    });

    test('GPS parado com celular parado continua pausando', () {
      final sess = RecordingSession(activityType: ActivityType.run)..start(0);
      for (var t = 0; t <= 30000; t += 1000) {
        stillAccel(sess, fromMs: t, toMs: t + 900);
        sess.addSample(at(0.3 * (t % 2000) / 1000, t: t, speed: 0.2));
      }
      expect(sess.state, RecordingState.autoPaused);
    });

    test('acelerometro pausa mesmo sem fix de GPS', () {
      final sess = RecordingSession(activityType: ActivityType.run)..start(0);
      for (var t = 0; t <= 20000; t += 1000) {
        runningAccel(sess, fromMs: t, toMs: t + 900);
        sess.addSample(at(3.5 * t / 1000, t: t, speed: 3.5));
      }
      expect(sess.state, RecordingState.recording);
      // Parou; o GPS tambem para de mandar fix (iOS segura com o usuario parado).
      for (var t = 21000; t <= 30000; t += 1000) {
        stillAccel(sess, fromMs: t, toMs: t + 900);
        sess.tick(t + 900);
      }
      expect(sess.state, RecordingState.autoPaused);
    });

    test(
      'correndo no tunel (acelerometro em movimento) não pausa pelo silencio',
      () {
        final sess = RecordingSession(activityType: ActivityType.run)..start(0);
        for (var t = 0; t <= 20000; t += 1000) {
          runningAccel(sess, fromMs: t, toMs: t + 900);
          sess.addSample(at(3.5 * t / 1000, t: t, speed: 3.5));
        }
        for (var t = 21000; t <= 60000; t += 1000) {
          runningAccel(sess, fromMs: t, toMs: t + 900);
          sess.tick(t + 900);
        }
        expect(sess.state, RecordingState.recording);
        expect(sess.stats.timerMs, 60900);
      },
    );
  });

  // Achados da revisao independente do commit bc9a974.
  group('revisao', () {
    void still(RecordingSession sess, int from, int to) {
      for (var t = from; t <= to; t += 100) {
        sess.addAccel(AccelSample(t, 0, 0, 9.81));
      }
    }

    void running(RecordingSession sess, int from, int to) {
      var i = 0;
      for (var t = from; t <= to; t += 100) {
        sess.addAccel(AccelSample(t, 0, 0, 9.81 + ((i++).isEven ? 3 : -3)));
      }
    }

    void runWithGps(RecordingSession sess, int from, int to) {
      for (var t = from; t <= to; t += 1000) {
        running(sess, t, t + 900);
        sess.addSample(at(3.5 * t / 1000, t: t, speed: 3.5));
      }
    }

    test('pausa por silencio não recua para antes de uma pausa já contada', () {
      final sess = RecordingSession(activityType: ActivityType.run)..start(0);
      runWithGps(sess, 0, 20000);
      for (var t = 21000; t <= 40000; t += 1000) {
        still(sess, t, t + 900);
        sess.tick(t + 900);
      }
      for (var t = 41000; t <= 60000; t += 1000) {
        running(sess, t, t + 900);
        sess.tick(t + 900);
      }
      final before = sess.stats.timerMs;
      // O acelerometro some por 5 s (sem GPS tambem).
      for (var t = 61000; t <= 66000; t += 1000) {
        sess.tick(t + 900);
      }
      expect(sess.stats.timerMs, greaterThanOrEqualTo(before));
    });

    test('tunel correndo com soluco no acelerometro conta inteiro', () {
      final sess = RecordingSession(activityType: ActivityType.run)..start(0);
      runWithGps(sess, 0, 20000);
      for (var t = 21000; t <= 80000; t += 1000) {
        running(sess, t, t + 900);
        sess.tick(t + 900);
      }
      for (var t = 81000; t <= 83000; t += 1000) {
        sess.tick(t + 900);
      }
      for (var t = 84000; t <= 100000; t += 1000) {
        running(sess, t, t + 900);
        sess.tick(t + 900);
      }
      runWithGps(sess, 101000, 105000);
      expect(sess.state, RecordingState.recording);
      expect(sess.stats.timerMs, greaterThan(100000));
      expect(sess.stats.distanceMeters, greaterThan(3.5 * 100));
    });

    test('fix grosseiro depois de parada sem sinal não vira tunel', () {
      final sess = RecordingSession(activityType: ActivityType.walk)..start(0);
      final m = walk(sess, fromMs: 0, toMs: 60000);
      final timer0 = sess.stats.timerMs;
      final d0 = sess.stats.distanceMeters;
      ticks(sess, fromMs: 61000, toMs: 90000);
      // Parado; o fix de rede vem 45 m deslocado, precisao 80 m, sem velocidade.
      sess.addSample(at(m + 45, t: 91000, accuracy: 80));
      for (var t = 92000; t <= 100000; t += 1000) {
        sess.tick(t);
        sess.addSample(at(m, t: t, speed: 0));
      }
      expect(sess.stats.timerMs, lessThan(timer0 + 5000));
      expect(sess.stats.distanceMeters, lessThan(d0 + 5));
    });

    test('volta marcada pouco antes do silencio não fica negativa', () {
      final sess = RecordingSession(activityType: ActivityType.walk)..start(0);
      walk(sess, fromMs: 0, toMs: 60000);
      sess.tick(65000);
      final lap = sess.lap(65000)!;
      ticks(sess, fromMs: 66000, toMs: 80000);
      expect(sess.state, RecordingState.autoPaused);
      expect(sess.stats.timerMs, greaterThanOrEqualTo(lap.endTimerMs));
      expect(sess.currentLap.durationMs, greaterThanOrEqualTo(0));
    });
  });
}
