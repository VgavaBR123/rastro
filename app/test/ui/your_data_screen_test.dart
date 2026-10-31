// Configuracoes > Seus dados (F07): entrada, importar com o seletor trocado
// por caminhos fixos (como no E2E), progresso com semantica, cancelar,
// resumo, exportar tudo pelo compartilhar e exportar GPX pelo detalhe.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/app/router.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/platform/activity_sharer.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/sync/background/background_sync_provider.dart';
import 'package:strava_estudo_app/sync/background/background_sync_scheduler.dart';
import 'package:strava_estudo_app/ui/activity_detail_screen.dart';
import 'package:strava_estudo_app/ui/recording_health_section.dart';
import 'package:strava_estudo_app/ui/settings_screen.dart';
import 'package:strava_estudo_app/ui/theme/app_theme.dart';
import 'package:strava_estudo_app/ui/your_data/your_data_screen.dart';
import 'package:strava_estudo_app/your_data/export_service.dart';
import 'package:strava_estudo_app/your_data/import_feed.dart';
import 'package:strava_estudo_app/your_data/import_file_picker.dart';
import 'package:strava_estudo_app/your_data/your_data_controller.dart';
import 'package:strava_estudo_app/your_data/your_data_providers.dart';

import '../fixtures/fake_sharer.dart';
import '../your_data/fixtures.dart';

/// Fila que so entrega o proximo item quando o teste libera.
class GatedFeed implements ImportFeed {
  final List<ImportStep> steps;
  final List<Completer<void>> gates;
  int i = 0;
  bool closed = false;
  GatedFeed(this.steps) : gates = [for (final _ in steps) Completer<void>()];
  @override
  int get total => steps.length;
  @override
  Future<ImportStep?> next() async {
    if (closed || i >= steps.length) return null;
    await gates[i].future;
    return steps[i++];
  }

  @override
  Future<void> close() async => closed = true;
}

/// Alterna tempo real (arquivos, banco) e quadros ate [done] valer.
Future<void> waitFor(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 400 && !done(); i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    await tester.pump(const Duration(milliseconds: 20));
  }
  expect(done(), isTrue, reason: 'esperou demais');
  await tester.pumpAndSettle();
}

/// Seletor que avisa a copia ("preparando") e espera o teste liberar.
class SlowPicker implements ProgressImportFilePicker {
  final Completer<List<String>> result = Completer();
  bool fail = false;
  @override
  Future<List<String>> pick() => pickWithProgress(() {});
  @override
  Future<List<String>> pickWithProgress(void Function() onPreparing) async {
    onPreparing();
    final r = await result.future;
    if (fail) throw const FileSystemException('sem espaco');
    return r;
  }

  @override
  Future<void> cleanUp() async {}
}

/// Anuncios enviados ao leitor de tela.
List<String> captureAnnouncements(WidgetTester tester) {
  final said = <String>[];
  tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(
    SystemChannels.accessibility,
    (msg) async {
      final m = msg! as Map<Object?, Object?>;
      if (m['type'] == 'announce') said.add((m['data']! as Map<Object?, Object?>)['message']! as String);
      return null;
    },
  );
  addTearDown(() => tester.binding.defaultBinaryMessenger
      .setMockDecodedMessageHandler<Object?>(SystemChannels.accessibility, null));
  return said;
}

void main() {
  late RecordingDatabase db;
  late FakeActivitySharer sharer;
  late Directory dir;

  setUp(() {
    db = RecordingDatabase(NativeDatabase.memory());
    sharer = FakeActivitySharer();
    dir = Directory.systemTemp.createTempSync('rastro_ui_data');
  });
  tearDown(() async {
    await db.close();
    dir.deleteSync(recursive: true);
  });

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    String initial = AppRoutes.yourData,
    List<String> picked = const [],
    ImportFilePicker? picker,
    ImportFeedFactory? feed,
    ThemeData? theme,
  }) async {
    await tester.binding.setSurfaceSize(const Size(500, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(path: AppRoutes.settings, builder: (_, _) => const SettingsScreen()),
        yourDataRoute(),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recordingDatabaseProvider.overrideWithValue(db),
          activitySharerProvider.overrideWithValue(sharer),
          backgroundSyncSchedulerProvider.overrideWithValue(const NoopBackgroundSyncScheduler()),
          importFilePickerProvider.overrideWithValue(picker ?? FixedImportFilePicker(picked)),
          importFeedFactoryProvider.overrideWithValue(feed ?? LocalImportFeed.open),
          exportDirectoryProvider.overrideWithValue(() async => Directory('${dir.path}/export')),
        ],
        child: MaterialApp.router(theme: theme ?? AppTheme.dark, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(tester.element(find.byType(Router<Object>)));
  }

  /// Espera (em tempo real) o controlador sair da fase [phase].
  Future<void> waitWhile(WidgetTester tester, ProviderContainer c, YourDataPhase phase) async {
    await waitFor(tester, () => c.read(yourDataControllerProvider).phase != phase);
  }

  testWidgets('Configuracoes mostra Seus dados e abre a tela', (tester) async {
    await pump(tester, initial: AppRoutes.settings);
    final tile = find.byKey(const Key('your_data'));
    await tester.scrollUntilVisible(tile, 200, scrollable: find.byType(Scrollable).first);
    expect(tester.getSize(tile).height, greaterThanOrEqualTo(44));
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(find.byType(YourDataScreen), findsOneWidget);
    expect(find.byKey(const Key('import_pick')), findsOneWidget);
    expect(find.byKey(const Key('export_all')), findsOneWidget);
  });

  testWidgets('importar ZIP e arquivos soltos mostra o resumo', (tester) async {
    final csv = stravaCsv([
      (id: '1', name: 'Longao', type: 'Run', file: 'activities/1.gpx'),
      (id: '2', name: 'Piscina', type: 'Swim', file: 'activities/2.gpx'),
      (id: '3', name: 'Sumiu', type: 'Ride', file: 'activities/3.fit.gz'),
    ]);
    final zip = zipOf({
      'activities.csv': utf8.encode(csv),
      'activities/1.gpx': utf8.encode(gpxText(points: line(30))),
      'activities/2.gpx': utf8.encode(gpxText(points: line(30, startMs: kT0 + 3600000))),
    });
    final paths = [
      writeTemp(dir, 'export.zip', zip),
      writeTemp(dir, 'pedal.fit', fitBytes(points: line(30, startMs: kT0 + 86400000), sport: 2)),
      // O mesmo GPX do ZIP, solto: duplicata.
      writeTemp(dir, 'repetida.gpx', utf8.encode(gpxText(points: line(30)))),
    ];
    final semantics = tester.ensureSemantics();
    final said = captureAnnouncements(tester);
    final c = await pump(tester, picked: paths);
    await tester.tap(find.byKey(const Key('import_pick')));
    await tester.pump();
    await waitWhile(tester, c, YourDataPhase.importing);

    expect(find.byKey(const Key('import_summary')), findsOneWidget);
    expect(said, contains('Importacao concluida: 2 importadas, 1 com erro'));
    expect(tester.getSemantics(find.text('Importacao concluida')), isSemantics(isHeader: true));
    semantics.dispose();
    expect(find.text('2 importadas'), findsOneWidget);
    expect(find.text('1 duplicada (ja estavam no app)'), findsOneWidget);
    expect(find.text('1 de natacao ignorada'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('import_summary_errors')),
        matching: find.textContaining('activities/3.fit.gz'),
      ),
      findsOneWidget,
    );
    final rows = await db.finishedActivitiesAscending();
    expect(rows.map((a) => a.title), ['Longao', null]);
    expect(rows.map((a) => a.importSource), ['gpx', 'fit']);
    expect(rows.every((a) => a.visibility == 'private'), isTrue);

    await tester.tap(find.byKey(const Key('import_done')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('import_pick')), findsOneWidget);
  });

  testWidgets('progresso com semantica e cancelar mantem o que ja entrou', (tester) async {
    final semantics = tester.ensureSemantics();
    final gpxPath = writeTemp(dir, 'a.gpx', utf8.encode(gpxText(points: line(10))));
    final first = (await tester.runAsync(() async {
      final f = await LocalImportFeed.open([gpxPath]);
      final s = await f.next();
      await f.close();
      return s!;
    }))!;
    final gated = GatedFeed([first, first, first]);
    final c = await pump(tester, picked: ['x'], feed: (_) async => gated);
    await tester.tap(find.byKey(const Key('import_pick')));
    await tester.pump();
    expect(find.byKey(const Key('import_progress')), findsOneWidget);
    expect(find.text('Importando: 0 de 3'), findsOneWidget);
    expect(
      tester.getSemantics(find.byKey(const Key('import_progress')).first),
      isNotNull,
    );
    expect(find.bySemanticsLabel('Importando'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Importando')),
      isSemantics(isLiveRegion: false),
      reason: 'o valor muda a cada item; o anuncio e em degraus',
    );

    gated.gates[0].complete();
    await waitFor(tester, () => c.read(yourDataControllerProvider).done >= 1);
    expect(find.text('Importando: 1 de 3'), findsOneWidget);
    final cancel = find.byKey(const Key('import_cancel'));
    expect(tester.getSize(cancel).height, greaterThanOrEqualTo(44));
    await tester.tap(cancel);
    await tester.pump();
    expect(find.text('Cancelando...'), findsOneWidget);
    gated.gates[1].complete();
    await waitWhile(tester, c, YourDataPhase.importing);
    expect(find.byKey(const Key('import_summary_cancelled')), findsOneWidget);
    expect(gated.closed, isTrue);
    expect(await tester.runAsync(db.finishedActivitiesAscending), hasLength(1));
    semantics.dispose();
  });

  testWidgets('exportar tudo gera o ZIP e abre o compartilhar; privacidade ligada por padrao', (tester) async {
    await tester.runAsync(() => db.upsertActivity(ActivitiesCompanion.insert(
      guid: 'a',
      activityType: ActivityType.walk,
      startTimestampMs: kT0,
      endTimestampMs: Value(kT0 + 60000),
      timerTimeMs: const Value(60000),
      isFinished: const Value(true),
      syncState: SyncState.pending,
    )));
    final c = await pump(tester);
    final privacy = tester.widget<SwitchListTile>(find.byKey(const Key('export_privacy')));
    expect(privacy.value, isTrue);
    await tester.tap(find.byKey(const Key('export_all')));
    await tester.pump();
    await waitWhile(tester, c, YourDataPhase.exporting);
    expect(sharer.files.single.mimeType, 'application/zip');
    expect(sharer.files.single.path, startsWith('${dir.path}/export'));
    expect(File(sharer.files.single.path).existsSync(), isTrue);
  });

  testWidgets('copia do seletor: Preparando os arquivos, e falha sugere falta de espaco', (tester) async {
    final picker = SlowPicker();
    final c = await pump(tester, picker: picker);
    await tester.tap(find.byKey(const Key('import_pick')));
    await tester.pump();
    expect(find.text('Importando: Preparando os arquivos...'), findsOneWidget);
    expect(tester.widget<LinearProgressIndicator>(find.byKey(const Key('import_progress'))).value, isNull);
    picker.fail = true;
    picker.result.complete(const []);
    await waitWhile(tester, c, YourDataPhase.importing);
    expect(find.text('Nao foi possivel abrir os arquivos. Confira se ha espaco livre no aparelho.'), findsOneWidget);
    expect(find.byKey(const Key('import_pick')), findsOneWidget);
  });

  testWidgets('seletor cancelado depois de preparar volta ao inicio', (tester) async {
    final picker = SlowPicker();
    final c = await pump(tester, picker: picker);
    await tester.tap(find.byKey(const Key('import_pick')));
    await tester.pump();
    picker.result.complete(const []);
    await waitWhile(tester, c, YourDataPhase.importing);
    expect(find.byKey(const Key('import_pick')), findsOneWidget);
    expect(find.byKey(const Key('import_summary')), findsNothing);
  });

  testWidgets('exportar anuncia o fim', (tester) async {
    await tester.runAsync(() => db.upsertActivity(ActivitiesCompanion.insert(
      guid: 'a',
      activityType: ActivityType.walk,
      startTimestampMs: kT0,
      isFinished: const Value(true),
      syncState: SyncState.pending,
    )));
    final said = captureAnnouncements(tester);
    final c = await pump(tester);
    await tester.tap(find.byKey(const Key('export_all')));
    await tester.pump();
    await waitWhile(tester, c, YourDataPhase.exporting);
    expect(said, contains('Exportacao concluida'));
  });

  testWidgets('exportar sem atividades avisa', (tester) async {
    final c = await pump(tester);
    await tester.tap(find.byKey(const Key('export_privacy')));
    await tester.pump();
    expect(c.read(yourDataControllerProvider).exportPrivacy, isFalse);
    await tester.tap(find.byKey(const Key('export_all')));
    await tester.pump();
    await waitWhile(tester, c, YourDataPhase.exporting);
    expect(find.text('Nenhuma atividade para exportar'), findsOneWidget);
    expect(sharer.files, isEmpty);
  });

  testWidgets('tema claro tambem monta', (tester) async {
    await pump(tester, theme: AppTheme.light);
    expect(find.byKey(const Key('import_pick')), findsOneWidget);
  });

  group('detalhe', () {
    Future<Activity> seed(String? source) async {
      await db.upsertActivity(ActivitiesCompanion.insert(
        guid: 'imp-1',
        activityType: ActivityType.run,
        startTimestampMs: kT0,
        endTimestampMs: Value(kT0 + 60000),
        timerTimeMs: const Value(60000),
        isFinished: const Value(true),
        syncState: SyncState.pending,
        importSource: Value(source),
      ));
      return (await db.finishedActivitiesAscending()).single;
    }

    Future<void> open(WidgetTester tester, Activity a) async {
      await tester.binding.setSurfaceSize(const Size(600, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(ProviderScope(
        overrides: [
          recordingDatabaseProvider.overrideWithValue(db),
          activitySharerProvider.overrideWithValue(sharer),
          exportDirectoryProvider.overrideWithValue(() async => Directory('${dir.path}/export')),
        ],
        child: MaterialApp(theme: AppTheme.dark, home: ActivityDetailScreen(activity: a)),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('mostra Importada de GPX; gravada no app nao mostra', (tester) async {
      final a = (await tester.runAsync(() => seed('gpx')))!;
      await open(tester, a);
      expect(find.text('Importada de GPX'), findsOneWidget);
      expect(find.byKey(const Key('detailImportSource')), findsOneWidget);
      expect(find.byType(RecordingHealthSection), findsNothing,
          reason: 'importada nao tem saude da gravacao');
    });

    testWidgets('sem origem nao mostra o selo', (tester) async {
      final a = (await tester.runAsync(() => seed(null)))!;
      await open(tester, a);
      expect(find.byKey(const Key('detailImportSource')), findsNothing);
    });

    testWidgets('menu > Exportar GPX com privacidade e compartilhar', (tester) async {
      final a = (await tester.runAsync(() => seed('fit')))!;
      await open(tester, a);
      final menu = find.byKey(const Key('detailMenu'));
      expect(tester.getSize(menu).height, greaterThanOrEqualTo(44));
      await tester.tap(menu);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('detailExportGpx')));
      await tester.pumpAndSettle();
      final sw = tester.widget<SwitchListTile>(find.byKey(const Key('exportGpxPrivacy')));
      expect(sw.value, isTrue);
      await tester.tap(find.byKey(const Key('exportGpxConfirm')));
      await waitFor(tester, () => sharer.files.isNotEmpty);
      expect(sharer.files.single.mimeType, 'application/gpx+xml');
      expect(sharer.files.single.path, endsWith('.gpx'));
    });

    testWidgets('exportar GPX com outra exportacao em andamento avisa', (tester) async {
      final a = (await tester.runAsync(() => seed('fit')))!;
      await open(tester, a);
      await tester.tap(find.byKey(const Key('detailMenu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('detailExportGpx')));
      await tester.pumpAndSettle();
      // Outra exportacao segura a trava enquanto o Exportar e tocado.
      final release = Completer<void>();
      final held = ExportService.runExclusive(() => release.future);
      await tester.tap(find.byKey(const Key('exportGpxConfirm')));
      await waitFor(tester, () => find.text('Ja ha uma exportacao em andamento').evaluate().isNotEmpty);
      expect(sharer.files, isEmpty);
      release.complete();
      await held;
    });
  });
}
