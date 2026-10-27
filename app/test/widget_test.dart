// Widget tests do Inicio (feed): estado vazio convidando a gravar e, com
// atividades, o resumo da semana e os cartoes, no tema escuro e no claro.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/activity/week_summary.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/persistence/recording_repository.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/domain/waypoint.dart' as dom;
import 'package:strava_estudo_app/ui/components/activity_card.dart';
import 'package:strava_estudo_app/ui/components/week_summary_card.dart';
import 'package:strava_estudo_app/ui/home_screen.dart';
import 'package:strava_estudo_app/ui/theme/app_theme.dart';

// Quarta-feira; a corrida semeada cai na segunda desta semana.
final now = DateTime(2026, 10, 28, 12);

dom.Waypoint acc(double lat, double dist, double alt) => dom.Waypoint(
      position: GeoPoint(latitude: lat, longitude: 0, altitudeMeters: alt),
      cumulativeDistanceMeters: dist,
      elapsedTimeMs: 0,
      timerTimeMs: 0,
      classification: dom.WaypointClassification.accept,
      horizontalAccuracyMeters: 5,
      verticalAccuracyMeters: 2,
    );

Future<void> pumpHome(WidgetTester tester, RecordingDatabase db, {ThemeData? theme}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      recordingDatabaseProvider.overrideWithValue(db),
      weekClockProvider.overrideWithValue(() => now),
    ],
    child: MaterialApp(theme: theme ?? AppTheme.dark, home: const HomeScreen()),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Inicio vazio convida a gravar', (tester) async {
    // A Home consulta o banco na abertura (recuperacao pos-crash).
    final db = RecordingDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await pumpHome(tester, db);

    expect(find.text('Atividades'), findsOneWidget);
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.byKey(const Key('settings')), findsOneWidget);
    expect(find.byKey(const Key('home_empty')), findsOneWidget);
    expect(find.text('Nenhuma atividade ainda'), findsOneWidget);
    expect(find.byKey(const Key('home_record')), findsOneWidget);
    // Resumo aparece zerado, sem meta inventada.
    expect(find.byType(WeekSummaryCard), findsOneWidget);
    expect(find.text('Nenhum treino'), findsOneWidget);
    // A escolha do esporte saiu do Inicio.
    expect(find.text('Correr'), findsNothing);
  });

  for (final (name, theme) in [('escuro', AppTheme.dark), ('claro', AppTheme.light)]) {
    testWidgets('Inicio mostra o resumo da semana e o cartao ($name)', (tester) async {
      final db = RecordingDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = RecordingRepository(db);
      final start = DateTime(2026, 10, 26, 7).millisecondsSinceEpoch;
      await repo.startActivity(guid: 'a', type: ActivityType.run, startTimestampMs: start);
      await repo.appendWaypoints('a', [
        acc(0.0, 0, 100),
        acc(0.005, 600, 130),
        acc(0.01, 1200, 160),
      ]);
      await repo.finish('a', start + 360000, distanceMeters: 1200, timerTimeMs: 360000);

      await pumpHome(tester, db, theme: theme);

      expect(find.text('Esta semana'), findsOneWidget);
      expect(find.text('1 treino'), findsOneWidget);
      expect(find.byType(ActivityCard), findsOneWidget);
      expect(find.text('Corrida da manha'), findsOneWidget);
      expect(find.text('Ver detalhe'), findsOneWidget);
      expect(find.byKey(const Key('home_empty')), findsNothing);
      // Distancia aparece no resumo e no cartao.
      expect(find.textContaining('1.20'), findsNWidgets(2));

      await tester.ensureVisible(find.byKey(const Key('share-a')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('share-a')));
      await tester.pump();
      expect(find.text('Em breve'), findsOneWidget);
    });
  }
}
