// Plano 5 km (F06): entrada na tela Gravar e tela do plano (aviso de saude,
// Voz do plano, comecar com a semana inicial, proxima sessao, parcial, decisao
// da semana e reiniciar com confirmacao). Nos dois temas.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/app/router.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/plan5k/domain/plan_progress.dart';
import 'package:strava_estudo_app/plan5k/plan_repository.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/source/current_position.dart';
import 'package:strava_estudo_app/ui/plan5k/plan_actions.dart';
import 'package:strava_estudo_app/ui/plan5k/plan_screen.dart';
import 'package:strava_estudo_app/ui/record_setup_screen.dart';
import 'package:strava_estudo_app/ui/theme/app_theme.dart';

import 'record_setup_screen_test.dart' show FakePosition;

const _bh = GeoPoint(latitude: -19.92, longitude: -43.94);

void main() {
  late RecordingDatabase db;
  late PlanRepository repo;

  Future<void> drain(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 15)));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> pump(
    WidgetTester tester, {
    String initial = '/plan5k',
    ThemeData? theme,
    Future<void> Function()? seed,
  }) async {
    db = RecordingDatabase(NativeDatabase.memory());
    addTearDown(() => tester.runAsync(db.close));
    repo = PlanRepository(db);
    await tester.runAsync(() async {
      await db.saveSettings(reliabilityChecklistSeen: true);
      await seed?.call();
    });
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(path: '/record', builder: (_, _) => const RecordSetupScreen()),
        GoRoute(
          path: '/start',
          builder: (_, _) => Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () => startPlanSession(context, ref),
                child: const Text('iniciar sessao'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.plan5k,
          builder: (_, _) => const PlanScreen(),
          routes: [
            GoRoute(path: 'session', builder: (_, _) => const Text('gravando plano')),
          ],
        ),
        reliabilityRoute(),
      ],
    );
    addTearDown(router.dispose);
    final container = ProviderContainer(
      overrides: [
        recordingDatabaseProvider.overrideWithValue(db),
        currentPositionSourceProvider.overrideWithValue(FakePosition(now: _bh) as CurrentPositionSource),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: theme ?? AppTheme.dark, routerConfig: router),
      ),
    );
    await drain(tester);
  }

  Future<void> tapVisible(WidgetTester tester, Key key) async {
    await tester.ensureVisible(find.byKey(key));
    await tester.pump();
    await tester.tap(find.byKey(key));
    await drain(tester);
  }

  String status(WidgetTester tester, int w, int n) =>
      tester.widget<Text>(find.byKey(Key('plan_session_status_${w}_$n'))).data!;

  testWidgets('sem plano: aviso de saude, voz ligada e comecar na semana escolhida', (tester) async {
    await pump(tester);
    expect(find.byKey(const Key('plan_health_notice')), findsOneWidget);
    expect(find.textContaining('Se sentir dor, pare e descanse'), findsOneWidget);
    final voice = find.byKey(const Key('plan_voice_toggle'));
    expect(tester.widget<SwitchListTile>(voice).value, isTrue);
    await tester.tap(voice);
    await drain(tester);
    expect(tester.widget<SwitchListTile>(voice).value, isFalse);
    expect((await tester.runAsync(db.loadSettings))!.plan5kVoice, isFalse);

    expect(find.byKey(const Key('plan_next_card')), findsNothing);
    await tapVisible(tester, const Key('plan_start_week_4'));
    expect(
      tester.widget<Text>(find.byKey(const Key('plan_start_preview'))).data,
      contains('5 x (3 min correndo + 1 min 30 s caminhando)'),
    );
    expect(tester.getSize(find.byKey(const Key('plan_start_week_4'))).height, greaterThanOrEqualTo(44));
    await tapVisible(tester, const Key('plan_begin'));

    final s = await tester.runAsync(repo.loadState);
    expect(s!.started, isTrue);
    expect(s.startWeek, 4);
    expect(find.byKey(const Key('plan_start_card')), findsNothing);
    await tester.scrollUntilVisible(find.byKey(const Key('plan_next_card')), -200);
    expect(find.descendant(of: find.byKey(const Key('plan_next_card')), matching: find.text('Semana 4, sessao 1')), findsOneWidget);
    await tester.scrollUntilVisible(find.byKey(const Key('plan_session_status_3_3')), 200);
    expect(status(tester, 3, 3), 'Pulada');
    await tester.scrollUntilVisible(find.byKey(const Key('plan_session_status_4_1')), 200);
    expect(status(tester, 4, 1), 'Proxima');
  });

  testWidgets('sessao parcial aparece como parcial e continua sendo a proxima', (tester) async {
    await pump(tester, theme: AppTheme.light, seed: () async {
      await repo.saveState(const PlanState(started: true));
      await repo.beginSession(week: 1, number: 1, round: 0, requiredMs: 100, guid: 'g1', nowMs: 1);
      await repo.finishSession('g1', movingMs: 10, status: SessionStatus.partial, nowMs: 2);
    });
    await tester.scrollUntilVisible(find.byKey(const Key('plan_session_status_1_1')), 200);
    expect(status(tester, 1, 1), 'Parcial, fica para a proxima');
    expect(status(tester, 1, 2), 'A fazer');
    expect(tester.takeException(), isNull);
  });

  testWidgets('semana pesada: cartao de decisao; seguir vai para a semana 2', (tester) async {
    await pump(tester, seed: () async {
      await repo.saveState(const PlanState(started: true));
      await db.upsertActivity(ActivitiesCompanion.insert(
        guid: 'pesada',
        activityType: ActivityType.run,
        startTimestampMs: 1,
        syncState: SyncState.pending,
        isFinished: const Value(true),
        rpe: const Value(8),
      ));
      for (var n = 1; n <= 3; n++) {
        final guid = n == 2 ? 'pesada' : 'g$n';
        await repo.beginSession(week: 1, number: n, round: 0, requiredMs: 100, guid: guid, nowMs: n);
        await repo.finishSession(guid, movingMs: 100, status: SessionStatus.done, nowMs: n);
      }
    });
    expect(find.byKey(const Key('plan_week_decision')), findsOneWidget);
    expect(find.byKey(const Key('plan_next_card')), findsNothing);
    await tapVisible(tester, const Key('plan_decision_advance'));
    expect((await tester.runAsync(repo.loadState))!.currentWeek, 2);
    expect(find.byKey(const Key('plan_week_decision')), findsNothing);
    expect(find.descendant(of: find.byKey(const Key('plan_next_card')), matching: find.text('Semana 2, sessao 1')), findsOneWidget);
  });

  testWidgets('semana completa sem esforco alto segue sozinha ao abrir', (tester) async {
    await pump(tester, seed: () async {
      await repo.saveState(const PlanState(started: true));
      for (var n = 1; n <= 3; n++) {
        await repo.beginSession(week: 1, number: n, round: 0, requiredMs: 100, guid: 'g$n', nowMs: n);
        await repo.finishSession('g$n', movingMs: 100, status: SessionStatus.done, nowMs: n);
      }
    });
    expect((await tester.runAsync(repo.loadState))!.currentWeek, 2);
    expect(find.byKey(const Key('plan_week_decision')), findsNothing);
  });

  testWidgets('reiniciar pede confirmacao; cancelar mantem, confirmar zera', (tester) async {
    await pump(tester, seed: () => repo.saveState(const PlanState(started: true, startWeek: 2, currentWeek: 3)));
    await tester.scrollUntilVisible(find.byKey(const Key('plan_restart')), 300);
    await tester.tap(find.byKey(const Key('plan_restart')));
    await drain(tester);
    expect(find.byKey(const Key('plan_restart_dialog')), findsOneWidget);
    await tester.tap(find.byKey(const Key('plan_restart_cancel')));
    await drain(tester);
    expect((await tester.runAsync(repo.loadState))!.started, isTrue);

    await tester.tap(find.byKey(const Key('plan_restart')));
    await drain(tester);
    await tester.tap(find.byKey(const Key('plan_restart_confirm')));
    await drain(tester);
    expect((await tester.runAsync(repo.loadState))!.started, isFalse);
    await tester.scrollUntilVisible(find.byKey(const Key('plan_begin')), -300);
    expect(find.byKey(const Key('plan_begin')), findsOneWidget);
  });

  group('entrada na tela Gravar', () {
    testWidgets('sem plano: leva a tela do plano', (tester) async {
      await pump(tester, initial: '/record');
      expect(
        tester.widget<Text>(find.byKey(const Key('plan_entry_subtitle'))).data,
        'Do zero aos 5 km em 10 semanas',
      );
      expect(find.byKey(const Key('plan_entry_start')), findsNothing);
      expect(tester.getSize(find.byKey(const Key('plan_entry'))).height, greaterThanOrEqualTo(44));
      await tester.tap(find.byKey(const Key('plan_entry')));
      await drain(tester);
      expect(find.byType(PlanScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('com plano: mostra a proxima sessao e grava guiado', (tester) async {
      await pump(tester, initial: '/record', theme: AppTheme.light, seed: () => repo.saveState(const PlanState(started: true)));
      expect(find.text('Plano 5 km: semana 1, sessao 1'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('plan_entry_subtitle'))).data,
        '8 x (1 min correndo + 1 min 30 s caminhando) - 28 min 30 s',
      );
      final start = find.byKey(const Key('plan_entry_start'));
      expect(tester.getSize(start).height, greaterThanOrEqualTo(44));
      await tester.tap(start);
      await drain(tester);
      expect(find.text('gravando plano'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('iniciar sessao sem sessao disponivel: avisa e nao abre a gravacao', (tester) async {
    await pump(tester, initial: '/start');
    await tester.tap(find.text('iniciar sessao'));
    await drain(tester);
    expect(find.text('gravando plano'), findsNothing);
    expect(find.text('Sem sessao do plano agora.'), findsOneWidget);
  });

  testWidgets('depois de Comecar o plano a lista volta ao topo e o Iniciar sessao fica a vista', (tester) async {
    await pump(tester);
    await tapVisible(tester, const Key('plan_begin'));
    await tester.pumpAndSettle();
    final start = find.byKey(const Key('plan_start_next'));
    expect(start, findsOneWidget);
    final r = tester.getRect(start);
    expect(r.top, greaterThanOrEqualTo(0));
    expect(r.bottom, lessThanOrEqualTo(915));
  });
}
