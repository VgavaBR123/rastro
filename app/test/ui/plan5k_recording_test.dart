// Plano 5 km (F06) na tela de gravacao: cartao do bloco (rotulo, contagem,
// proximo, progresso e semantica viva), mensagem de sessao parcial no
// fechamento e o dialogo "repetir a semana" depois da 3a sessao pesada.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/closing/closing_service.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/plan5k/domain/plan_progress.dart';
import 'package:strava_estudo_app/plan5k/domain/plan_table.dart';
import 'package:strava_estudo_app/plan5k/guided_session.dart';
import 'package:strava_estudo_app/plan5k/plan_providers.dart';
import 'package:strava_estudo_app/plan5k/plan_repository.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/settings/app_settings.dart';
import 'package:strava_estudo_app/settings/settings_controller.dart';
import 'package:strava_estudo_app/ui/recording_screen.dart';
import 'package:strava_estudo_app/ui/theme/app_theme.dart';

import '../fixtures/sample_route.dart';
import '../recording/fakes.dart';

const s = 1000;
const block = [
  PlanBlock(BlockKind.warmup, 30 * s),
  PlanBlock(BlockKind.run, 30 * s),
  PlanBlock(BlockKind.walk, 30 * s),
  PlanBlock(BlockKind.run, 30 * s),
  PlanBlock(BlockKind.cooldown, 30 * s),
];
final table = [
  for (var w = 1; w <= kPlanWeeks; w++)
    for (var n = 1; n <= kSessionsPerWeek; n++) PlanSession(week: w, number: n, blocks: block),
];

class _FixedSettings extends SettingsController {
  _FixedSettings(super.db, AppSettings s) {
    state = s;
  }
  @override
  Future<void> load() async {}
}

class _FakeClosing extends ClosingService {
  _FakeClosing(super.repo);
  @override
  Future<List<String>> phrasesFor(String guid, {required bool gentle, required bool metric}) async =>
      const ['Frase um.'];
}

class _NoHaptics implements PlanHaptics {
  @override
  Future<void> blockChange() async {}
  @override
  Future<void> warning() async {}
}

void main() {
  late RecordingDatabase db;
  late FakeLocationSource source;
  late FakeHeartbeatTicker ticker;
  var nowMs = 0;

  Future<void> drain(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
  }

  Future<void> hold(WidgetTester tester, Finder f) async {
    final g = await tester.startGesture(tester.getCenter(f));
    for (var i = 0; i < 16; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await g.up();
    await tester.pump();
  }

  Future<void> tick(WidgetTester tester, int seconds) async {
    nowMs += seconds * s;
    ticker.tick();
    await drain(tester);
  }

  Future<void> tapVisible(WidgetTester tester, Key key) async {
    await tester.ensureVisible(find.byKey(key));
    await tester.pump();
    await tester.tap(find.byKey(key));
    await tester.pump();
  }

  Future<void> pump(
    WidgetTester tester, {
    ThemeData? theme,
    Future<void> Function(PlanRepository repo)? seed,
  }) async {
    db = RecordingDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    source = FakeLocationSource();
    ticker = FakeHeartbeatTicker();
    nowMs = 0;
    final planRepo = PlanRepository(db);
    await tester.runAsync(() async {
      await planRepo.saveState(const PlanState(started: true));
      await seed?.call(planRepo);
    });
    tester.view.physicalSize = const Size(420, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationSourceProvider.overrideWithValue(source),
          recordingDatabaseProvider.overrideWithValue(db),
          settingsProvider.overrideWith((ref) => _FixedSettings(db, const AppSettings())),
          closingServiceProvider.overrideWith((ref) => _FakeClosing(ref.watch(recordingRepositoryProvider))),
          plan5kTableProvider.overrideWithValue(table),
          planTickerProvider.overrideWithValue(ticker),
          planMonotonicNowProvider.overrideWithValue(() => nowMs),
          planHapticsProvider.overrideWithValue(_NoHaptics()),
        ],
        child: MaterialApp(
          theme: theme ?? AppTheme.dark,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const RecordingScreen(activityType: ActivityType.run, guided: true),
                  ),
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await drain(tester);
    for (final p in sampleRoute().take(3)) {
      source.add(p);
    }
    await drain(tester);
  }

  Future<void> saveWith(WidgetTester tester, {String? rpeKey}) async {
    await tester.tap(find.byKey(const Key('pause')));
    await drain(tester);
    await hold(tester, find.byKey(const Key('stop')));
    if (rpeKey != null) await tapVisible(tester, Key(rpeKey));
    await tapVisible(tester, const Key('save_activity'));
    await drain(tester);
  }

  String textOf(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

  testWidgets('cartao do bloco: aquecimento, troca para correr, proximo e progresso', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    expect(find.byKey(const Key('plan_block_card')), findsOneWidget);
    expect(textOf(tester, const Key('plan_block_label')), 'Aquecer caminhando');
    expect(textOf(tester, const Key('plan_block_countdown')), '0:30');
    expect(textOf(tester, const Key('plan_block_next')), 'A seguir: Correr 30 s');

    await tick(tester, 12);
    expect(textOf(tester, const Key('plan_block_countdown')), '0:18');
    await tick(tester, 18);
    expect(textOf(tester, const Key('plan_block_label')), 'Correr');
    expect(textOf(tester, const Key('plan_block_next')), 'A seguir: Caminhar 30 s');
    // A troca fechou uma volta da gravacao.
    expect(find.text('Volta 2'), findsOneWidget);

    // Leitor de tela: o cabecalho e regiao viva com o bloco atual.
    final header = tester.getSemantics(find.byKey(const Key('plan_block_header')));
    expect(header, isSemantics(label: 'Correr. Bloco 2 de 5', isLiveRegion: true));
    final progress = tester.widget<LinearProgressIndicator>(find.byKey(const Key('plan_session_progress')));
    expect(progress.value, closeTo(30 / 150, 1e-9));
    handle.dispose();
  });

  testWidgets('pausado: o cartao mostra Pausado e a contagem para', (tester) async {
    await pump(tester, theme: AppTheme.light);
    await tester.tap(find.byKey(const Key('pause')));
    await drain(tester);
    await tick(tester, 20);
    expect(textOf(tester, const Key('plan_block_countdown')), '0:30');
    expect(find.descendant(of: find.byKey(const Key('plan_block_card')), matching: find.text('Pausado')), findsOneWidget);
  });

  testWidgets('encerrar no meio: fechamento diz que a sessao parcial fica para a proxima', (tester) async {
    await pump(tester);
    await tick(tester, 40);
    await saveWith(tester);
    expect(find.byKey(const Key('closing_view')), findsOneWidget);
    expect(find.text('Sessao parcial salva. Ela fica para a proxima vez.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('closing_done')));
    await drain(tester);
    expect(find.byType(RecordingScreen), findsNothing);
    expect(find.byKey(const Key('plan_repeat_dialog')), findsNothing);
  });

  testWidgets('3a sessao concluida com RPE 9: pergunta se repete a semana (padrao Repetir)', (tester) async {
    await pump(tester, seed: (repo) async {
      for (var n = 1; n <= 2; n++) {
        await repo.beginSession(week: 1, number: n, round: 0, plannedMs: 150 * s, guid: 'old_$n', nowMs: n);
        await repo.finishSession('old_$n', movingMs: 150 * s, status: SessionStatus.done, nowMs: n);
      }
    });
    await tick(tester, 160);
    expect(textOf(tester, const Key('plan_block_label')), 'Plano de hoje concluido');
    await saveWith(tester, rpeKey: 'rpe_9');
    expect(find.text('Sessao 3 da semana 1 do plano concluida.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('closing_done')));
    await drain(tester);
    expect(find.byKey(const Key('plan_repeat_dialog')), findsOneWidget);
    expect(find.text('Seguir para a semana 2'), findsOneWidget);
    expect(tester.getSize(find.byKey(const Key('plan_repeat_week'))).height, greaterThanOrEqualTo(44));
    await tester.tap(find.byKey(const Key('plan_repeat_week')));
    await drain(tester);
    expect(find.byType(RecordingScreen), findsNothing);
    final state = await tester.runAsync(() => PlanRepository(db).loadState());
    expect(state!.currentWeek, 1);
    expect(state.repeatsOf(1), 1);
  });

  testWidgets('3a sessao concluida sem RPE: segue sozinho para a semana 2', (tester) async {
    await pump(tester, seed: (repo) async {
      for (var n = 1; n <= 2; n++) {
        await repo.beginSession(week: 1, number: n, round: 0, plannedMs: 150 * s, guid: 'old_$n', nowMs: n);
        await repo.finishSession('old_$n', movingMs: 150 * s, status: SessionStatus.done, nowMs: n);
      }
    });
    await tick(tester, 160);
    await saveWith(tester);
    await tester.tap(find.byKey(const Key('closing_done')));
    await drain(tester);
    expect(find.byKey(const Key('plan_repeat_dialog')), findsNothing);
    final state = await tester.runAsync(() => PlanRepository(db).loadState());
    expect(state!.currentWeek, 2);
  });
}
