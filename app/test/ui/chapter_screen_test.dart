// Capitulo (F05) na tela: paginas estilo story (avancar, voltar, fechar),
// privacidade (nunca mapa, rota, horario, titulo ou descricao), Modo Gentil
// (sem pace), compartilhar a imagem, alvos de toque, leitor de tela e os dois
// temas.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/auth/session_store.dart';
import 'package:strava_estudo_app/chapters/chapter_providers.dart';
import 'package:strava_estudo_app/chapters/domain/period.dart';
import 'package:strava_estudo_app/core/format/activity_labels.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/persistence/recording_repository.dart';
import 'package:strava_estudo_app/platform/activity_sharer.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/domain/waypoint.dart' as dom;
import 'package:strava_estudo_app/ui/chapters/chapter_screen.dart';
import 'package:strava_estudo_app/ui/chapters/chapter_share_card.dart';
import 'package:strava_estudo_app/ui/route_map.dart';
import 'package:strava_estudo_app/ui/route_preview.dart';
import 'package:strava_estudo_app/ui/share/share_activity_screen.dart';
import 'package:strava_estudo_app/ui/theme/app_theme.dart';

import '../fixtures/fake_sharer.dart';

const String kTitle = 'Saida de casa na Rua das Flores';
const String kDescription = 'Portao azul, perto da padaria';

final now = DateTime(2026, 11, 2, 9);

/// Atividade finalizada com trajeto, titulo e descricao (o que nao pode vazar).
Future<int> seed(
  RecordingRepository repo,
  String guid,
  DateTime start, {
  ActivityType type = ActivityType.run,
  double meters = 10500,
  int seconds = 3720,
}) async {
  final startMs = start.millisecondsSinceEpoch;
  await repo.startActivity(guid: guid, type: type, startTimestampMs: startMs);
  await repo.appendWaypoints(guid, [
    for (var i = 0; i <= 10; i++)
      dom.Waypoint(
        position: GeoPoint(latitude: -23.55 + i * 0.001, longitude: -46.63),
        cumulativeDistanceMeters: meters * i / 10,
        elapsedTimeMs: seconds * 100 * i,
        timerTimeMs: seconds * 100 * i,
        classification: dom.WaypointClassification.accept,
      ),
  ]);
  await repo.finish(guid, startMs + seconds * 1000, distanceMeters: meters, timerTimeMs: seconds * 1000);
  await repo.saveDetails(guid, title: kTitle, description: kDescription);
  return startMs;
}

Future<({RecordingDatabase db, FakeActivitySharer sharer, List<int> starts})> setUpDb(
  WidgetTester tester, {
  bool gentle = false,
  bool metric = true,
}) async {
  final db = RecordingDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final repo = RecordingRepository(db);
  final starts = <int>[];
  await tester.runAsync(() async {
    starts.add(await seed(repo, 'set', DateTime(2026, 9, 3, 6, 40)));
    starts.add(await seed(repo, 'a', DateTime(2026, 10, 3, 7, 15)));
    starts.add(await seed(repo, 'b', DateTime(2026, 10, 10, 18, 5), type: ActivityType.ride, meters: 25000, seconds: 4200));
    starts.add(await seed(repo, 'c', DateTime(2026, 10, 17, 6, 50), meters: 5000, seconds: 1800));
    await db.saveSettings(gentleMode: gentle, useMetric: metric);
  });
  return (db: db, sharer: FakeActivitySharer(), starts: starts);
}

Future<void> pumpChapter(
  WidgetTester tester,
  RecordingDatabase db,
  FakeActivitySharer sharer, {
  ChapterSource source = const ChapterSource.month(MonthKey(2026, 10)),
  ThemeData? theme,
  List<Override> extra = const [],
}) async {
  await tester.binding.setSurfaceSize(const Size(420, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final dir = Directory.systemTemp.createTempSync('chapter_share');
  addTearDown(() => dir.deleteSync(recursive: true));
  await tester.pumpWidget(ProviderScope(
    overrides: [
      recordingDatabaseProvider.overrideWithValue(db),
      sessionStoreProvider.overrideWithValue(InMemorySessionStore()),
      chapterClockProvider.overrideWithValue(() => now),
      activitySharerProvider.overrideWithValue(sharer),
      shareImageDirectoryProvider.overrideWithValue(() async => dir),
      ...extra,
    ],
    child: MaterialApp(
      theme: theme ?? AppTheme.dark,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              key: const Key('open'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => ChapterScreen(source: source)),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.byKey(const Key('open')));
  await tester.pumpAndSettle();
}

/// Todos os textos visiveis na tela.
String visibleText(WidgetTester tester) => [
  for (final t in tester.widgetList<Text>(find.byType(Text))) t.data ?? t.textSpan?.toPlainText() ?? '',
  for (final t in tester.widgetList<RichText>(find.byType(RichText))) t.text.toPlainText(),
].join('\n');

/// Percorre as paginas ate a ultima, devolvendo os textos de cada uma.
Future<List<String>> walkPages(WidgetTester tester) async {
  final out = <String>[visibleText(tester)];
  while (find.byKey(const Key('chapter_next')).evaluate().isNotEmpty) {
    await tester.tap(find.byKey(const Key('chapter_next')));
    await tester.pumpAndSettle();
    out.add(visibleText(tester));
  }
  return out;
}

void expectNoPrivateData(WidgetTester tester, String text, List<int> starts) {
  expect(find.byType(RoutePreview), findsNothing);
  expect(find.byType(RouteMap), findsNothing);
  expect(text, isNot(contains('Flores')));
  expect(text, isNot(contains('Portao')));
  expect(text, isNot(contains('padaria')));
  for (final ms in starts) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    final hm = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    expect(text, isNot(contains(hm)), reason: 'horario $hm');
    expect(text, isNot(contains(formatDateTimeMs(ms))));
  }
  // Titulo sugerido pelo horario tambem nao aparece.
  expect(text, isNot(contains('da manha')));
  expect(text, isNot(contains('da tarde')));
}

void main() {
  testWidgets('paginas: avancar, voltar, tocar nas laterais e fechar', (tester) async {
    final s = await setUpDb(tester);
    await pumpChapter(tester, s.db, s.sharer);

    expect(find.byKey(const Key('chapter_screen')), findsOneWidget);
    expect(find.byKey(const Key('chapter_page_opening')), findsOneWidget);
    expect(find.text('Outubro'), findsOneWidget);
    expect(find.byKey(const Key('chapter_prev')), findsNothing);

    await tester.tap(find.byKey(const Key('chapter_next')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chapter_page_totals')), findsOneWidget);

    await tester.tap(find.byKey(const Key('chapter_prev')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chapter_page_opening')), findsOneWidget);

    // Toque no lado direito avanca; no esquerdo, recua.
    final area = tester.getRect(find.byKey(const Key('chapter_tap_area')));
    await tester.tapAt(Offset(area.right - 20, area.center.dy));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chapter_page_totals')), findsOneWidget);
    await tester.tapAt(Offset(area.left + 20, area.center.dy));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chapter_page_opening')), findsOneWidget);

    final pages = await walkPages(tester);
    expect(pages.length, inInclusiveRange(4, 6));
    expect(find.byKey(const Key('chapter_page_closing')), findsOneWidget);
    expect(find.byKey(const Key('chapter_share')), findsOneWidget);

    await tester.tap(find.byKey(const Key('chapter_close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chapter_screen')), findsNothing);
  });

  testWidgets('privacidade: nenhuma pagina nem a imagem mostra mapa, horario, titulo ou descricao', (tester) async {
    final s = await setUpDb(tester);
    await pumpChapter(tester, s.db, s.sharer);
    for (final text in await walkPages(tester)) {
      expectNoPrivateData(tester, text, s.starts);
    }
    await tester.tap(find.byKey(const Key('chapter_share')));
    await tester.pumpAndSettle();
    expect(find.byType(ChapterShareCard), findsOneWidget);
    expectNoPrivateData(tester, visibleText(tester), s.starts);
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('chapter_share_image')));
      // Captura e escrita do arquivo sao assincronas de verdade.
      for (var i = 0; i < 50 && s.sharer.images.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await tester.pump();
      }
    });
    await tester.pump();
    expect(s.sharer.images, hasLength(1));
    expect(s.sharer.images.single.path, endsWith('capitulo-202610.png'));
    final text = s.sharer.images.single.text!;
    expect(text, isNot(contains('Flores')));
    expect(text, contains('outubro de 2026'));
  });

  testWidgets('capitulo do ano tambem nao mostra dados privados', (tester) async {
    final s = await setUpDb(tester);
    await pumpChapter(tester, s.db, s.sharer, source: const ChapterSource.year(2026));
    expect(find.text('2026'), findsWidgets);
    for (final text in await walkPages(tester)) {
      expectNoPrivateData(tester, text, s.starts);
    }
    expect(find.byKey(const Key('chapter_page_closing')), findsOneWidget);
  });

  testWidgets('Modo Gentil: nada de pace, velocidade ou rapidez, nem na imagem', (tester) async {
    final s = await setUpDb(tester, gentle: true);
    await pumpChapter(tester, s.db, s.sharer);
    final all = (await walkPages(tester)).join('\n').toLowerCase();
    for (final banned in ['pace', 'ritmo', 'velocidade', 'rapid', '/km', 'km/h']) {
      expect(all, isNot(contains(banned)), reason: banned);
    }
    await tester.tap(find.byKey(const Key('chapter_share')));
    await tester.pumpAndSettle();
    final card = visibleText(tester).toLowerCase();
    expect(card, isNot(contains('pace')));
    expect(card, isNot(contains('/km')));
  });

  testWidgets('fora do Modo Gentil mostra o pace medio das corridas', (tester) async {
    final s = await setUpDb(tester);
    await pumpChapter(tester, s.db, s.sharer);
    await tester.tap(find.byKey(const Key('chapter_next')));
    await tester.pumpAndSettle();
    expect(find.text('Pace medio da corrida'), findsOneWidget);
  });

  testWidgets('imagem em milhas quando a configuracao e imperial, com marca Rastro', (tester) async {
    final s = await setUpDb(tester, metric: false);
    await pumpChapter(tester, s.db, s.sharer);
    await walkPages(tester);
    await tester.tap(find.byKey(const Key('chapter_share')));
    await tester.pumpAndSettle();
    final card = find.byType(ChapterShareCard);
    expect(find.descendant(of: card, matching: find.textContaining(' mi')), findsWidgets);
    expect(find.descendant(of: card, matching: find.text('Rastro')), findsOneWidget);
    // Outubro: primeiro pedal e primeiro pedal de 20 km (12.4 mi).
    expect(find.descendant(of: card, matching: find.byKey(const Key('chapter_share_milestone'))), findsNWidgets(2));
    expect(find.descendant(of: card, matching: find.text('Primeiro pedal de 12.4 mi')), findsOneWidget);
  });

  testWidgets('abrir o capitulo do mes marca como visto', (tester) async {
    final s = await setUpDb(tester);
    await pumpChapter(tester, s.db, s.sharer);
    final seen = await tester.runAsync(() => s.db.chapterMonthSeen());
    expect(seen, 202610);
  });

  testWidgets('mes sem atividade: capitulo curto e gentil', (tester) async {
    final s = await setUpDb(tester);
    await pumpChapter(tester, s.db, s.sharer, source: const ChapterSource.month(MonthKey(2026, 8)));
    expect(find.text('Agosto foi de descanso. Setembro comeca agora.'), findsOneWidget);
    final pages = await walkPages(tester);
    expect(pages, hasLength(2));
    expect(find.byKey(const Key('chapter_share')), findsOneWidget);
  });

  for (final (name, theme) in [('escuro', AppTheme.dark), ('claro', AppTheme.light)]) {
    testWidgets('acessibilidade no tema $name: alvos de 44 px e rotulo de cada pagina', (tester) async {
      final handle = tester.ensureSemantics();
      final s = await setUpDb(tester);
      await pumpChapter(tester, s.db, s.sharer, theme: theme);
      for (final key in ['chapter_next', 'chapter_close']) {
        final size = tester.getSize(find.byKey(Key(key)));
        expect(size.width, greaterThanOrEqualTo(44), reason: key);
        expect(size.height, greaterThanOrEqualTo(44), reason: key);
      }
      expect(find.bySemanticsLabel(RegExp('^Outubro')), findsOneWidget);
      await tester.tap(find.byKey(const Key('chapter_next')));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(RegExp('Distancia: 40.50 km')), findsOneWidget);
      final prev = tester.getSize(find.byKey(const Key('chapter_prev')));
      expect(prev.height, greaterThanOrEqualTo(44));
      await walkPages(tester);
      final share = tester.getSize(find.byKey(const Key('chapter_share')));
      expect(share.height, greaterThanOrEqualTo(44));
      expect(tester.takeException(), isNull);
      handle.dispose();
    });
  }

  testWidgets('capitulo que falha ao montar nao conta como visto', (tester) async {
    final s = await setUpDb(tester);
    await pumpChapter(tester, s.db, s.sharer, extra: [
      monthChapterProvider.overrideWith((ref, month) async => throw StateError('falhou')),
    ]);
    expect(find.byKey(const Key('chapter_error')), findsOneWidget);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    expect(await tester.runAsync(() => s.db.chapterMonthSeen()), isNull);
  });
}
