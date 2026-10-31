// Widget test da aba Estatisticas (escuro e claro): totais do periodo, grafico
// de 8 semanas, distribuicao por esporte e troca de periodo. Tambem confere
// os totais da semana e os recordes na aba Voce, que usam o mesmo provider.
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
import 'package:strava_estudo_app/ui/components/metric_tile.dart';
import 'package:strava_estudo_app/ui/profile_screen.dart';
import 'package:strava_estudo_app/ui/stats_screen.dart';
import 'package:strava_estudo_app/ui/theme/app_colors.dart';
import 'package:strava_estudo_app/ui/theme/app_theme.dart';

// Quarta-feira, 22/10/2026.
final now = DateTime(2026, 10, 22, 15);

Future<void> seed(
  RecordingDatabase db,
  String guid,
  ActivityType type,
  DateTime start, {
  required double km,
  required int min,
  bool finished = true,
}) => db.upsertActivity(
  ActivitiesCompanion.insert(
    guid: guid,
    activityType: type,
    startTimestampMs: start.millisecondsSinceEpoch,
    timerTimeMs: Value(min * 60000),
    distanceMeters: Value(km * 1000),
    isFinished: Value(finished),
    syncState: SyncState.pending,
  ),
);

Future<RecordingDatabase> pump(
  WidgetTester tester,
  Widget screen, {
  required ThemeData theme,
  bool withData = true,
}) async {
  // Largura de celular e altura para a tela inteira caber.
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final db = RecordingDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  if (withData) {
    await seed(
      db,
      'r1',
      ActivityType.run,
      DateTime(2026, 10, 20, 7),
      km: 10,
      min: 50,
    );
    await seed(
      db,
      'b1',
      ActivityType.ride,
      DateTime(2026, 10, 1, 9),
      km: 40,
      min: 90,
    );
    await seed(
      db,
      'w1',
      ActivityType.walk,
      DateTime(2026, 9, 2, 18),
      km: 3,
      min: 40,
    );
    // Nao finalizada: fica de fora.
    await seed(
      db,
      'x1',
      ActivityType.run,
      DateTime(2026, 10, 21),
      km: 99,
      min: 99,
      finished: false,
    );
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        recordingDatabaseProvider.overrideWithValue(db),
        sessionStoreProvider.overrideWithValue(InMemorySessionStore()),
        statsClockProvider.overrideWithValue(() => now),
      ],
      child: MaterialApp(theme: theme, home: screen),
    ),
  );
  await tester.pumpAndSettle();
  return db;
}

String tileValue(WidgetTester tester, String key) {
  final tile = tester.widget<MetricTile>(find.byKey(Key(key)));
  return [tile.value, ?tile.unit].join(' ');
}

void main() {
  for (final (name, theme) in [
    ('escuro', AppTheme.dark),
    ('claro', AppTheme.light),
  ]) {
    group('tema $name', () {
      testWidgets('mostra totais, grafico e distribuicao do periodo', (
        tester,
      ) async {
        await pump(tester, const StatsScreen(), theme: theme);

        expect(find.text('Estatisticas'), findsOneWidget);
        // Padrao: 4 semanas (corrida e pedal).
        expect(tileValue(tester, 'stats_total_distance'), '50,00 km');
        expect(tileValue(tester, 'stats_total_time'), '2:20:00');
        expect(tileValue(tester, 'stats_total_count'), '2');
        expect(tileValue(tester, 'stats_total_gain'), '0 m');
        expect(find.byKey(const Key('stats_week_chart')), findsOneWidget);
        expect(find.byKey(const Key('stats_sport_ride')), findsOneWidget);
        expect(find.byKey(const Key('stats_sport_run')), findsOneWidget);
        expect(find.byKey(const Key('stats_sport_walk')), findsNothing);
        expect(find.text('64%'), findsOneWidget); // 90 de 140 min

        // Cores da funcao saem do tema atual.
        final c = theme.extension<AppColors>()!;
        final dist = tester.widget<MetricTile>(
          find.byKey(const Key('stats_total_distance')),
        );
        expect(dist.role.fg, c.dist.fg);
        expect(dist.block, isTrue);

        await tester.tap(find.byKey(const Key('stats_period_week')));
        await tester.pumpAndSettle();
        expect(tileValue(tester, 'stats_total_distance'), '10,00 km');
        expect(tileValue(tester, 'stats_total_count'), '1');
        expect(find.byKey(const Key('stats_sport_ride')), findsNothing);

        await tester.tap(find.byKey(const Key('stats_period_8w')));
        await tester.pumpAndSettle();
        expect(tileValue(tester, 'stats_total_count'), '3');
        await tester.scrollUntilVisible(
          find.byKey(const Key('stats_sport_walk')),
          200,
        );
        expect(find.byKey(const Key('stats_sport_walk')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('sem treinos mostra zeros e o aviso', (tester) async {
        await pump(tester, const StatsScreen(), theme: theme, withData: false);
        expect(tileValue(tester, 'stats_total_count'), '0');
        expect(tileValue(tester, 'stats_total_time'), '0:00');
        expect(find.byKey(const Key('stats_chart_max')), findsOneWidget);
        await tester.scrollUntilVisible(
          find.byKey(const Key('stats_empty')),
          200,
        );
        expect(find.byKey(const Key('stats_empty')), findsOneWidget);
      });

      testWidgets('Voce deslogado: convite, semana e recordes locais', (
        tester,
      ) async {
        await pump(tester, const ProfileScreen(), theme: theme);
        expect(find.byKey(const Key('profile_signin')), findsOneWidget);
        expect(tileValue(tester, 'profile_week_distance'), '10,00 km');
        expect(tileValue(tester, 'profile_week_count'), '1');
        final record = find.byKey(
          const Key('profile_record_ride_longestDistance'),
        );
        await tester.scrollUntilVisible(record, 200);
        expect(find.text('Pedal mais longo'), findsOneWidget);
        expect(find.text('40,00 km'), findsOneWidget);
        expect(
          find.byKey(const Key('profile_record_run_bestPace')),
          findsOneWidget,
        );
        expect(find.text('5:00 /km'), findsOneWidget);
        expect(find.byKey(const Key('profile_settings')), findsOneWidget);
        expect(find.byKey(const Key('profile_logout')), findsNothing);
      });
    });
  }

  test('alturas das fatias sao proporcionais ao maior tempo', () {
    final w = WeekBar(
      start: DateTime(2026, 10, 19),
      timerMsBySport: const {ActivityType.walk: 30, ActivityType.run: 60},
    );
    final segs = WeekBarsPainter.segments(w, 120, 100);
    // Corrida embaixo, depois caminhada (ordem do enum).
    expect(segs, [(ActivityType.run, 50.0), (ActivityType.walk, 25.0)]);
    expect(WeekBarsPainter.segments(w, 0, 100), isEmpty);
  });

  test('iniciais do avatar', () {
    expect(profileInitials('Ana Lima Souza'), 'AS');
    expect(profileInitials('  ana '), 'A');
    expect(profileInitials(''), '?');
  });
}
