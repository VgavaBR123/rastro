// Funcoes puras do mapa (GeoJSON e enquadramento) e o fallback fora de
// Android/iOS (os testes rodam no host, sem mapa nativo).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/ui/route_map.dart';
import 'package:strava_estudo_app/ui/route_preview.dart';

const a = GeoPoint(latitude: -19.92, longitude: -43.94);
const b = GeoPoint(latitude: -19.91, longitude: -43.93);

void main() {
  test('GeoJSON usa a ordem [lon, lat] e só desenha com 2+ pontos', () {
    final fc = routeFeatureCollection([a, b]);
    final feature = (fc['features'] as List).single as Map;
    expect(feature['geometry'], {
      'type': 'LineString',
      'coordinates': [
        [-43.94, -19.92],
        [-43.93, -19.91],
      ],
    });
    expect(routeFeatureCollection([a])['features'], isEmpty);
    expect(routeFeatureCollection([])['features'], isEmpty);
  });

  test('enquadramento envolve a rota', () {
    final bounds = routeBounds([b, a])!;
    expect(bounds.southwest.latitude, closeTo(-19.92, 1e-9));
    expect(bounds.southwest.longitude, closeTo(-43.94, 1e-9));
    expect(bounds.northeast.latitude, closeTo(-19.91, 1e-9));
    expect(bounds.northeast.longitude, closeTo(-43.93, 1e-9));
    expect(routeBounds([]), isNull);
  });

  test('ponto unico ganha uma caixa minima centrada nele', () {
    final bounds = routeBounds([a])!;
    expect(bounds.northeast.latitude - bounds.southwest.latitude,
        closeTo(kMinBoundsSpanDegrees, 1e-12));
    expect(bounds.northeast.longitude - bounds.southwest.longitude,
        closeTo(kMinBoundsSpanDegrees, 1e-12));
    expect((bounds.northeast.latitude + bounds.southwest.latitude) / 2,
        closeTo(a.latitude, 1e-12));
  });

  testWidgets('fora de Android/iOS usa o RoutePreview', (tester) async {
    expect(nativeMapSupported, isFalse);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: RouteMap(route: [a, b])),
    ));
    expect(find.byType(RoutePreview), findsOneWidget);
  });
}
