// Privacidade automatica (F02): Configuracoes > Privacidade, lista de zonas,
// sugestoes (aceitar/ignorar), adicionar no mapa ou a partir de uma
// atividade e remover.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/app/router.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/persistence/recording_repository.dart';
import 'package:strava_estudo_app/privacy/domain/privacy_zone.dart';
import 'package:strava_estudo_app/privacy/privacy_providers.dart';
import 'package:strava_estudo_app/privacy/privacy_repository.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/domain/waypoint.dart' as dom;
import 'package:strava_estudo_app/ui/components/big_action_button.dart';
import 'package:strava_estudo_app/ui/settings_screen.dart';
import 'package:strava_estudo_app/ui/theme/app_theme.dart';

dom.Waypoint p(double lat, double lon, int i) => dom.Waypoint(
  position: GeoPoint(latitude: lat, longitude: lon),
  cumulativeDistanceMeters: i * 100.0,
  elapsedTimeMs: i * 1000,
  timerTimeMs: i * 1000,
  classification: dom.WaypointClassification.accept,
);

/// Atividade de (lat, 0) ate (lat, [toLon]).
Future<void> seed(RecordingDatabase db, String guid, {double toLon = 0.01, String? title}) async {
  final repo = RecordingRepository(db);
  await repo.startActivity(guid: guid, type: ActivityType.run, startTimestampMs: 1000 + guid.hashCode % 1000);
  await repo.appendWaypoints(guid, [p(-20, 0, 0), p(-20, toLon / 2, 1), p(-20, toLon, 2)]);
  await repo.finish(guid, 9000, distanceMeters: 1000, timerTimeMs: 2000);
  if (title != null) await repo.saveDetails(guid, title: title);
}

/// Falha ao salvar a zona (disco cheio, banco fechado).
class _FailingAdd extends PrivacyRepository {
  _FailingAdd(super.db);
  int calls = 0;
  @override
  Future<PrivacyZone> addZone(PrivacyZone zone) async {
    calls++;
    throw StateError('disco cheio');
  }
}

void main() {
  late RecordingDatabase db;
  setUp(() => db = RecordingDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  Future<void> pumpApp(
    WidgetTester tester, {
    String at = AppRoutes.privacy,
    ThemeData? theme,
    PrivacyRepository? privacy,
  }) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1.5;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: at,
      routes: [
        GoRoute(path: AppRoutes.settings, builder: (_, _) => const SettingsScreen()),
        ...privacyRoutes(),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        recordingDatabaseProvider.overrideWithValue(db),
        if (privacy != null) privacyRepositoryProvider.overrideWithValue(privacy),
      ],
      child: MaterialApp.router(theme: theme ?? AppTheme.dark, routerConfig: router),
    ));
    await settle(tester);
  }

  Future<List<PrivacyZone>> zones(WidgetTester tester) async =>
      (await tester.runAsync(() => PrivacyRepository(db).zones()))!;

  testWidgets('Configuracoes tem Privacidade: zonas e ocultar no servidor', (tester) async {
    await pumpApp(tester, at: AppRoutes.settings);
    final sw = find.byKey(const Key('hide_on_server'));
    await tester.scrollUntilVisible(sw, 200);
    expect(tester.widget<SwitchListTile>(sw).value, isTrue);
    await tester.tap(sw);
    await settle(tester);
    expect(tester.widget<SwitchListTile>(sw).value, isFalse);
    expect((await tester.runAsync(db.loadSettings))!.hideOnServer, isFalse);

    final tile = find.byKey(const Key('privacy_zones'));
    expect(tester.getSize(tile).height, greaterThanOrEqualTo(44));
    await tester.tap(tile);
    await settle(tester);
    expect(find.byKey(const Key('privacy_zones_screen')), findsOneWidget);
  });

  for (final (nome, tema) in [('escuro', AppTheme.dark), ('claro', AppTheme.light)]) {
    testWidgets('lista vazia explica e oferece adicionar ($nome)', (tester) async {
      await pumpApp(tester, theme: tema);
      expect(find.byKey(const Key('privacy_empty')), findsOneWidget);
      expect(find.byKey(const Key('zone_add_map')), findsOneWidget);
      expect(find.byKey(const Key('zone_add_activity')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('sugestao: Esconder cria a zona Casa', (tester) async {
    await tester.runAsync(() async {
      // Tres saidas do mesmo lugar, chegadas em lugares diferentes.
      await seed(db, 'a', toLon: 0.01);
      await seed(db, 'b', toLon: 0.02);
      await seed(db, 'c', toLon: 0.03);
    });
    await pumpApp(tester);
    expect(find.byKey(const Key('zone_suggestion')), findsOneWidget);
    expect(find.textContaining('Parece que aqui e sua casa'), findsOneWidget);

    await tester.tap(find.byKey(const Key('suggestion_accept')));
    await settle(tester);
    expect(find.byKey(const Key('zone_suggestion')), findsNothing);
    final z = (await zones(tester)).single;
    expect(z.label, 'Casa');
    expect(z.latitude, closeTo(-20, 1e-6));
    expect(find.text('Casa'), findsOneWidget);
  });

  testWidgets('sugestao: Ignorar some e nao volta', (tester) async {
    await tester.runAsync(() async {
      await seed(db, 'a', toLon: 0.01);
      await seed(db, 'b', toLon: 0.02);
      await seed(db, 'c', toLon: 0.03);
    });
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('suggestion_dismiss')));
    await settle(tester);
    expect(find.byKey(const Key('zone_suggestion')), findsNothing);
    expect(await zones(tester), isEmpty);
    final dismissed = await tester.runAsync(() => PrivacyRepository(db).dismissedSuggestions());
    expect(dismissed, hasLength(1));
  });

  testWidgets('remover zona pede confirmacao', (tester) async {
    await tester.runAsync(() => PrivacyRepository(db).addZone(
      const PrivacyZone(latitude: 1, longitude: 1, radiusMeters: 200, label: 'Trabalho'),
    ));
    await pumpApp(tester);
    expect(find.text('Trabalho'), findsOneWidget);
    await tester.tap(find.byKey(const Key('zone_remove_0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('zone_remove_cancel')));
    await settle(tester);
    expect(await zones(tester), hasLength(1));

    await tester.tap(find.byKey(const Key('zone_remove_0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('zone_remove_confirm')));
    await settle(tester);
    expect(await zones(tester), isEmpty);
    expect(find.byKey(const Key('privacy_empty')), findsOneWidget);
  });

  testWidgets('adicionar a partir de uma atividade (fim)', (tester) async {
    await tester.runAsync(() => seed(db, 'a', toLon: 0.01, title: 'Treino do parque'));
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('zone_add_activity')));
    await settle(tester);
    await tester.tap(find.text('Treino do parque'));
    await settle(tester);
    expect(find.byKey(const Key('zone_from_activity_dialog')), findsOneWidget);
    await tester.tap(find.byKey(const Key('zone_point_end')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('zone_from_activity_label')), 'Academia');
    await tester.tap(find.byKey(const Key('zone_from_activity_save')));
    await settle(tester);

    final z = (await zones(tester)).single;
    expect(z.label, 'Academia');
    expect(z.longitude, closeTo(0.01, 1e-9));
    expect(find.text('Academia'), findsOneWidget);
  });

  testWidgets('adicionar no mapa (campos de coordenada fora do celular)', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('zone_add_map')));
    await settle(tester);
    expect(find.byKey(const Key('add_zone_screen')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('zone_label')), 'Casa da mae');
    await tester.enterText(find.byKey(const Key('zone_lat')), '-19.9');
    await tester.enterText(find.byKey(const Key('zone_lon')), '-43.9');
    await tester.tap(find.byKey(const Key('zone_radius_400')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('zone_save')));
    await tester.tap(find.byKey(const Key('zone_save')));
    await settle(tester);

    expect(find.byKey(const Key('add_zone_screen')), findsNothing);
    final z = (await zones(tester)).single;
    expect(z.label, 'Casa da mae');
    expect(z.latitude, -19.9);
    expect(z.longitude, -43.9);
    expect(z.radiusMeters, 400);
    expect(find.text('Casa da mae'), findsOneWidget);
  });

  testWidgets('coordenada invalida nao salva', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('zone_add_map')));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('zone_lat')), '200');
    await tester.enterText(find.byKey(const Key('zone_lon')), 'abc');
    await tester.ensureVisible(find.byKey(const Key('zone_save')));
    await tester.tap(find.byKey(const Key('zone_save')));
    await settle(tester);
    expect(find.byKey(const Key('add_zone_screen')), findsOneWidget);
    expect(find.text('Coordenada invalida'), findsWidgets);
    expect(await zones(tester), isEmpty);
  });

  testWidgets('local salvo sem nome vira "Local protegido", como no repositorio', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('zone_add_map')));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('zone_lat')), '-19.9');
    await tester.enterText(find.byKey(const Key('zone_lon')), '-43.9');
    await tester.ensureVisible(find.byKey(const Key('zone_save')));
    await tester.tap(find.byKey(const Key('zone_save')));
    await settle(tester);
    expect((await zones(tester)).single.label, 'Local protegido');
  });

  testWidgets('falha ao salvar o local avisa e libera o botao', (tester) async {
    final failing = _FailingAdd(db);
    await pumpApp(tester, privacy: failing);
    await tester.tap(find.byKey(const Key('zone_add_map')));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('zone_lat')), '-19.9');
    await tester.enterText(find.byKey(const Key('zone_lon')), '-43.9');
    await tester.ensureVisible(find.byKey(const Key('zone_save')));
    await tester.tap(find.byKey(const Key('zone_save')));
    await settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('add_zone_screen')), findsOneWidget);
    expect(find.textContaining('Nao foi possivel salvar'), findsOneWidget);
    // O botao volta a funcionar.
    expect(
      tester.widget<BigActionButton>(find.byKey(const Key('zone_save'))).onPressed,
      isNotNull,
    );
    expect(failing.calls, 1);
  });

  testWidgets('a partir de uma atividade: so lista atividades com rota', (tester) async {
    await tester.runAsync(() async {
      await seed(db, 'a', toLon: 0.01, title: 'Treino do parque');
      final repo = RecordingRepository(db);
      await repo.startActivity(guid: 'indoor', type: ActivityType.run, startTimestampMs: 50000);
      await repo.finish('indoor', 60000);
      await repo.saveDetails('indoor', title: 'Esteira');
    });
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('zone_add_activity')));
    await settle(tester);
    expect(find.text('Treino do parque'), findsOneWidget);
    expect(find.text('Esteira'), findsNothing);
  });

  testWidgets('a partir de uma atividade: toque duplo abre uma folha so', (tester) async {
    await tester.runAsync(() => seed(db, 'a', toLon: 0.01, title: 'Treino do parque'));
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('zone_add_activity')));
    await tester.tap(find.byKey(const Key('zone_add_activity')), warnIfMissed: false);
    await settle(tester);
    expect(find.text('Escolha a atividade'), findsOneWidget);
  });
}
