// Testes da pausa automatica por velocidade (etapa 03).
//
// O caso central aqui e a amostra SEM velocidade informada: tratar isso como
// zero pausaria a gravacao com o usuario em movimento. O detector deriva a
// velocidade do deslocamento quando o provedor nao informa.
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/recording/domain/auto_pause.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/location_sample.dart';

LocationSample amostra(
  double lat,
  double lon, {
  required int t,
  double? speed,
}) =>
    LocationSample(
      position: GeoPoint(latitude: lat, longitude: lon),
      wallClockMs: t,
      monotonicMs: t,
      horizontalAccuracyMeters: 5,
      speedMetersPerSecond: speed,
    );

void main() {
  group('SpeedAutoPauseDetector com velocidade informada', () {
    test('pausa depois do tempo minimo parado', () {
      final d = SpeedAutoPauseDetector();
      expect(d.shouldBePaused(amostra(0, 0, t: 0, speed: 0.0)), isFalse);
      expect(d.shouldBePaused(amostra(0, 0, t: 2000, speed: 0.0)), isFalse);
      // 3 s abaixo do limiar -> pausa.
      expect(d.shouldBePaused(amostra(0, 0, t: 3000, speed: 0.0)), isTrue);
    });

    test('retoma quando a velocidade sobe', () {
      final d = SpeedAutoPauseDetector();
      d.shouldBePaused(amostra(0, 0, t: 0, speed: 0.0));
      expect(d.shouldBePaused(amostra(0, 0, t: 4000, speed: 0.0)), isTrue);
      expect(d.shouldBePaused(amostra(0, 0, t: 5000, speed: 3.0)), isFalse);
    });
  });

  group('SpeedAutoPauseDetector sem velocidade informada', () {
    test('em movimento, NAO pausa (regressao: ausente != zero)', () {
      final d = SpeedAutoPauseDetector();
      // ~11 m por segundo, sem o campo de velocidade.
      for (int i = 0; i <= 6; i++) {
        final paused = d.shouldBePaused(
          amostra(0, i * 0.0001, t: i * 1000),
        );
        expect(paused, isFalse, reason: 'amostra $i nao deveria pausar');
      }
    });

    test('parado, pausa pela velocidade derivada', () {
      final d = SpeedAutoPauseDetector();
      d.shouldBePaused(amostra(0, 0, t: 0));
      d.shouldBePaused(amostra(0, 0, t: 1000));
      d.shouldBePaused(amostra(0, 0, t: 2000));
      expect(d.shouldBePaused(amostra(0, 0, t: 4000)), isTrue);
    });

    test('primeira amostra sem velocidade nao muda o estado', () {
      final d = SpeedAutoPauseDetector();
      expect(d.shouldBePaused(amostra(0, 0, t: 0)), isFalse);
    });

    test('reset esquece a posicao anterior', () {
      final d = SpeedAutoPauseDetector();
      d.shouldBePaused(amostra(0, 0, t: 0));
      d.shouldBePaused(amostra(0, 0, t: 1000));
      d.reset();
      // Sem referencia anterior, a velocidade volta a ser desconhecida.
      expect(d.shouldBePaused(amostra(0, 0, t: 2000)), isFalse);
    });
  });
}
