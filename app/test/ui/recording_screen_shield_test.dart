// Gravacao blindada (F01) na tela de gravacao: aviso de lacuna (banner), GPS
// sem sinal e bloqueio contra toques (cadeado; desbloquear exige segurar).
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/recording/domain/location_sample.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/presentation/recording_controller.dart';
import 'package:strava_estudo_app/recording/service/recording_service.dart';
import 'package:strava_estudo_app/ui/recording_screen.dart';
import 'package:strava_estudo_app/ui/theme/app_theme.dart';

import '../fixtures/sample_route.dart';
import '../recording/fakes.dart';

void main() {
  late RecordingDatabase db;
  late FakeLocationSource source;
  late FakeHeartbeatTicker ticker;
  late int now;

  setUp(() {
    db = RecordingDatabase(NativeDatabase.memory());
    source = FakeLocationSource();
    ticker = FakeHeartbeatTicker();
    now = 1000000;
  });
  tearDown(() => db.close());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> pumpScreen(WidgetTester tester, {ThemeData? theme}) async {
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
              heartbeat: ticker,
              now: () => now,
            ),
          ),
        ],
        child: MaterialApp(
          theme: theme ?? AppTheme.dark,
          home: const RecordingScreen(activityType: ActivityType.ride),
        ),
      ),
    );
    await settle(tester);
  }

  void add(LocationSample s) => source.add(s);

  Future<void> hold(WidgetTester tester, Finder f) async {
    final g = await tester.startGesture(tester.getCenter(f));
    for (var i = 0; i < 16; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await g.up();
    await tester.pump();
  }

  Future<void> loseGps(WidgetTester tester) async {
    add(sampleRoute()[0]);
    await settle(tester);
    for (var i = 0; i < 8; i++) {
      now += 5000;
      ticker.tick();
      await settle(tester);
    }
  }

  testWidgets(
    'GPS mudo mostra aviso; ao voltar, banner da lacuna e Entendi fecha',
    (tester) async {
      await pumpScreen(tester);
      expect(find.byKey(const Key('gps_lost_banner')), findsNothing);

      await loseGps(tester);
      expect(find.byKey(const Key('gps_lost_banner')), findsOneWidget);

      now += 2000;
      add(sampleRoute()[1]);
      await settle(tester);
      expect(find.byKey(const Key('gps_lost_banner')), findsNothing);
      expect(find.byKey(const Key('gap_banner')), findsOneWidget);
      expect(find.textContaining('42 s'), findsOneWidget);
      expect(find.textContaining('sem sinal de GPS'), findsOneWidget);

      await tester.tap(find.byKey(const Key('gap_banner_dismiss')));
      await settle(tester);
      expect(find.byKey(const Key('gap_banner')), findsNothing);
    },
  );

  testWidgets('cadeado bloqueia os toques; desbloquear exige segurar', (
    tester,
  ) async {
    await pumpScreen(tester);
    add(sampleRoute()[0]);
    await settle(tester);

    final lock = find.byKey(const Key('recording_lock'));
    expect(lock, findsOneWidget);
    expect(tester.getSize(lock).height, greaterThanOrEqualTo(64));
    await tester.tap(lock);
    await settle(tester);

    // Bloqueada: sem Pausar/Volta e com o botao de desbloquear grande.
    expect(find.byKey(const Key('pause')), findsNothing);
    expect(find.byKey(const Key('lap')), findsNothing);
    final unlock = find.byKey(const Key('recording_unlock'));
    expect(unlock, findsOneWidget);
    expect(tester.getSize(unlock).height, greaterThanOrEqualTo(64));
    expect(find.text('Segure para desbloquear'), findsOneWidget);

    // Toque rapido nao desbloqueia.
    await tester.tap(unlock);
    await settle(tester);
    expect(find.byKey(const Key('recording_unlock')), findsOneWidget);

    await hold(tester, unlock);
    await settle(tester);
    expect(find.byKey(const Key('recording_unlock')), findsNothing);
    expect(find.byKey(const Key('pause')), findsOneWidget);
  });

  testWidgets('bloqueada, o toque no mapa/metricas nao passa', (tester) async {
    await pumpScreen(tester);
    add(sampleRoute()[0]);
    await settle(tester);
    await tester.tap(find.byKey(const Key('recording_lock')));
    await settle(tester);
    // O botao de alternar o mapa fica inerte.
    await tester.tap(find.byKey(const Key('toggle_map')), warnIfMissed: false);
    await settle(tester);
    expect(find.text('Pace medio'), findsOneWidget);
  });

  testWidgets('tema claro renderiza banner e cadeado sem erro', (tester) async {
    await pumpScreen(tester, theme: AppTheme.light);
    await loseGps(tester);
    now += 2000;
    add(sampleRoute()[1]);
    await settle(tester);
    expect(find.byKey(const Key('gap_banner')), findsOneWidget);
    expect(find.byKey(const Key('recording_lock')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
