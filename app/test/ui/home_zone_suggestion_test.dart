// Privacidade automatica (F02) na Inicio: a sugestao "parece que aqui e sua
// casa" aparece sem a pessoa precisar abrir Configuracoes > Privacidade.
import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/app/router.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/persistence/recording_repository.dart';
import 'package:strava_estudo_app/privacy/privacy_repository.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/location_sample.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/domain/waypoint.dart' as dom;
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

dom.Waypoint p(double lon, int i) => dom.Waypoint(
  position: GeoPoint(latitude: -20, longitude: lon),
  cumulativeDistanceMeters: i * 500.0,
  elapsedTimeMs: i * 1000,
  timerTimeMs: i * 1000,
  classification: dom.WaypointClassification.accept,
);

/// Atividade saindo de casa (-20, 0) e chegando em (-20, [toLon]).
Future<void> seed(
  RecordingDatabase db,
  String guid,
  double toLon,
  int startMs,
) async {
  final repo = RecordingRepository(db);
  await repo.startActivity(
    guid: guid,
    type: ActivityType.run,
    startTimestampMs: startMs,
  );
  await repo.appendWaypoints(guid, [p(0, 0), p(toLon / 2, 1), p(toLon, 2)]);
  await repo.finish(
    guid,
    startMs + 9000,
    distanceMeters: 1000,
    timerTimeMs: 2000,
  );
}

void main() {
  late RecordingDatabase db;
  setUp(() => db = RecordingDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  Future<ProviderContainer> pumpHome(
    WidgetTester tester, {
    ThemeData? theme,
  }) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1.5;
    addTearDown(tester.view.reset);
    final router = buildAppRouter();
    addTearDown(router.dispose);
    final container = ProviderContainer(
      overrides: [
        recordingDatabaseProvider.overrideWithValue(db),
        locationSourceProvider.overrideWithValue(_FakeSource()),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: theme ?? AppTheme.dark,
          routerConfig: router,
        ),
      ),
    );
    await settle(tester);
    return container;
  }

  Future<void> seedHome(WidgetTester tester) => tester.runAsync(() async {
    await seed(db, 'a', 0.01, 1000);
    await seed(db, 'b', 0.02, 2000);
    await seed(db, 'c', 0.03, 3000);
  });

  for (final (nome, tema) in [
    ('escuro', AppTheme.dark),
    ('claro', AppTheme.light),
  ]) {
    testWidgets('lugar repetido mostra a sugestao na Inicio ($nome)', (
      tester,
    ) async {
      await seedHome(tester);
      await pumpHome(tester, theme: tema);
      expect(find.byKey(const Key('home_zone_suggestion')), findsOneWidget);
      expect(find.textContaining('Parece que aqui e sua casa'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('sem lugar repetido: sem sugestao', (tester) async {
    await tester.runAsync(() => seed(db, 'a', 0.01, 1000));
    await pumpHome(tester);
    expect(find.byKey(const Key('home_zone_suggestion')), findsNothing);
  });

  testWidgets('Esconder na Inicio cria a zona Casa e a sugestao some', (
    tester,
  ) async {
    await seedHome(tester);
    await pumpHome(tester);
    await tester.tap(find.byKey(const Key('suggestion_accept')));
    await settle(tester);
    expect(find.byKey(const Key('home_zone_suggestion')), findsNothing);
    final zones = (await tester.runAsync(() => PrivacyRepository(db).zones()))!;
    expect(zones.single.label, 'Casa');
    expect(find.textContaining('agora e um local protegido'), findsOneWidget);
  });

  testWidgets('Ignorar na Inicio some e nao volta', (tester) async {
    await seedHome(tester);
    final container = await pumpHome(tester);
    await tester.tap(find.byKey(const Key('suggestion_dismiss')));
    await settle(tester);
    expect(find.byKey(const Key('home_zone_suggestion')), findsNothing);
    container.invalidate(recentActivitiesProvider);
    await settle(tester);
    expect(find.byKey(const Key('home_zone_suggestion')), findsNothing);
    final dismissed = await tester.runAsync(
      () => PrivacyRepository(db).dismissedSuggestions(),
    );
    expect(dismissed, hasLength(1));
  });

  testWidgets('nova atividade salva atualiza a sugestao na Inicio', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await seed(db, 'a', 0.01, 1000);
      await seed(db, 'b', 0.02, 2000);
    });
    final container = await pumpHome(tester);
    expect(find.byKey(const Key('home_zone_suggestion')), findsNothing);
    await tester.runAsync(() => seed(db, 'c', 0.03, 3000));
    // A gravacao invalida as recentes ao salvar.
    container.invalidate(recentActivitiesProvider);
    await settle(tester);
    expect(find.byKey(const Key('home_zone_suggestion')), findsOneWidget);
  });
}
