// RecordingScreen: Salvar persiste titulo/descricao/visibilidade, chips do topo
// sem transbordar em tela estreita e botoes durante a pausa automatica.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/persistence/database.dart';
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

  Future<void> pumpScreen(WidgetTester tester) async {
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
            ),
          ),
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

  testWidgets('Salvar grava título, descrição e visibilidade no banco', (
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
  });

  testWidgets('pausa automática mostra Volta e Pausar, não Retomar', (
    tester,
  ) async {
    await pumpScreen(tester);
    await feed(tester, [0, 1, 2]);
    detector.paused = true;
    await feed(tester, [3]);

    expect(find.text('Pausa automática'), findsOneWidget);
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

  testWidgets('chips do topo não transbordam em 320 de largura', (
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
    expect(find.text('Pausa automática'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Com o mapa aberto o botao vira "Metricas".
    await tester.tap(find.byKey(const Key('toggle_map')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
