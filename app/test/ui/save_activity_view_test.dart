// Tela Salvar isolada: titulo pelo horario, campos, visibilidade e as acoes
// (Descartar so depois de confirmar), nos dois temas.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/core/format/activity_labels.dart';
import 'package:strava_estudo_app/core/format/measures.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/ui/save_activity_view.dart';
import 'package:strava_estudo_app/ui/theme/app_theme.dart';

const _route = [
  GeoPoint(latitude: -19.92, longitude: -43.94),
  GeoPoint(latitude: -19.91, longitude: -43.93),
];

void main() {
  test('titulo sugerido pelo horario de inicio', () {
    expect(suggestedActivityTitle(ActivityType.run, DateTime(2026, 1, 1, 6)), 'Corrida da manha');
    expect(suggestedActivityTitle(ActivityType.ride, DateTime(2026, 1, 1, 11, 59)), 'Pedal da manha');
    expect(suggestedActivityTitle(ActivityType.walk, DateTime(2026, 1, 1, 12)), 'Caminhada da tarde');
    expect(suggestedActivityTitle(ActivityType.run, DateTime(2026, 1, 1, 18)), 'Corrida da noite');
    expect(suggestedActivityTitle(ActivityType.run, DateTime(2026, 1, 1, 4, 59)), 'Corrida da noite');
  });

  test('separa valor e unidade', () {
    expect(splitMeasure('5:30 /km'), ('5:30', '/km'));
    expect(splitMeasure('1:02:03'), ('1:02:03', null));
  });

  Future<List<Object>> pumpView(WidgetTester tester, ThemeData theme) async {
    final events = <Object>[];
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: theme,
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
          onBack: () => events.add('back'),
          onSave: events.add,
          onDiscard: () => events.add('discard'),
        ),
      ),
    ));
    return events;
  }

  for (final (nome, tema) in [('escuro', AppTheme.dark), ('claro', AppTheme.light)]) {
    testWidgets('renderiza e salva com o rascunho no tema $nome', (tester) async {
      final events = await pumpView(tester, tema);
      expect(tester.takeException(), isNull);
      expect(find.text('Corrida da noite'), findsOneWidget);
      expect(find.text('Distancia'), findsOneWidget);
      expect(find.text('Subida'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('save_description')), 'Treino leve');
      await tester.tap(find.byKey(const Key('visibility_followers')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('save_activity')));
      await tester.pump();

      final draft = events.single as ActivityDraft;
      expect(draft.title, 'Corrida da noite');
      expect(draft.description, 'Treino leve');
      expect(draft.visibility, ActivityVisibility.followers);
    });
  }

  testWidgets('com o teclado aberto Salvar e Descartar saem do caminho (GRA-04)', (tester) async {
    await pumpView(tester, AppTheme.dark);
    expect(find.byKey(const Key('save_activity')), findsOneWidget);
    expect(find.byKey(const Key('discard_activity')), findsOneWidget);

    // O Scaffold tira o teclado do MediaQuery do corpo; a tela precisa ver o
    // teclado mesmo assim.
    tester.view.viewInsets = const FakeViewPadding(bottom: 700);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('save_activity')), findsNothing);
    expect(find.byKey(const Key('discard_activity')), findsNothing);
    expect(find.byKey(const Key('save_description')), findsOneWidget);

    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('save_activity')), findsOneWidget);
    expect(find.byKey(const Key('discard_activity')), findsOneWidget);
  });

  testWidgets('Descartar so dispara depois de confirmar', (tester) async {
    final events = await pumpView(tester, AppTheme.dark);
    await tester.tap(find.byKey(const Key('discard_activity')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('discard_cancel')));
    await tester.pumpAndSettle();
    expect(events, isEmpty);

    await tester.tap(find.byKey(const Key('discard_activity')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('discard_confirm')));
    await tester.pumpAndSettle();
    expect(events, ['discard']);

    await tester.tap(find.byKey(const Key('save_back')));
    expect(events, ['discard', 'back']);
  });
}
