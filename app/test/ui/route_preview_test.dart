// Testes da projecao da rota (funcao pura) e render do RoutePreview.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/ui/route_preview.dart';
import 'package:strava_estudo_app/ui/theme/app_colors.dart';
import 'package:strava_estudo_app/ui/theme/app_theme.dart';

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

  for (final (name, theme) in [('escuro', AppTheme.dark), ('claro', AppTheme.light)]) {
    testWidgets('miniatura com cor, halo e partida desenha sem erro ($name)', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: Scaffold(
          body: RoutePreview(
            route: const [
              GeoPoint(latitude: 0, longitude: 0),
              GeoPoint(latitude: 0.001, longitude: 0.002),
            ],
            color: AppColors.dark.pace.fill,
            height: 140,
            halo: true,
            showStart: true,
            emptyLabel: 'Sem rota',
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
      expect(find.text('Sem rota'), findsNothing);
      expect(tester.getSize(find.byType(RoutePreview)).height, 140);
    });
  }

  testWidgets('rotulo de vazio configuravel', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: const Scaffold(body: RoutePreview(route: [], emptyLabel: 'Sem rota')),
    ));
    expect(find.text('Sem rota'), findsOneWidget);
  });
}
