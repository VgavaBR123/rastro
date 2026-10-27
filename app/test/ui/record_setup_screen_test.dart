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
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/source/current_position.dart';
import 'package:strava_estudo_app/ui/components/segmented_selector.dart';
import 'package:strava_estudo_app/ui/map_style.dart';
import 'package:strava_estudo_app/ui/record_setup_screen.dart';
import 'package:strava_estudo_app/ui/route_map.dart';
import 'package:strava_estudo_app/ui/route_preview.dart';
import 'package:strava_estudo_app/ui/theme/app_theme.dart';

class FakePosition implements CurrentPositionSource {
  bool access;
  GeoPoint? last;
  GeoPoint? now;
  final List<bool> accessCalls = [];

  FakePosition({this.access = true, this.last, this.now});

  @override
  Future<bool> hasAccess({bool request = false}) async {
    accessCalls.add(request);
    return access;
  }

  @override
  Future<GeoPoint?> lastKnown() async => last;

  @override
  Future<GeoPoint?> current() async => now;
}

const _bh = GeoPoint(latitude: -19.92, longitude: -43.94);

Future<ProviderContainer> pumpSetup(
  WidgetTester tester, {
  required RecordingDatabase db,
  ThemeData? theme,
  CurrentPositionSource? position,
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
  final container = ProviderContainer(
    overrides: [
      recordingDatabaseProvider.overrideWithValue(db),
      currentPositionSourceProvider.overrideWithValue(position ?? FakePosition(now: _bh)),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: theme ?? AppTheme.dark, routerConfig: router),
    ),
  );
  // O historico vem do banco em memoria.
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pump();
  }
  return container;
}

RouteMap routeMap(WidgetTester tester) => tester.widget<RouteMap>(find.byType(RouteMap));

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

  testWidgets('com fix, centraliza na posicao e o chip recentraliza', (tester) async {
    final db = RecordingDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final pos = FakePosition(last: const GeoPoint(latitude: -19.9, longitude: -43.9), now: _bh);
    await pumpSetup(tester, db: db, position: pos);

    expect(pos.accessCalls, [true]); // pede a permissao ao abrir
    expect(find.text('GPS pronto'), findsOneWidget);
    expect(routeMap(tester).userLocation, _bh); // o fix atual vence a ultima conhecida
    final before = routeMap(tester).recenterRequest;

    await tester.tap(find.byKey(const Key('gps_chip')));
    await tester.pump();
    expect(routeMap(tester).recenterRequest, before + 1);
  });

  testWidgets('sem permissao mostra Sem GPS e o toque tenta de novo', (tester) async {
    final db = RecordingDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final pos = FakePosition(access: false);
    await pumpSetup(tester, db: db, position: pos);

    expect(find.text('Sem GPS'), findsOneWidget);
    expect(routeMap(tester).userLocation, isNull);

    pos
      ..access = true
      ..now = _bh;
    await tester.tap(find.byKey(const Key('gps_chip')));
    for (var i = 0; i < 3; i++) {
      await tester.pump();
    }
    expect(pos.accessCalls, [true, true]);
    expect(find.text('GPS pronto'), findsOneWidget);
    expect(routeMap(tester).userLocation, _bh);
  });

  testWidgets('sem fix a tempo mostra Sem GPS', (tester) async {
    final db = RecordingDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await pumpSetup(tester, db: db, position: FakePosition());
    expect(find.text('Sem GPS'), findsOneWidget);
  });

  testWidgets('Camadas troca o estilo do mapa e Automatico volta ao tema', (tester) async {
    final db = RecordingDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final container = await pumpSetup(tester, db: db);

    await tester.tap(find.byKey(const Key('map_layers')));
    await tester.pumpAndSettle();
    expect(find.text('Segue o tema (Escuro)'), findsOneWidget);
    await tester.tap(find.byKey(const Key('map_style_ruas')));
    await tester.pumpAndSettle();
    expect(container.read(mapStyleChoiceProvider), MapStyle.ruas);
    expect(find.byKey(const Key('map_style_ruas')), findsNothing); // folha fechou

    await tester.tap(find.byKey(const Key('map_layers')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('map_style_auto')));
    await tester.pumpAndSettle();
    expect(container.read(mapStyleChoiceProvider), isNull);
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
