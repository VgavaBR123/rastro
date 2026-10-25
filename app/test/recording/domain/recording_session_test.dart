// Testes da sessao agregadora e do relogio (etapas 03-04).
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/location_sample.dart';
import 'package:strava_estudo_app/recording/domain/recording_clock.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/domain/recording_session.dart';

LocationSample s(
  double lat,
  double lon, {
  required int t,
  double? speed,
  double? alt,
}) =>
    LocationSample(
      position: GeoPoint(latitude: lat, longitude: lon, altitudeMeters: alt),
      wallClockMs: t,
      monotonicMs: t,
      horizontalAccuracyMeters: 5.0,
      speedMetersPerSecond: speed,
      verticalAccuracyMeters: 3.0,
    );

void main() {
  group('RecordingClock', () {
    test('timer exclui tempo pausado; elapsed inclui', () {
      final c = RecordingClock();
      c.start(0);
      c.tick(10000); // 10 s correndo
      c.pause(10000);
      c.tick(15000);
      c.resume(15000); // 5 s pausado
      c.tick(20000); // +5 s correndo
      expect(c.elapsedMs, 20000);
      expect(c.timerMs, 15000); // 20 - 5 pausado
    });
  });

  group('RecordingSession', () {
    test('acumula distancia e conta pontos aceitos', () {
      final sess = RecordingSession(
        activityType: ActivityType.run,
        autoPauseEnabled: false,
      );
      sess.start(0);
      sess.addSample(s(0, 0, t: 0));
      sess.addSample(s(0, 0.0001, t: 1000)); // ~11 m
      sess.addSample(s(0, 0.0002, t: 2000)); // +~11 m
      final st = sess.stats;
      expect(st.acceptedPointCount, greaterThanOrEqualTo(2));
      expect(st.distanceMeters, greaterThan(18));
      expect(st.state, RecordingState.recording);
    });

    test('auto-pause por velocidade baixa e retomada', () {
      final sess = RecordingSession(
        activityType: ActivityType.ride,
        autoPauseEnabled: true,
      );
      sess.start(0);
      // andando normal
      sess.addSample(s(0, 0.0, t: 0, speed: 8));
      sess.addSample(s(0, 0.0002, t: 1000, speed: 8));
      // parado por tempo suficiente -> auto-pausa
      sess.addSample(s(0, 0.00022, t: 2000, speed: 0.0));
      sess.addSample(s(0, 0.00022, t: 6000, speed: 0.0));
      expect(sess.state, RecordingState.autoPaused);
      // volta a se mover -> retoma
      sess.addSample(s(0, 0.0004, t: 7000, speed: 8));
      expect(sess.state, RecordingState.recording);
    });

    test('acumula elevacao a partir da altitude', () {
      final sess = RecordingSession(
        activityType: ActivityType.run,
        autoPauseEnabled: false,
      );
      sess.start(0);
      sess.addSample(s(0, 0.0, t: 0, alt: 100));
      sess.addSample(s(0, 0.0001, t: 1000, alt: 110));
      sess.addSample(s(0, 0.0002, t: 2000, alt: 105));
      final st = sess.stats;
      expect(st.ascentMeters, closeTo(10, 0.001));
      expect(st.descentMeters, closeTo(5, 0.001));
    });
  });
}
