// Testes do perfil de elevacao: extracao (so aceitos com altitude), reducao
// por baldes de min/max e ganho.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/activity/elevation_profile.dart';
import 'package:strava_estudo_app/activity/lap_summary.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/recording/domain/waypoint.dart' as dom;

Waypoint row(
  int seq,
  double dist,
  double? alt, {
  dom.WaypointClassification cls = dom.WaypointClassification.accept,
}) => Waypoint(
  id: seq,
  activityGuid: 'a',
  seq: seq,
  latitude: 0,
  longitude: 0,
  altitudeMeters: alt,
  elapsedTimeMs: seq * 1000,
  timerTimeMs: seq * 1000,
  cumulativeDistanceMeters: dist,
  classification: cls.index,
);

List<ElevationSample> serie(int n, double Function(int i) alt) => [
  for (var i = 0; i < n; i++) ElevationSample(i * 10.0, alt(i)),
];

void main() {
  group('extracao', () {
    test('ignora pontos sem altitude e pontos não aceitos', () {
      final s = elevationSamplesFromWaypoints([
        row(0, 0, 100),
        row(1, 10, null),
        row(2, 20, 500, cls: dom.WaypointClassification.ignoreBadAccuracy),
        row(3, 30, 110),
      ]);
      expect(s.map((e) => e.distanceMeters), [0, 30]);
      expect(s.map((e) => e.altitudeMeters), [100, 110]);
    });

    test('menos de 2 pontos com altitude -> sem perfil', () {
      expect(buildElevationProfile([]), isNull);
      expect(buildElevationProfile([row(0, 0, 100), row(1, 10, null)]), isNull);
    });

    test('perfil traz min, max, faixa de distância e ganho', () {
      final p = buildElevationProfile([
        row(0, 0, 100),
        row(1, 100, 120),
        row(2, 200, 90),
        row(3, 300, 130),
      ])!;
      expect(p.minAltitudeMeters, 90);
      expect(p.maxAltitudeMeters, 130);
      expect(p.startDistanceMeters, 0);
      expect(p.endDistanceMeters, 300);
      // Subidas: 100->120 (+20) e 90->130 (+40).
      expect(p.gainMeters, closeTo(60, 1e-9));
      expect(p.points, hasLength(4));
    });
  });

  group('reducao', () {
    test('serie curta volta inalterada', () {
      final s = serie(50, (i) => i.toDouble());
      expect(reduceElevationSamples(s, 300), hasLength(50));
    });

    test('respeita o limite e mantem primeiro e último', () {
      final s = serie(10000, (i) => math.sin(i / 50) * 100);
      final r = reduceElevationSamples(s, 300);
      expect(r.length, lessThanOrEqualTo(300));
      expect(r.length, greaterThan(200));
      expect(r.first, same(s.first));
      expect(r.last, same(s.last));
    });

    test('preserva picos estreitos (min e max globais)', () {
      // Serie plana com um pico de 1 ponto e um vale de 1 ponto.
      final s = serie(5000, (i) {
        if (i == 1234) return 900;
        if (i == 3777) return -50;
        return 100;
      });
      final r = reduceElevationSamples(s, 300);
      final alts = r.map((e) => e.altitudeMeters);
      expect(alts.reduce(math.max), 900);
      expect(alts.reduce(math.min), -50);
    });

    test('mantem a ordem por distância', () {
      final rnd = math.Random(7);
      final s = serie(3001, (_) => rnd.nextDouble() * 500);
      final r = reduceElevationSamples(s, 301);
      expect(r.length, lessThanOrEqualTo(301));
      for (var i = 1; i < r.length; i++) {
        expect(r[i].distanceMeters, greaterThan(r[i - 1].distanceMeters));
      }
    });

    test('perfil grande usa o limite padrao de 300', () {
      final rows = [
        for (var i = 0; i < 2000; i++) row(i, i * 5.0, 100.0 + i % 37),
      ];
      final p = buildElevationProfile(rows)!;
      expect(p.points.length, lessThanOrEqualTo(kElevationProfileMaxPoints));
      expect(p.maxAltitudeMeters, 136);
    });
  });

  group('voltas', () {
    test('resumo calcula distância, tempo e pace', () {
      final l = LapSummary.fromLap(
        const Lap(
          activityGuid: 'a',
          number: 2,
          startTimerMs: 60000,
          endTimerMs: 360000,
          endElapsedMs: 370000,
          startDistanceMeters: 200,
          endDistanceMeters: 1200,
        ),
      );
      expect(l.distanceMeters, 1000);
      expect(l.durationMs, 300000);
      expect(l.paceSecondsPerMeter, closeTo(0.3, 1e-12));
    });

    test('volta sem distância não tem pace', () {
      final l = LapSummary.fromLap(
        const Lap(
          activityGuid: 'a',
          number: 1,
          startTimerMs: 0,
          endTimerMs: 1000,
          endElapsedMs: 1000,
          startDistanceMeters: 50,
          endDistanceMeters: 50,
        ),
      );
      expect(l.paceSecondsPerMeter, isNull);
    });
  });
}
