// Privacidade automatica (F02) na tela Compartilhar: etiqueta "Inicio e fim
// ocultos", rota cortada por padrao, alavanca (rota cortada / sem mapa / so
// metricas), trecho completo so com confirmacao e dica de rotina.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/persistence/recording_repository.dart';
import 'package:strava_estudo_app/platform/activity_sharer.dart';
import 'package:strava_estudo_app/privacy/domain/privacy_zone.dart';
import 'package:strava_estudo_app/privacy/privacy_repository.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/domain/waypoint.dart' as dom;
import 'package:strava_estudo_app/ui/privacy/routine_warning_banner.dart';
import 'package:strava_estudo_app/ui/route_preview.dart';
import 'package:strava_estudo_app/ui/share/share_activity_screen.dart';
import 'package:strava_estudo_app/ui/theme/app_theme.dart';

import '../fixtures/fake_sharer.dart';

const int n = 200;
const double step = 0.0001;

dom.Waypoint p(int i, {double lat = 0}) => dom.Waypoint(
  position: GeoPoint(latitude: lat, longitude: i * step),
  cumulativeDistanceMeters: i * 11.1,
  elapsedTimeMs: i * 1000,
  timerTimeMs: i * 1000,
  classification: dom.WaypointClassification.accept,
);

void main() {
  late RecordingDatabase db;
  late Directory dir;
  late FakeActivitySharer sharer;

  setUp(() async {
    db = RecordingDatabase(NativeDatabase.memory());
    dir = Directory.systemTemp.createTempSync('share_priv');
    sharer = FakeActivitySharer();
    final repo = RecordingRepository(db);
    final start = DateTime(2026, 10, 26, 7).millisecondsSinceEpoch;
    await repo.startActivity(guid: 'a', type: ActivityType.run, startTimestampMs: start);
    await repo.appendWaypoints('a', [for (var i = 0; i < n; i++) p(i)]);
    await repo.finish('a', start + n * 1000, distanceMeters: n * 11.1, timerTimeMs: n * 1000);
    await repo.saveDetails('a', title: 'Treino de casa');
  });

  tearDown(() async {
    await db.close();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  Future<void> addHomeZone() => PrivacyRepository(db).addZone(
    const PrivacyZone(latitude: 0, longitude: 0, radiusMeters: 200, label: 'Casa'),
  );

  Future<void> pumpScreen(WidgetTester tester, {ThemeData? theme}) async {
    await tester.binding.setSurfaceSize(const Size(420, 960));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final activity = (await tester.runAsync(() => RecordingRepository(db).activity('a')))!;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        recordingDatabaseProvider.overrideWithValue(db),
        activitySharerProvider.overrideWithValue(sharer),
        shareImageDirectoryProvider.overrideWithValue(() async => dir),
      ],
      child: MaterialApp(
        theme: theme ?? AppTheme.dark,
        home: ShareActivityScreen(activity: activity),
      ),
    ));
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  int routeLength(WidgetTester tester) =>
      tester.widget<RoutePreview>(find.byKey(const Key('share_card_route'))).route.length;

  testWidgets('sem zona: sem etiqueta e rota inteira', (tester) async {
    await pumpScreen(tester);
    expect(find.text('Inicio e fim ocultos'), findsNothing);
    expect(routeLength(tester), n);
    expect(find.byKey(const Key('share_reveal_full')), findsNothing);
  });

  for (final (nome, tema) in [('escuro', AppTheme.dark), ('claro', AppTheme.light)]) {
    testWidgets('com zona em casa: etiqueta e rota cortada por padrao ($nome)', (tester) async {
      await tester.runAsync(addHomeZone);
      await pumpScreen(tester, theme: tema);
      expect(find.text('Inicio e fim ocultos'), findsOneWidget);
      expect(routeLength(tester), lessThan(n));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('alavanca: sem mapa e so metricas', (tester) async {
    await tester.runAsync(addHomeZone);
    await pumpScreen(tester);
    expect(find.byKey(const Key('share_privacy_trimmed')), findsOneWidget);

    await tester.tap(find.byKey(const Key('share_privacy_noMap')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('share_card_route')), findsNothing);
    expect(find.byKey(const Key('share_card_title')), findsOneWidget);

    await tester.tap(find.byKey(const Key('share_privacy_metricsOnly')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('share_card_route')), findsNothing);
    expect(find.byKey(const Key('share_card_title')), findsNothing);
    expect(find.byKey(const Key('share_card_date')), findsNothing);
    expect(find.byKey(const Key('share_metric_Distancia')), findsOneWidget);
  });

  testWidgets('trecho completo so depois de confirmar', (tester) async {
    await tester.runAsync(addHomeZone);
    await pumpScreen(tester);
    final cortada = routeLength(tester);

    await tester.tap(find.byKey(const Key('share_reveal_full')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reveal_dialog')), findsOneWidget);
    await tester.tap(find.byKey(const Key('reveal_cancel')));
    await tester.pumpAndSettle();
    expect(routeLength(tester), cortada);

    await tester.tap(find.byKey(const Key('share_reveal_full')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reveal_confirm')));
    await tester.pumpAndSettle();
    expect(routeLength(tester), n);
    expect(find.text('Inicio e fim ocultos'), findsNothing);
    expect(find.text('Trajeto completo visivel'), findsOneWidget);

    // Voltar a esconder.
    await tester.tap(find.byKey(const Key('share_hide_again')));
    await tester.pumpAndSettle();
    expect(routeLength(tester), cortada);
  });

  testWidgets('rotina previsivel mostra a dica', (tester) async {
    await tester.runAsync(() async {
      final repo = RecordingRepository(db);
      for (var i = 0; i < 3; i++) {
        final start = DateTime(2026, 10, 20 + i, 7, 10).millisecondsSinceEpoch;
        await repo.startActivity(guid: 'r$i', type: ActivityType.run, startTimestampMs: start);
        await repo.appendWaypoints('r$i', [p(0), p(1)]);
        await repo.finish('r$i', start + 2000);
      }
    });
    await pumpScreen(tester);
    expect(find.byKey(const Key('share_routine_warning')), findsOneWidget);
    // Mesmo componente da tela Salvar.
    expect(
      find.descendant(
        of: find.byKey(const Key('share_routine_warning')),
        matching: find.byType(RoutineWarningBanner),
      ),
      findsOneWidget,
    );
  });

  testWidgets('rotina de outras atividades nao avisa ao compartilhar uma sem relacao', (
    tester,
  ) async {
    // Depois da atividade compartilhada, 4 saidas de outro lugar as 18h.
    await tester.runAsync(() async {
      final repo = RecordingRepository(db);
      for (var i = 0; i < 4; i++) {
        final start = DateTime(2026, 10, 27 + i, 18).millisecondsSinceEpoch;
        await repo.startActivity(guid: 'o$i', type: ActivityType.run, startTimestampMs: start);
        await repo.appendWaypoints('o$i', [p(0, lat: 1), p(1, lat: 1)]);
        await repo.finish('o$i', start + 2000);
      }
    });
    await pumpScreen(tester);
    expect(find.byKey(const Key('share_routine_warning')), findsNothing);
  });

  testWidgets('sem rotina: sem dica', (tester) async {
    await pumpScreen(tester);
    expect(find.byKey(const Key('share_routine_warning')), findsNothing);
  });
}
