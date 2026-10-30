// Privacidade automatica (F02): funcao pura de corte do inicio e do fim da
// rota dentro das zonas, com raio efetivo determinado pelo guid.
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/privacy/domain/privacy_zone.dart';
import 'package:strava_estudo_app/privacy/domain/route_trim.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';

/// ~11,1 m por passo de 0.0001 grau no equador.
const double kStep = 0.0001;

/// Rota reta para leste a partir de (0, 0): [n] pontos.
List<GeoPoint> line(int n, {double fromLon = 0}) => [
  for (var i = 0; i < n; i++)
    GeoPoint(latitude: 0, longitude: fromLon + i * kStep),
];

PrivacyZone zoneAt(double lon, {double radius = 200, double lat = 0}) =>
    PrivacyZone(latitude: lat, longitude: lon, radiusMeters: radius, label: 'Casa');

void main() {
  group('raio efetivo pelo guid', () {
    test('fica entre 200 e 600 m', () {
      for (final g in ['a', 'b', 'guid-123', 'xyz', '', 'outro guid longo']) {
        final r = cutRadiusForActivity(g);
        expect(r, inInclusiveRange(kMinCutRadiusMeters, kMaxCutRadiusMeters));
      }
    });

    test('mesma atividade sempre o mesmo raio', () {
      expect(cutRadiusForActivity('guid-1'), cutRadiusForActivity('guid-1'));
    });

    test('atividades diferentes variam o raio', () {
      final radii = {
        for (var i = 0; i < 20; i++) cutRadiusForActivity('atividade-$i').round(),
      };
      expect(radii.length, greaterThan(10));
    });
  });

  group('zona', () {
    test('contem ponto dentro do raio e nao fora', () {
      final z = zoneAt(0, radius: 100);
      expect(z.contains(const GeoPoint(latitude: 0, longitude: 0.0005)), isTrue);
      expect(z.contains(const GeoPoint(latitude: 0, longitude: 0.002)), isFalse);
      // Com raio maior informado.
      expect(
        z.contains(const GeoPoint(latitude: 0, longitude: 0.002), radiusMeters: 300),
        isTrue,
      );
    });
  });

  group('corte da rota', () {
    test('sem zonas e sem distancia: mantem tudo', () {
      final t = computeRouteTrim(line(50), zones: const [], activityGuid: 'g');
      expect(t.start, 0);
      expect(t.end, 50);
      expect(t.hidesAnything, isFalse);
      expect(t.apply(line(50)), hasLength(50));
    });

    test('inicio dentro da zona e cortado ate sair do raio efetivo', () {
      final route = line(200); // ~2,2 km
      final t = computeRouteTrim(route, zones: [zoneAt(0)], activityGuid: 'g');
      final r = cutRadiusForActivity('g');
      expect(t.hidesStart, isTrue);
      expect(t.hidesEnd, isFalse);
      // O primeiro ponto mantido esta fora do raio e o anterior dentro.
      final center = const GeoPoint(latitude: 0, longitude: 0);
      expect(haversineMeters(center, route[t.start]), greaterThan(r));
      expect(haversineMeters(center, route[t.start - 1]), lessThanOrEqualTo(r));
      expect(t.end, 200);
    });

    test('fim dentro da zona e cortado', () {
      final route = line(200);
      final endLon = 199 * kStep;
      final t = computeRouteTrim(route, zones: [zoneAt(endLon)], activityGuid: 'g');
      expect(t.hidesStart, isFalse);
      expect(t.hidesEnd, isTrue);
      final r = cutRadiusForActivity('g');
      final center = GeoPoint(latitude: 0, longitude: endLon);
      expect(haversineMeters(center, route[t.end - 1]), greaterThan(r));
      expect(haversineMeters(center, route[t.end]), lessThanOrEqualTo(r));
    });

    test('ida e volta de casa: corta as duas pontas', () {
      final ida = line(150);
      final route = [...ida, ...ida.reversed];
      final t = computeRouteTrim(route, zones: [zoneAt(0)], activityGuid: 'g');
      expect(t.hidesStart, isTrue);
      expect(t.hidesEnd, isTrue);
      expect(t.end - t.start, lessThan(route.length));
    });

    test('passar pela zona no meio da rota nao corta o meio', () {
      // Comeca longe, passa sobre a zona e termina longe.
      final route = line(300, fromLon: -0.015);
      final t = computeRouteTrim(route, zones: [zoneAt(0)], activityGuid: 'g');
      expect(t.start, 0);
      expect(t.end, 300);
    });

    test('mesma atividade sempre corta igual', () {
      final route = line(200);
      final a = computeRouteTrim(route, zones: [zoneAt(0)], activityGuid: 'x1');
      final b = computeRouteTrim(route, zones: [zoneAt(0)], activityGuid: 'x1');
      expect((a.start, a.end), (b.start, b.end));
    });

    test('raio da zona maior que o aleatorio prevalece', () {
      final route = line(200);
      final t = computeRouteTrim(
        route,
        zones: [zoneAt(0, radius: 1000)],
        activityGuid: 'g',
      );
      final center = const GeoPoint(latitude: 0, longitude: 0);
      expect(haversineMeters(center, route[t.start]), greaterThan(1000));
    });

    test('ocultar primeiros e ultimos X m sem zona', () {
      final route = line(100); // ~1,1 km
      final t = computeRouteTrim(
        route,
        zones: const [],
        activityGuid: 'g',
        hideStartMeters: 100,
        hideEndMeters: 200,
      );
      expect(t.hidesStart, isTrue);
      expect(t.hidesEnd, isTrue);
      expect(haversineMeters(route.first, route[t.start]), greaterThanOrEqualTo(100));
      expect(haversineMeters(route.first, route[t.start - 1]), lessThan(100));
      expect(haversineMeters(route[t.end - 1], route.last), greaterThanOrEqualTo(200));
      expect(haversineMeters(route[t.end], route.last), lessThan(200));
    });

    test('zona e distancia juntas: vale o maior corte', () {
      final route = line(300);
      final soZona = computeRouteTrim(route, zones: [zoneAt(0)], activityGuid: 'g');
      final ambos = computeRouteTrim(
        route,
        zones: [zoneAt(0)],
        activityGuid: 'g',
        hideStartMeters: 2000,
      );
      expect(ambos.start, greaterThan(soZona.start));
    });

    test('rota toda dentro da zona: nada sobra', () {
      final route = line(10);
      final t = computeRouteTrim(route, zones: [zoneAt(0)], activityGuid: 'g');
      expect(t.hidesAll, isTrue);
      expect(t.apply(route), isEmpty);
    });

    test('rota vazia: nada a cortar', () {
      final t = computeRouteTrim(const [], zones: [zoneAt(0)], activityGuid: 'g');
      expect(t.hidesAnything, isFalse);
      expect(t.apply(const <GeoPoint>[]), isEmpty);
    });

    test('apply recorta qualquer lista paralela a rota', () {
      final route = line(200);
      final t = computeRouteTrim(route, zones: [zoneAt(0)], activityGuid: 'g');
      final ids = [for (var i = 0; i < 200; i++) i];
      expect(t.apply(ids).first, t.start);
      expect(t.apply(ids).last, t.end - 1);
    });
  });
}
