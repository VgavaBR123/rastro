// Testes da projecao da rota (funcao pura) e render do RoutePreview.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/ui/route_preview.dart';

void main() {
  const size = Size(200, 200);

  test('rota vazia projeta lista vazia', () {
    expect(projectRoute(const [], size), isEmpty);
  });

  test('todos os offsets ficam dentro da area', () {
    final pts = [
      const GeoPoint(latitude: 0, longitude: 0),
      const GeoPoint(latitude: 0.001, longitude: 0.001),
      const GeoPoint(latitude: 0.002, longitude: 0.0005),
    ];
    final offs = projectRoute(pts, size);
    expect(offs.length, pts.length);
    for (final o in offs) {
      expect(o.dx, inInclusiveRange(0, size.width));
      expect(o.dy, inInclusiveRange(0, size.height));
    }
  });

  test('linha reta para leste mantem o y constante e x crescente', () {
    final pts = [
      const GeoPoint(latitude: 0, longitude: 0.0),
      const GeoPoint(latitude: 0, longitude: 0.001),
      const GeoPoint(latitude: 0, longitude: 0.002),
    ];
    final offs = projectRoute(pts, size);
    expect(offs[0].dy, closeTo(offs[1].dy, 0.0001));
    expect(offs[1].dy, closeTo(offs[2].dy, 0.0001));
    expect(offs[0].dx < offs[1].dx, true);
    expect(offs[1].dx < offs[2].dx, true);
  });

  testWidgets('RoutePreview sem pontos mostra placeholder', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: RoutePreview(route: [])),
    ));
    expect(find.text('Aguardando GPS...'), findsOneWidget);
  });
}
