// Carga do treino (F04) na aba Estatisticas: total do periodo (sRPE) e barras
// por semana; sem nenhum treino com esforco, uma dica de como comecar.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/activity/stats_summary.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/auth/session_store.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/ui/stats_screen.dart';
import 'package:strava_estudo_app/ui/theme/app_theme.dart';

final now = DateTime(2026, 10, 22, 15);

Future<void> seed(RecordingDatabase db, String guid, DateTime start, {required int min, int? rpe}) =>
    db.upsertActivity(
      ActivitiesCompanion.insert(
        guid: guid,
        activityType: ActivityType.run,
        startTimestampMs: start.millisecondsSinceEpoch,
        timerTimeMs: Value(min * 60000),
        distanceMeters: const Value(5000),
        isFinished: const Value(true),
        syncState: SyncState.pending,
        rpe: Value(rpe),
      ),
    );

Future<void> pump(WidgetTester tester, RecordingDatabase db, ThemeData theme) async {
  tester.view.physicalSize = const Size(400, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        recordingDatabaseProvider.overrideWithValue(db),
        sessionStoreProvider.overrideWithValue(InMemorySessionStore()),
        statsClockProvider.overrideWithValue(() => now),
      ],
      child: MaterialApp(theme: theme, home: const StatsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final (name, theme) in [('escuro', AppTheme.dark), ('claro', AppTheme.light)]) {
    testWidgets('carga do periodo e por semana no tema $name', (tester) async {
      final db = RecordingDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await seed(db, 'a', DateTime(2026, 10, 20, 7), min: 30, rpe: 5); // 150
      await seed(db, 'b', DateTime(2026, 10, 14, 7), min: 60, rpe: 4); // 240
      await seed(db, 'c', DateTime(2026, 10, 13, 7), min: 60); // sem RPE
      await pump(tester, db, theme);

      final section = find.byKey(const Key('stats_load'));
      await tester.ensureVisible(section);
      expect(find.text('Carga do treino'), findsOneWidget);
      // Periodo padrao: 4 semanas.
      expect(
        find.descendant(of: section, matching: find.text('390')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('stats_load_week_7')), findsOneWidget);
      expect(find.byKey(const Key('stats_load_week_6')), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.byKey(const Key('stats_period_week')));
      await tester.tap(find.byKey(const Key('stats_period_week')));
      await tester.pumpAndSettle();
      expect(find.descendant(of: section, matching: find.text('150')), findsOneWidget);
    });
  }

  testWidgets('sem esforco informado: dica no lugar da carga', (tester) async {
    final db = RecordingDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await seed(db, 'a', DateTime(2026, 10, 20, 7), min: 30);
    await pump(tester, db, AppTheme.dark);
    final empty = find.byKey(const Key('stats_load_empty'));
    await tester.ensureVisible(empty);
    expect(empty, findsOneWidget);
  });
}
