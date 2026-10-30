// Entradas dos capitulos (F05): cartao no Inicio a partir do dia 1 do mes
// seguinte (abrir ou dispensar o faz sumir) e a lista "Capitulos" com o
// resumo da sequencia na aba Estatisticas. Pelo roteador real do app.
import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/activity/stats_summary.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/app/router.dart';
import 'package:strava_estudo_app/auth/session_store.dart';
import 'package:strava_estudo_app/chapters/chapter_providers.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/recording/domain/location_sample.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/source/location_source.dart';
import 'package:strava_estudo_app/ui/theme/app_theme.dart';

class _FakeSource implements LocationSource {
  final _c = StreamController<LocationSample>();
  @override
  Future<bool> ensurePermission() async => true;
  @override
  Stream<LocationSample> positions() => _c.stream;
  @override
  Future<void> stop() async => _c.close();
}

var now = DateTime(2026, 11, 2, 9);

Future<void> seed(RecordingDatabase db, String guid, DateTime start) => db.upsertActivity(
  ActivitiesCompanion.insert(
    guid: guid,
    activityType: ActivityType.run,
    startTimestampMs: start.millisecondsSinceEpoch,
    timerTimeMs: const Value(1800000),
    distanceMeters: const Value(5000),
    isFinished: const Value(true),
    syncState: SyncState.pending,
  ),
);

void main() {
  late RecordingDatabase db;
  setUp(() {
    db = RecordingDatabase(NativeDatabase.memory());
    now = DateTime(2026, 11, 2, 9);
  });
  tearDown(() => db.close());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  Future<void> pumpApp(WidgetTester tester, {ThemeData? theme, String initial = AppRoutes.home}) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1.5;
    addTearDown(tester.view.reset);
    final router = buildAppRouter(initialLocation: initial);
    addTearDown(router.dispose);
    final container = ProviderContainer(overrides: [
      recordingDatabaseProvider.overrideWithValue(db),
      locationSourceProvider.overrideWithValue(_FakeSource()),
      sessionStoreProvider.overrideWithValue(InMemorySessionStore()),
      chapterClockProvider.overrideWithValue(() => now),
      statsClockProvider.overrideWithValue(() => now),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: theme ?? AppTheme.dark, routerConfig: router),
    ));
    await settle(tester);
  }

  for (final (nome, tema) in [('escuro', AppTheme.dark), ('claro', AppTheme.light)]) {
    testWidgets('cartao do Inicio abre o capitulo e some depois ($nome)', (tester) async {
      await tester.runAsync(() => seed(db, 'a', DateTime(2026, 10, 5, 7)));
      await pumpApp(tester, theme: tema);

      final card = find.byKey(const Key('home_chapter_card'));
      expect(card, findsOneWidget);
      expect(find.text('Seu capitulo de outubro esta pronto'), findsOneWidget);
      final open = tester.getSize(find.byKey(const Key('home_chapter_open')));
      expect(open.height, greaterThanOrEqualTo(44));

      await tester.tap(find.byKey(const Key('home_chapter_open')));
      await settle(tester);
      expect(find.byKey(const Key('chapter_screen')), findsOneWidget);
      expect(find.byKey(const Key('chapter_page_opening')), findsOneWidget);

      await tester.tap(find.byKey(const Key('chapter_close')));
      await settle(tester);
      expect(find.byKey(const Key('chapter_screen')), findsNothing);
      expect(find.byKey(const Key('home_chapter_card')), findsNothing);
      expect(await tester.runAsync(db.chapterMonthSeen), 202610);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('dispensar o cartao guarda no banco e ele nao volta', (tester) async {
    await tester.runAsync(() => seed(db, 'a', DateTime(2026, 10, 5, 7)));
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('home_chapter_dismiss')));
    await settle(tester);
    expect(find.byKey(const Key('home_chapter_card')), findsNothing);
    expect(await tester.runAsync(db.chapterMonthSeen), 202610);
  });

  testWidgets('app novo (so atividade deste mes): sem cartao', (tester) async {
    await tester.runAsync(() => seed(db, 'a', DateTime(2026, 11, 1, 7)));
    await pumpApp(tester);
    expect(find.byKey(const Key('home_chapter_card')), findsNothing);
  });

  testWidgets('mes vazio com historico: cartao gentil', (tester) async {
    await tester.runAsync(() => seed(db, 'a', DateTime(2026, 8, 5, 7)));
    await pumpApp(tester);
    expect(find.text('Seu capitulo de outubro esta pronto'), findsOneWidget);
  });

  for (final (nome, tema) in [('escuro', AppTheme.dark), ('claro', AppTheme.light)]) {
    testWidgets('lista de capitulos e sequencia nas Estatisticas ($nome)', (tester) async {
      await tester.runAsync(() async {
        await seed(db, 'a', DateTime(2026, 10, 21, 7));
        await seed(db, 'b', DateTime(2026, 10, 28, 7));
        await seed(db, 'c', DateTime(2025, 6, 3, 7));
      });
      await pumpApp(tester, theme: tema, initial: AppRoutes.stats);

      final streak = find.byKey(const Key('stats_streak'));
      await tester.ensureVisible(streak);
      expect(find.descendant(of: streak, matching: find.text('2 semanas')), findsOneWidget);
      expect(find.descendant(of: streak, matching: find.textContaining('Coringa de novembro')), findsOneWidget);

      expect(find.byKey(const Key('stats_chapters')), findsOneWidget);
      expect(find.byKey(const Key('chapter_item_year_2026')), findsOneWidget);
      expect(find.byKey(const Key('chapter_item_year_2025')), findsOneWidget);
      expect(find.byKey(const Key('chapter_item_month_202610')), findsOneWidget);
      expect(find.byKey(const Key('chapter_item_month_202506')), findsOneWidget);
      // Mes corrente ainda nao fechado.
      expect(find.byKey(const Key('chapter_item_month_202611')), findsNothing);
      expect(find.text('2026 ate agora'), findsOneWidget);

      final item = find.byKey(const Key('chapter_item_year_2026'));
      await tester.ensureVisible(item);
      expect(tester.getSize(item).height, greaterThanOrEqualTo(44));
      await tester.tap(item);
      await settle(tester);
      expect(find.byKey(const Key('chapter_screen')), findsOneWidget);
      expect(find.text('Seu ano ate agora.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('lista: abrir um mes pela lista', (tester) async {
    await tester.runAsync(() => seed(db, 'c', DateTime(2025, 6, 3, 7)));
    await pumpApp(tester, initial: AppRoutes.stats);
    final item = find.byKey(const Key('chapter_item_month_202506'));
    await tester.ensureVisible(item);
    await tester.tap(item);
    await settle(tester);
    expect(find.text('Junho'), findsOneWidget);
    // Mes antigo pela lista nao esconde o cartao de outubro (so avanca).
    expect(await tester.runAsync(db.chapterMonthSeen), 202506);
  });

  testWidgets('app aberto em 31/10 volta do segundo plano em 1/11: cartao aparece', (tester) async {
    await tester.runAsync(() => seed(db, 'a', DateTime(2026, 10, 5, 7)));
    now = DateTime(2026, 10, 31, 23, 50);
    await pumpApp(tester);
    expect(find.byKey(const Key('home_chapter_card')), findsNothing);

    now = DateTime(2026, 11, 1, 8);
    // Segundo plano e volta, passando pelos estados intermediarios como o
    // sistema faz.
    for (final st in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(st);
    }
    await settle(tester);
    expect(find.byKey(const Key('home_chapter_card')), findsOneWidget);
    expect(find.text('Seu capitulo de outubro esta pronto'), findsOneWidget);
  });
}
