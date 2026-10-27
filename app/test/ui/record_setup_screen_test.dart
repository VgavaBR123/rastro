// Tela Gravar: esporte marcado pelo ultimo usado (ou Corrida), troca pelo
// seletor e Iniciar abre a gravacao do esporte escolhido. Renderiza nos dois
// temas (o mapa nativo nao existe no host: cai no RoutePreview).
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/persistence/recording_repository.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/ui/components/segmented_selector.dart';
import 'package:strava_estudo_app/ui/record_setup_screen.dart';
import 'package:strava_estudo_app/ui/route_preview.dart';
import 'package:strava_estudo_app/ui/theme/app_theme.dart';

Future<void> pumpSetup(
  WidgetTester tester, {
  required RecordingDatabase db,
  ThemeData? theme,
}) async {
  final router = GoRouter(
    initialLocation: '/record',
    routes: [
      GoRoute(
        path: '/record',
        builder: (_, _) => const RecordSetupScreen(),
        routes: [
          GoRoute(
            path: ':type',
            builder: (_, state) => Text('gravando ${state.pathParameters['type']}'),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [recordingDatabaseProvider.overrideWithValue(db)],
      child: MaterialApp.router(theme: theme ?? AppTheme.dark, routerConfig: router),
    ),
  );
  // O historico vem do banco em memoria.
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pump();
  }
}

bool selected(WidgetTester tester, ActivityType t) {
  final sel = tester.widget<SegmentedSelector<ActivityType>>(
    find.byType(SegmentedSelector<ActivityType>),
  );
  return sel.selected == t;
}

void main() {
  testWidgets('sem historico marca Corrida; trocar e Iniciar abre o esporte', (tester) async {
    final db = RecordingDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await pumpSetup(tester, db: db);

    expect(find.byType(RoutePreview), findsOneWidget);
    expect(find.byKey(const Key('gps_chip')), findsOneWidget);
    expect(find.byKey(const Key('map_layers')), findsOneWidget);
    expect(selected(tester, ActivityType.run), isTrue);

    await tester.tap(find.byKey(const Key('sport_ride')));
    await tester.pump();
    expect(selected(tester, ActivityType.ride), isTrue);

    await tester.tap(find.byKey(const Key('record_start')));
    await tester.pumpAndSettle();
    expect(find.text('gravando ride'), findsOneWidget);
  });

  testWidgets('o ultimo esporte usado vem marcado', (tester) async {
    final db = RecordingDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = RecordingRepository(db);
    await tester.runAsync(() async {
      await repo.startActivity(guid: 'a1', type: ActivityType.walk, startTimestampMs: 1000);
      await repo.finish('a1', 2000, distanceMeters: 100, timerTimeMs: 1000);
    });
    await pumpSetup(tester, db: db);

    expect(selected(tester, ActivityType.walk), isTrue);
    expect(find.text('Ultimo usado: Caminhada'), findsOneWidget);
    await tester.tap(find.byKey(const Key('record_start')));
    await tester.pumpAndSettle();
    expect(find.text('gravando walk'), findsOneWidget);
  });

  for (final (nome, tema) in [('escuro', AppTheme.dark), ('claro', AppTheme.light)]) {
    testWidgets('renderiza no tema $nome', (tester) async {
      final db = RecordingDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await pumpSetup(tester, db: db, theme: tema);
      expect(find.byKey(const Key('record_setup_sheet')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
