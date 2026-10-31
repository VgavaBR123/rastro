// INI-11/HIS-07 (teste no iPhone, 30/10/2026): sem trajeto, o cartao de
// compartilhar mostra o esporte no lugar da rota, e o estilo Cartao tem borda.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/ui/share/share_card.dart';
import 'package:strava_estudo_app/ui/theme/app_theme.dart';

ShareCardData data(List<GeoPoint> route) => ShareCardData(
  title: 'Corrida da manha',
  type: ActivityType.run,
  startTimestampMs: 0,
  distanceMeters: 0,
  timerMs: 6000,
  route: route,
  metric: true,
);

Future<void> pump(WidgetTester tester, ShareCardData d, ShareCardStyle style) =>
    tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: Center(child: ShareCard(data: d, style: style)),
    ));

void main() {
  testWidgets('um ponto so: marca do esporte no lugar da rota', (tester) async {
    await pump(tester, data(const [GeoPoint(latitude: 0, longitude: 0)]), ShareCardStyle.card);
    expect(find.byKey(const Key('share_card_no_route')), findsOneWidget);
    expect(find.byKey(const Key('share_card_route')), findsNothing);
  });

  testWidgets('com rota nao mostra a marca', (tester) async {
    await pump(
      tester,
      data(const [GeoPoint(latitude: 0, longitude: 0), GeoPoint(latitude: 0.001, longitude: 0)]),
      ShareCardStyle.card,
    );
    expect(find.byKey(const Key('share_card_no_route')), findsNothing);
    expect(find.byKey(const Key('share_card_route')), findsOneWidget);
  });

  for (final (style, bordered) in [(ShareCardStyle.card, true), (ShareCardStyle.transparent, false)]) {
    testWidgets('borda no estilo ${style.label}: $bordered', (tester) async {
      await pump(tester, data(const []), style);
      final box = tester.widget<DecoratedBox>(find.descendant(
        of: find.byType(ShareCard),
        matching: find.byType(DecoratedBox),
      ).first);
      expect((box.decoration as BoxDecoration).border != null, bordered);
    });
  }
}
