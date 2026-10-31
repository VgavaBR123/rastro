// Widget tests do WeekSummaryCard, no tema escuro e no claro.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/activity/week_summary.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/ui/components/week_summary_card.dart';
import 'package:strava_estudo_app/ui/theme/app_colors.dart';
import 'package:strava_estudo_app/ui/theme/app_theme.dart';

final now = DateTime(2026, 10, 28, 12);

WeekSummary summary() => buildWeekSummary([
      WeekEntry(
        type: ActivityType.run,
        startTimestampMs: DateTime(2026, 10, 26, 7).millisecondsSinceEpoch,
        distanceMeters: 5000,
        timerTimeMs: 1800000,
        elevationGainMeters: 42,
      ),
      WeekEntry(
        type: ActivityType.ride,
        startTimestampMs: DateTime(2026, 10, 28, 7).millisecondsSinceEpoch,
        distanceMeters: 20000,
        timerTimeMs: 3600000,
        elevationGainMeters: 100,
      ),
    ], now: now);

Future<void> pump(WidgetTester tester, WeekSummary s, ThemeData theme, {bool metric = true}) =>
    tester.pumpWidget(MaterialApp(
      theme: theme,
      home: Scaffold(body: WeekSummaryCard(summary: s, useMetric: metric, todayIndex: 2)),
    ));

/// Cor da barra de um dia.
Color? barColor(WidgetTester tester, int day) {
  final box = tester.widget<Container>(find.descendant(
    of: find.byKey(Key('week_day_$day')),
    matching: find.byWidgetPredicate((w) => w is Container && w.decoration != null),
  ));
  return (box.decoration! as BoxDecoration).color;
}

void main() {
  test('rotulo da contagem', () {
    expect(workoutCountLabel(0), 'Nenhum treino');
    expect(workoutCountLabel(1), '1 treino');
    expect(workoutCountLabel(4), '4 treinos');
  });

  for (final (name, theme) in [('escuro', AppTheme.dark), ('claro', AppTheme.light)]) {
    testWidgets('mostra titulo, contagem, tres metricas e sete barras ($name)', (tester) async {
      await pump(tester, summary(), theme);
      final c = theme.extension<AppColors>() ?? AppColors.dark;

      expect(find.text('Esta semana'), findsOneWidget);
      expect(find.text('2 treinos'), findsOneWidget);
      expect(find.text('Distancia'), findsOneWidget);
      expect(find.text('Tempo'), findsOneWidget);
      expect(find.text('Subida'), findsOneWidget);
      expect(find.textContaining('25,00'), findsOneWidget);
      expect(find.textContaining('1:30:00'), findsOneWidget);
      expect(find.textContaining('142'), findsOneWidget);
      for (var i = 0; i < 7; i++) {
        expect(find.byKey(Key('week_day_$i')), findsOneWidget);
      }
      // Barras na cor do esporte do dia; dia vazio no trilho neutro.
      expect(barColor(tester, 0), c.sport(ActivityType.run).fill);
      expect(barColor(tester, 2), c.sport(ActivityType.ride).fill);
      expect(barColor(tester, 1), c.surface2);
    });
  }

  testWidgets('semana vazia mostra zeros sem meta inventada', (tester) async {
    await pump(tester, buildWeekSummary(const [], now: now), AppTheme.dark, metric: false);
    expect(find.text('Nenhum treino'), findsOneWidget);
    expect(find.textContaining(' de '), findsNothing);
    // Zero em imperial: distancia e subida em pes (EST-05).
    expect(find.textContaining('ft'), findsNWidgets(2));
  });
}
