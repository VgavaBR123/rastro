// Fechamento gentil (F04) na tela Salvar: esforco percebido (1 a 10, com
// rotulo da faixa) e humor (5 opcoes com icone e texto), ambos opcionais, e
// o Modo Gentil escondendo o pace.
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

Future<List<Object>> pumpView(
  WidgetTester tester, {
  bool gentle = false,
  ThemeData? theme,
}) async {
  final events = <Object>[];
  tester.view.physicalSize = const Size(400, 2400);
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
        gentle: gentle,
        onBack: () => events.add('back'),
        onSave: events.add,
        onDiscard: () => events.add('discard'),
      ),
    ),
  ));
  return events;
}

Future<void> tapVisible(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.pump();
  await tester.tap(find.byKey(key));
  await tester.pump();
}

void main() {
  testWidgets('sem escolher nada: RPE e humor seguem nulos', (tester) async {
    final events = await pumpView(tester);
    expect(find.byKey(const Key('save_rpe')), findsOneWidget);
    expect(find.byKey(const Key('save_mood')), findsOneWidget);
    expect(find.text('Opcional'), findsWidgets);
    await tapVisible(tester, const Key('save_activity'));
    final draft = events.single as ActivityDraft;
    expect(draft.rpe, isNull);
    expect(draft.mood, isNull);
  });

  for (final (nome, tema) in [('escuro', AppTheme.dark), ('claro', AppTheme.light)]) {
    testWidgets('escolhe RPE 7 (Forte) e humor Cansado no tema $nome', (tester) async {
      final events = await pumpView(tester, theme: tema);
      for (var i = 1; i <= 10; i++) {
        expect(find.byKey(Key('rpe_$i')), findsOneWidget);
      }
      await tapVisible(tester, const Key('rpe_7'));
      expect(find.text('7 - Forte'), findsOneWidget);
      await tapVisible(tester, const Key('mood_tired'));
      expect(tester.takeException(), isNull);
      await tapVisible(tester, const Key('save_activity'));
      final draft = events.single as ActivityDraft;
      expect(draft.rpe, 7);
      expect(draft.mood, Mood.tired);
    });
  }

  testWidgets('tocar de novo desmarca', (tester) async {
    final events = await pumpView(tester);
    await tapVisible(tester, const Key('rpe_3'));
    expect(find.text('3 - Tranquilo'), findsOneWidget);
    await tapVisible(tester, const Key('rpe_3'));
    await tapVisible(tester, const Key('mood_great'));
    await tapVisible(tester, const Key('mood_great'));
    await tapVisible(tester, const Key('save_activity'));
    final draft = events.single as ActivityDraft;
    expect(draft.rpe, isNull);
    expect(draft.mood, isNull);
  });

  testWidgets('humor: 5 opcoes com icone e texto', (tester) async {
    await pumpView(tester);
    for (final m in Mood.values) {
      final option = find.byKey(Key('mood_${m.dbValue}'));
      expect(option, findsOneWidget);
      expect(find.descendant(of: option, matching: find.text(m.label)), findsOneWidget);
      expect(find.descendant(of: option, matching: find.byType(Icon)), findsOneWidget);
    }
  });

  testWidgets('alvos de toque com pelo menos 44 dp', (tester) async {
    await pumpView(tester);
    for (var i = 1; i <= 10; i++) {
      final size = tester.getSize(find.byKey(Key('rpe_$i')));
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
    }
    for (final m in Mood.values) {
      expect(tester.getSize(find.byKey(Key('mood_${m.dbValue}'))).height,
          greaterThanOrEqualTo(44));
    }
  });

  testWidgets('Modo Gentil: sem pace no resumo', (tester) async {
    await pumpView(tester, gentle: true);
    expect(find.byKey(const Key('save_pace')), findsNothing);
    expect(find.text('Pace medio'), findsNothing);
    expect(find.byKey(const Key('save_distance')), findsOneWidget);
    expect(find.byKey(const Key('save_duration')), findsOneWidget);
  });
}
