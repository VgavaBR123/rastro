// RecordingScreen: Salvar persiste titulo/descricao/visibilidade, chips do topo
// sem transbordar em tela estreita e botoes durante a pausa automatica.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/persistence/recording_repository.dart';
import 'package:strava_estudo_app/privacy/domain/routine.dart';
import 'package:strava_estudo_app/privacy/privacy_providers.dart';
import 'package:strava_estudo_app/privacy/privacy_repository.dart';
import 'package:strava_estudo_app/recording/domain/waypoint.dart' as dom;
import 'package:strava_estudo_app/recording/domain/auto_pause.dart';
import 'package:strava_estudo_app/recording/domain/location_sample.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/presentation/recording_controller.dart';
import 'package:strava_estudo_app/recording/service/recording_service.dart';
import 'package:strava_estudo_app/ui/recording_screen.dart';
import 'package:strava_estudo_app/ui/theme/app_theme.dart';

import '../fixtures/sample_route.dart';
import '../recording/fakes.dart';

/// Pausa automatica controlada pelo teste.
class _SwitchAutoPause implements AutoPauseDetector {
  bool paused = false;
  @override
  bool shouldBePaused(LocationSample sample) => paused;
  @override
  void reset() {}
}

/// Repositorio de privacidade cuja consulta de rotina falha.
class _FailingPrivacy extends PrivacyRepository {
  _FailingPrivacy(super.db);
  @override
  Future<List<ActivityStartSample>> recentStarts({
    int limit = kRoutineWindow,
    String? exceptGuid,
    int? atOrBeforeMs,
  }) async => throw StateError('banco indisponivel');
}

void main() {
  late RecordingDatabase db;
  late FakeLocationSource source;
  late _SwitchAutoPause detector;

  setUp(() {
    db = RecordingDatabase(NativeDatabase.memory());
    source = FakeLocationSource();
    detector = _SwitchAutoPause();
  });
  tearDown(() => db.close());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    int Function()? now,
    PrivacyRepository? privacy,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationSourceProvider.overrideWithValue(source),
          recordingDatabaseProvider.overrideWithValue(db),
          recordingServiceProvider.overrideWithValue(
            const NoopRecordingService(),
          ),
          recordingControllerProvider.overrideWith(
            (ref) => RecordingController(
              source: source,
              repo: ref.watch(recordingRepositoryProvider),
              autoPauseFactory: (_) => detector,
              now: now,
            ),
          ),
          if (privacy != null) privacyRepositoryProvider.overrideWithValue(privacy),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RecordingScreen(
                        activityType: ActivityType.ride,
                      ),
                    ),
                  ),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  Future<void> feed(WidgetTester tester, Iterable<int> idx) async {
    final r = sampleRoute();
    for (final i in idx) {
      source.add(r[i]);
    }
    await settle(tester);
  }

  Future<void> hold(WidgetTester tester, Finder f) async {
    final g = await tester.startGesture(tester.getCenter(f));
    for (var i = 0; i < 16; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await g.up();
    await tester.pump();
  }

  Future<void> drain(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
  }

  testWidgets('Salvar grava titulo, descricao e visibilidade no banco', (
    tester,
  ) async {
    await pumpScreen(tester);
    await feed(tester, [0, 1, 2, 3]);
    await tester.tap(find.byKey(const Key('pause')));
    await settle(tester);
    await hold(tester, find.byKey(const Key('stop')));
    expect(find.byKey(const Key('save_activity_view')), findsOneWidget);

    final list = find
        .descendant(
          of: find.byKey(const Key('save_activity_view')),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.byKey(const Key('save_title')),
      200,
      scrollable: list,
    );
    await tester.enterText(
      find.byKey(const Key('save_title')),
      '  Volta no lago ',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('save_description')),
      200,
      scrollable: list,
    );
    await tester.enterText(
      find.byKey(const Key('save_description')),
      'Vento contra',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('visibility_followers')),
      200,
      scrollable: list,
    );
    await tester.tap(find.byKey(const Key('visibility_followers')));
    await tester.pump();
    // Privacidade (F02): ocultar os primeiros e ultimos 500 m.
    await tester.scrollUntilVisible(
      find.byKey(const Key('hide_edges_500')),
      200,
      scrollable: list,
    );
    await tester.tap(find.byKey(const Key('hide_edges_500')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('save_activity')));
    await drain(tester);

    expect(find.byType(RecordingScreen), findsNothing);
    final row = (await db.select(db.activities).get()).single;
    expect(row.isFinished, isTrue);
    expect(row.title, 'Volta no lago');
    expect(row.description, 'Vento contra');
    expect(
      ActivityVisibility.fromDb(row.visibility),
      ActivityVisibility.followers,
    );
    expect(row.hideEdgesMeters, 500);
  });

  testWidgets('rotina previsivel mostra a dica no Salvar (F02)', (tester) async {
    // 4 atividades anteriores saindo do mesmo ponto da rota, as 6h.
    final repo = RecordingRepository(db);
    final r = sampleRoute();
    await tester.runAsync(() async {
      for (var i = 0; i < 4; i++) {
        final start = DateTime(2026, 10, 20 + i, 6).millisecondsSinceEpoch;
        await repo.startActivity(guid: 'old$i', type: ActivityType.run, startTimestampMs: start);
        await repo.appendWaypoints('old$i', [
          dom.Waypoint(
            position: r[0].position,
            cumulativeDistanceMeters: 0,
            elapsedTimeMs: 0,
            timerTimeMs: 0,
            classification: dom.WaypointClassification.accept,
          ),
        ]);
        await repo.finish('old$i', start + 1000);
      }
    });
    await pumpScreen(tester);
    await feed(tester, [0, 1, 2, 3]);
    await tester.tap(find.byKey(const Key('pause')));
    await settle(tester);
    await hold(tester, find.byKey(const Key('stop')));
    await drain(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key('routine_warning')),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('save_activity_view')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.byKey(const Key('routine_warning')), findsOneWidget);
  });

  testWidgets('rotina usa o inicio do cabecalho, nao agora menos o tempo (F02)', (
    tester,
  ) async {
    // 3 anteriores saindo do mesmo ponto as 6h; a nova comeca as 6h05 pelo
    // relogio do controller. So com o inicio certo da 4 de 4.
    final repo = RecordingRepository(db);
    final r = sampleRoute();
    await tester.runAsync(() async {
      for (var i = 0; i < 3; i++) {
        final start = DateTime(2026, 10, 20 + i, 6).millisecondsSinceEpoch;
        await repo.startActivity(guid: 'old$i', type: ActivityType.run, startTimestampMs: start);
        await repo.appendWaypoints('old$i', [
          dom.Waypoint(
            position: r[0].position,
            cumulativeDistanceMeters: 0,
            elapsedTimeMs: 0,
            timerTimeMs: 0,
            classification: dom.WaypointClassification.accept,
          ),
        ]);
        await repo.finish('old$i', start + 1000);
      }
    });
    final startMs = DateTime(2026, 10, 25, 6, 5).millisecondsSinceEpoch;
    await pumpScreen(tester, now: () => startMs);
    await feed(tester, [0, 1, 2, 3]);
    await tester.tap(find.byKey(const Key('pause')));
    await settle(tester);
    await hold(tester, find.byKey(const Key('stop')));
    await drain(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key('routine_warning')),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('save_activity_view')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.byKey(const Key('routine_warning')), findsOneWidget);
  });

  testWidgets('falha ao conferir a rotina nao quebra o Salvar (F02)', (tester) async {
    await pumpScreen(tester, privacy: _FailingPrivacy(db));
    await feed(tester, [0, 1, 2, 3]);
    await tester.tap(find.byKey(const Key('pause')));
    await settle(tester);
    await hold(tester, find.byKey(const Key('stop')));
    await drain(tester);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('save_activity_view')), findsOneWidget);
    expect(find.byKey(const Key('routine_warning'), skipOffstage: false), findsNothing);
  });

  testWidgets('sem rotina, o Salvar nao mostra a dica', (tester) async {
    await pumpScreen(tester);
    await feed(tester, [0, 1, 2, 3]);
    await tester.tap(find.byKey(const Key('pause')));
    await settle(tester);
    await hold(tester, find.byKey(const Key('stop')));
    await drain(tester);
    final list = find
        .descendant(
          of: find.byKey(const Key('save_activity_view')),
          matching: find.byType(Scrollable),
        )
        .first;
    // Rola ate o fim da lista: a dica viria logo apos o corte das pontas.
    await tester.scrollUntilVisible(
      find.byKey(const Key('hide_edges_1000')),
      200,
      scrollable: list,
    );
    await tester.drag(list, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('routine_warning'), skipOffstage: false), findsNothing);
  });

  testWidgets('pausa automatica mostra Volta e Pausar, nao Retomar', (
    tester,
  ) async {
    await pumpScreen(tester);
    await feed(tester, [0, 1, 2]);
    detector.paused = true;
    await feed(tester, [3]);

    expect(find.text('Pausa automatica'), findsOneWidget);
    expect(find.byKey(const Key('resume')), findsNothing);
    expect(find.byKey(const Key('stop')), findsNothing);
    expect(find.byKey(const Key('lap')), findsOneWidget);
    expect(find.byKey(const Key('pause')), findsOneWidget);

    // Volta funciona na pausa automatica.
    await tester.tap(find.byKey(const Key('lap')));
    await settle(tester);
    expect(find.text('Volta 2'), findsOneWidget);

    // Pausar vira pausa manual, com Retomar e Encerrar.
    await tester.tap(find.byKey(const Key('pause')));
    await settle(tester);
    expect(find.text('Pausado'), findsOneWidget);
    expect(find.byKey(const Key('resume')), findsOneWidget);
    expect(find.byKey(const Key('stop')), findsOneWidget);

    // Retomar volta a gravar (a pausa automatica so volta com nova amostra).
    await tester.tap(find.byKey(const Key('resume')));
    await settle(tester);
    expect(find.text('Gravando'), findsOneWidget);
  });

  testWidgets('chips do topo nao transbordam em 320 de largura', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpScreen(tester);
    await feed(tester, [0, 1]);
    expect(tester.takeException(), isNull);

    // Rotulo mais longo do chip de estado.
    detector.paused = true;
    await feed(tester, [2]);
    expect(find.text('Pausa automatica'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Com o mapa aberto o botao vira "Metricas".
    await tester.tap(find.byKey(const Key('toggle_map')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
