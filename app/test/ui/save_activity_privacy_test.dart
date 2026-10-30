// Privacidade automatica (F02) na tela Salvar: "so eu" por padrao, ocultar
// primeiros e ultimos X m e a dica de rotina previsivel.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/ui/save_activity_view.dart';
import 'package:strava_estudo_app/ui/theme/app_theme.dart';

const _route = [
  GeoPoint(latitude: -19.92, longitude: -43.94),
  GeoPoint(latitude: -19.91, longitude: -43.93),
];

void main() {
  test('rotulos do corte das pontas nas duas unidades', () {
    expect(hideEdgesLabel(0, metric: true), 'Nao');
    expect(hideEdgesLabel(200, metric: true), '200 m');
    expect(hideEdgesLabel(1000, metric: true), '1 km');
    expect(hideEdgesLabel(200, metric: false), '0.1 mi');
    expect(hideEdgesLabel(1000, metric: false), '0.6 mi');
  });

  Future<List<Object>> pumpView(
    WidgetTester tester, {
    ThemeData? theme,
    bool routineWarning = false,
  }) async {
    final events = <Object>[];
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: theme ?? AppTheme.dark,
      home: Scaffold(
        body: SaveActivityView(
          type: ActivityType.run,
          route: _route,
          distanceMeters: 5230,
          timerMs: 1800000,
          avgPaceSecondsPerMeter: 0.344,
          ascentMeters: 42,
          metric: true,
          startedAt: DateTime(2026, 10, 26, 19, 5),
          routineWarning: routineWarning,
          onBack: () => events.add('back'),
          onSave: events.add,
          onDiscard: () => events.add('discard'),
        ),
      ),
    ));
    return events;
  }

  testWidgets('padrao: so eu e sem corte das pontas', (tester) async {
    final events = await pumpView(tester);
    await tester.tap(find.byKey(const Key('save_activity')));
    await tester.pump();
    final draft = events.single as ActivityDraft;
    expect(draft.visibility, ActivityVisibility.onlyMe);
    expect(draft.hideEdgesMeters, 0);
  });

  for (final (nome, tema) in [('escuro', AppTheme.dark), ('claro', AppTheme.light)]) {
    testWidgets('escolher ocultar 500 m vai no rascunho ($nome)', (tester) async {
      final events = await pumpView(tester, theme: tema);
      expect(find.text('Ocultar inicio e fim'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('hide_edges_500')));
      await tester.tap(find.byKey(const Key('hide_edges_500')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('save_activity')));
      await tester.pump();
      expect((events.single as ActivityDraft).hideEdgesMeters, 500);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('dica de rotina so aparece quando pedida', (tester) async {
    await pumpView(tester);
    expect(find.byKey(const Key('routine_warning')), findsNothing);

    await pumpView(tester, routineWarning: true);
    expect(find.byKey(const Key('routine_warning')), findsOneWidget);
    expect(find.textContaining('mesmo lugar'), findsOneWidget);
  });

  testWidgets('alvos do seletor de corte tem pelo menos 44 dp', (tester) async {
    await pumpView(tester);
    final size = tester.getSize(find.byKey(const Key('hide_edges_0')));
    expect(size.height, greaterThanOrEqualTo(44));
  });
}
