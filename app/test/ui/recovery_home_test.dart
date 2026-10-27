// Widget tests da recuperacao pos-crash na Home: o dialogo aparece para uma
// atividade nao finalizada e cada escolha tem o efeito certo no banco.
import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/app/router.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/persistence/recording_repository.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/location_sample.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/domain/waypoint.dart' as dom;
import 'package:strava_estudo_app/recording/source/location_source.dart';
import 'package:strava_estudo_app/ui/recording_screen.dart';

class _FakeSource implements LocationSource {
  final _c = StreamController<LocationSample>();
  @override
  Future<bool> ensurePermission() async => true;
  @override
  Stream<LocationSample> positions() => _c.stream;
  @override
  Future<void> stop() async => _c.close();
}

dom.Waypoint acc(double lon, double dist, int t) => dom.Waypoint(
      position: GeoPoint(latitude: 0, longitude: lon),
      cumulativeDistanceMeters: dist,
      elapsedTimeMs: t,
      timerTimeMs: t,
      classification: dom.WaypointClassification.accept,
      horizontalAccuracyMeters: 5,
    );

/// Banco com uma corrida interrompida iniciada ha [ago].
Future<RecordingDatabase> dbWithInterrupted(Duration ago) async {
  final db = RecordingDatabase(NativeDatabase.memory());
  final repo = RecordingRepository(db);
  final start = DateTime.now().subtract(ago).millisecondsSinceEpoch;
  await repo.startActivity(guid: 'x', type: ActivityType.run, startTimestampMs: start);
  await repo.appendWaypoints('x', [acc(0, 0, 0), acc(0.01, 1113, 300000)]);
  return db;
}

Future<void> pumpHome(WidgetTester tester, RecordingDatabase db) async {
  final router = buildAppRouter();
  addTearDown(router.dispose);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      recordingDatabaseProvider.overrideWithValue(db),
      locationSourceProvider.overrideWithValue(_FakeSource()),
    ],
    // Grafo de navegacao real (go_router): as telas navegam por AppRoutes.
    child: MaterialApp.router(routerConfig: router),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sem atividade interrompida nao mostra dialogo', (tester) async {
    final db = RecordingDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await pumpHome(tester, db);
    expect(find.byKey(const Key('recovery_dialog')), findsNothing);
    expect(find.text('Correr'), findsOneWidget);
  });

  testWidgets('Salvar finaliza a atividade com o que foi gravado', (tester) async {
    final db = await dbWithInterrupted(const Duration(minutes: 10));
    addTearDown(db.close);
    await pumpHome(tester, db);

    expect(find.text('Atividade interrompida'), findsOneWidget);
    expect(find.textContaining('1.11 km'), findsOneWidget);
    await tester.tap(find.byKey(const Key('recovery_save')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('recovery_dialog')), findsNothing);
    final saved = (await RecordingRepository(db).recent()).single;
    expect(saved.guid, 'x');
    expect(saved.distanceMeters, 1113);
    expect(saved.timerTimeMs, 300000);
  });

  testWidgets('Descartar apaga a atividade', (tester) async {
    final db = await dbWithInterrupted(const Duration(minutes: 10));
    addTearDown(db.close);
    await pumpHome(tester, db);

    await tester.tap(find.byKey(const Key('recovery_discard')));
    await tester.pumpAndSettle();

    final repo = RecordingRepository(db);
    expect(await repo.interrupted(), isEmpty);
    expect(await repo.recent(), isEmpty);
  });

  testWidgets('Retomar abre a gravacao continuando a mesma atividade', (tester) async {
    final db = await dbWithInterrupted(const Duration(minutes: 10));
    addTearDown(db.close);
    await pumpHome(tester, db);

    await tester.tap(find.byKey(const Key('recovery_resume')));
    await tester.pumpAndSettle();

    expect(find.byType(RecordingScreen), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(RecordingScreen)),
    );
    final state = container.read(recordingControllerProvider);
    expect(state.state, RecordingState.recording);
    expect(state.distanceMeters, 1113);
    expect(container.read(recordingControllerProvider.notifier).activityGuid, 'x');
  });

  testWidgets('interrompida ha muito tempo nao oferece Retomar', (tester) async {
    final db = await dbWithInterrupted(const Duration(hours: 5));
    addTearDown(db.close);
    await pumpHome(tester, db);

    expect(find.text('Atividade interrompida'), findsOneWidget);
    expect(find.byKey(const Key('recovery_resume')), findsNothing);
    expect(find.byKey(const Key('recovery_save')), findsOneWidget);
  });
}
