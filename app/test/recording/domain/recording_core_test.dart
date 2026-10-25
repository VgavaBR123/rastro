// Testes do nucleo clean-room de gravacao (etapas 03-04).
// Rodar com: flutter test  (ou dart test), apos instalar o SDK.
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/location_sample.dart';
import 'package:strava_estudo_app/recording/domain/point_pipeline.dart';
import 'package:strava_estudo_app/recording/domain/waypoint.dart';
import 'package:strava_estudo_app/recording/domain/splits.dart';
import 'package:strava_estudo_app/recording/domain/elevation.dart';

LocationSample sample(
  double lat,
  double lon, {
  required int t,
  double? acc = 5.0,
}) =>
    LocationSample(
      position: GeoPoint(latitude: lat, longitude: lon),
      wallClockMs: t,
      monotonicMs: t,
      horizontalAccuracyMeters: acc,
    );

void main() {
  group('haversine', () {
    test('1 grau de latitude ~= 111 km', () {
      final d = haversineMeters(
        const GeoPoint(latitude: 0, longitude: 0),
        const GeoPoint(latitude: 1, longitude: 0),
      );
      expect(d, closeTo(111195, 300));
    });
  });

  group('PointPipeline', () {
    test('rejeita precisao ausente ou acima de 150 m', () {
      final p = PointPipeline();
      final w1 = p.process(sample(0, 0, t: 0, acc: null),
          manuallyPaused: false, elapsedTimeMs: 0, timerTimeMs: 0);
      final w2 = p.process(sample(0, 0, t: 1000, acc: 200),
          manuallyPaused: false, elapsedTimeMs: 1000, timerTimeMs: 1000);
      expect(w1.classification, WaypointClassification.ignoreBadAccuracy);
      expect(w2.classification, WaypointClassification.ignoreBadAccuracy);
    });

    test('ignora deslocamento abaixo de 3 m', () {
      final p = PointPipeline();
      p.process(sample(0, 0, t: 0),
          manuallyPaused: false, elapsedTimeMs: 0, timerTimeMs: 0);
      // ~1 m de deslocamento
      final w = p.process(sample(0, 0.000009, t: 1000),
          manuallyPaused: false, elapsedTimeMs: 1000, timerTimeMs: 1000);
      expect(w.classification, WaypointClassification.ignoreSampleUpdateFilter);
      expect(p.cumulativeDistanceMeters, 0.0);
    });

    test('acumula distancia em pontos aceitos', () {
      final p = PointPipeline();
      p.process(sample(0, 0, t: 0),
          manuallyPaused: false, elapsedTimeMs: 0, timerTimeMs: 0);
      // ~11 m de deslocamento em 1 s -> aceito
      final w = p.process(sample(0, 0.0001, t: 1000),
          manuallyPaused: false, elapsedTimeMs: 1000, timerTimeMs: 1000);
      expect(w.classification, WaypointClassification.accept);
      expect(p.cumulativeDistanceMeters, greaterThan(10));
    });

    test('rejeita salto com aceleracao implausivel', () {
      final p = PointPipeline();
      // dois pontos normais (devagar)
      p.process(sample(0, 0, t: 0),
          manuallyPaused: false, elapsedTimeMs: 0, timerTimeMs: 0);
      p.process(sample(0, 0.0001, t: 1000),
          manuallyPaused: false, elapsedTimeMs: 1000, timerTimeMs: 1000);
      // salto enorme no passo seguinte (centenas de metros em 1 s)
      final w = p.process(sample(0, 0.01, t: 2000),
          manuallyPaused: false, elapsedTimeMs: 2000, timerTimeMs: 2000);
      expect(w.classification, WaypointClassification.ignoreAccelerationFilter);
    });

    test('ignora pontos durante pausa manual', () {
      final p = PointPipeline();
      final w = p.process(sample(0, 0, t: 0),
          manuallyPaused: true, elapsedTimeMs: 0, timerTimeMs: 0);
      expect(w.classification, WaypointClassification.ignoreManualPause);
    });
  });

  group('SplitList', () {
    test('fecha split na marca exata com tempo interpolado', () {
      final s = SplitList(1000.0);
      // ponto antes da marca: 900 m em 300 s
      s.update(900, 300000);
      // ponto depois: 1100 m em 360 s -> cruza 1000 m
      s.update(1100, 360000);
      expect(s.completedCount, 1);
      final split = s.completed.first;
      expect(split.endDistanceMeters, 1000);
      // frac = (1000-900)/(1100-900)=0.5 -> t = 300000 + 0.5*60000 = 330000
      expect(split.endTimerMs, 330000);
    });

    test('fecha varios splits num unico update (salto)', () {
      final s = SplitList(1000.0);
      s.update(500, 100000);
      s.update(2500, 500000); // cruza 1000 e 2000 de uma vez
      expect(s.completedCount, 2);
      expect(s.completed[0].endDistanceMeters, 1000);
      expect(s.completed[1].endDistanceMeters, 2000);
    });
  });

  group('ElevationAccumulator', () {
    test('ignora micro-oscilacao abaixo do limiar', () {
      final e = ElevationAccumulator(minDeltaMeters: 1.0);
      e.process(100);
      e.process(100.5); // dentro do ruido
      final stats = e.process(100.9); // ainda dentro do ruido vs referencia 100
      expect(stats.ascentMeters, 0.0);
    });

    test('acumula subida e descida acima do limiar', () {
      final e = ElevationAccumulator(minDeltaMeters: 1.0);
      e.process(100);
      e.process(105); // +5 subida
      final stats = e.process(102); // -3 descida
      expect(stats.ascentMeters, closeTo(5, 0.001));
      expect(stats.descentMeters, closeTo(3, 0.001));
    });

    test('descarta ponto de precisao vertical ruim', () {
      final e = ElevationAccumulator(maxVerticalAccuracyMeters: 20);
      e.process(100);
      final stats = e.process(130, verticalAccuracyMeters: 50);
      expect(stats.ascentMeters, 0.0);
    });
  });
}
