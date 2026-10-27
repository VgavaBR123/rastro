// Widget test do detalhe: perfil de elevacao, voltas, calorias e bateria.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/persistence/recording_repository.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/domain/waypoint.dart' as dom;
import 'package:strava_estudo_app/ui/activity_detail_screen.dart';

dom.Waypoint ponto(
  double dist,
  int timerMs,
  double? alt, {
  dom.WaypointClassification cls = dom.WaypointClassification.accept,
}) => dom.Waypoint(
  position: GeoPoint(
    latitude: dist / 111320.0,
    longitude: 0,
    altitudeMeters: alt,
  ),
  cumulativeDistanceMeters: dist,
  elapsedTimeMs: timerMs,
  timerTimeMs: timerMs,
  classification: cls,
  horizontalAccuracyMeters: 5,
);

/// 1500 m com altitude 100 -> 150 -> 120, duas voltas, calorias e bateria.
Future<RecordingDatabase> completa() async {
  final db = RecordingDatabase(NativeDatabase.memory());
  final repo = RecordingRepository(db);
  await repo.startActivity(
    guid: 'a',
    type: ActivityType.run,
    startTimestampMs: 1000,
    startBatteryLevel: 90,
  );
  await repo.appendWaypoints('a', [
    ponto(0, 0, 100),
    ponto(500, 150000, null), // sem altitude: fora do perfil
    ponto(1000, 300000, 150),
    // Rejeitado pelo pipeline: nao entra no perfil (seria o maximo).
    ponto(1100, 300001, 999, cls: dom.WaypointClassification.ignoreBadAccuracy),
    ponto(1500, 480000, 120),
  ]);
  await repo.saveLap(
    'a',
    number: 1,
    startTimerMs: 0,
    endTimerMs: 300000,
    endElapsedMs: 300000,
    startDistanceMeters: 0,
    endDistanceMeters: 1000,
  );
  await repo.saveLap(
    'a',
    number: 2,
    startTimerMs: 300000,
    endTimerMs: 480000,
    endElapsedMs: 480000,
    startDistanceMeters: 1000,
    endDistanceMeters: 1500,
  );
  await repo.finish(
    'a',
    481000,
    endBattery: 84,
    distanceMeters: 1500,
    timerTimeMs: 480000,
    calories: 123.6,
  );
  return db;
}

/// Atividade sem altitude suficiente, sem voltas, calorias nem bateria.
Future<RecordingDatabase> vazia() async {
  final db = RecordingDatabase(NativeDatabase.memory());
  final repo = RecordingRepository(db);
  await repo.startActivity(
    guid: 'b',
    type: ActivityType.walk,
    startTimestampMs: 1000,
  );
  await repo.appendWaypoints('b', [
    ponto(0, 0, null),
    ponto(100, 60000, null),
    ponto(200, 120000, 80), // so 1 ponto com altitude: sem perfil
  ]);
  await repo.finish('b', 121000, distanceMeters: 200, timerTimeMs: 120000);
  return db;
}

Future<void> abrir(WidgetTester tester, RecordingDatabase db) async {
  await tester.binding.setSurfaceSize(const Size(600, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final activity = (await RecordingRepository(db).recent()).first;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [recordingDatabaseProvider.overrideWithValue(db)],
      child: MaterialApp(home: ActivityDetailScreen(activity: activity)),
    ),
  );
  await tester.pumpAndSettle();
}

String textoDe(WidgetTester tester, Key key) =>
    tester.widget<Text>(find.byKey(key)).data!;

Finder naVolta(int n, String texto) =>
    find.descendant(of: find.byKey(Key('lap-$n')), matching: find.text(texto));

Finder naLinha(String key, String texto) =>
    find.descendant(of: find.byKey(Key(key)), matching: find.text(texto));

void main() {
  testWidgets('perfil de elevacao usa so pontos aceitos com altitude', (
    tester,
  ) async {
    final db = await completa();
    addTearDown(db.close);
    await abrir(tester, db);

    expect(find.byKey(const Key('elevationSection')), findsOneWidget);
    expect(find.byKey(const Key('elevationChart')), findsOneWidget);
    expect(textoDe(tester, const Key('elevationMax')), '150 m');
    expect(textoDe(tester, const Key('elevationMin')), '100 m');
    expect(textoDe(tester, const Key('elevationGain')), '50 m');
    expect(textoDe(tester, const Key('elevationStartDistance')), '0 km');
    expect(textoDe(tester, const Key('elevationEndDistance')), '1.5 km');
  });

  testWidgets('perfil em pes e milhas quando imperial', (tester) async {
    final db = await completa();
    addTearDown(db.close);
    await db.saveSettings(useMetric: false);
    await abrir(tester, db);

    expect(textoDe(tester, const Key('elevationMax')), '492 ft');
    expect(textoDe(tester, const Key('elevationMin')), '328 ft');
    expect(textoDe(tester, const Key('elevationEndDistance')), '0.9 mi');
  });

  testWidgets('voltas com distancia, tempo e pace em km', (tester) async {
    final db = await completa();
    addTearDown(db.close);
    await abrir(tester, db);

    expect(find.byKey(const Key('lapsSection')), findsOneWidget);
    expect(naVolta(1, 'Volta 1'), findsOneWidget);
    expect(naVolta(1, '1.00 km'), findsOneWidget);
    expect(naVolta(1, '5:00'), findsOneWidget);
    expect(naVolta(1, '5:00 /km'), findsOneWidget);
    expect(naVolta(2, 'Volta 2'), findsOneWidget);
    expect(naVolta(2, '500 m'), findsOneWidget);
    expect(naVolta(2, '3:00'), findsOneWidget);
    expect(naVolta(2, '6:00 /km'), findsOneWidget);
  });

  testWidgets('voltas com pace por milha quando imperial', (tester) async {
    final db = await completa();
    addTearDown(db.close);
    await db.saveSettings(useMetric: false);
    await abrir(tester, db);

    expect(naVolta(1, '0.62 mi'), findsOneWidget);
    expect(naVolta(1, '8:03 /mi'), findsOneWidget);
    expect(naVolta(2, '0.31 mi'), findsOneWidget);
    expect(naVolta(2, '9:39 /mi'), findsOneWidget);
  });

  testWidgets('calorias arredondadas e consumo de bateria', (tester) async {
    final db = await completa();
    addTearDown(db.close);
    await abrir(tester, db);

    expect(naLinha('detailCalories', '124 kcal'), findsOneWidget);
    expect(naLinha('detailBattery', '6%'), findsOneWidget);
  });

  testWidgets('sem altitude, voltas, calorias e bateria as secoes somem', (
    tester,
  ) async {
    final db = await vazia();
    addTearDown(db.close);
    await abrir(tester, db);

    expect(find.byKey(const Key('elevationSection')), findsNothing);
    expect(find.byKey(const Key('elevationChart')), findsNothing);
    expect(find.byKey(const Key('lapsSection')), findsNothing);
    expect(find.byKey(const Key('detailCalories')), findsNothing);
    expect(find.byKey(const Key('detailBattery')), findsNothing);
    expect(find.text('Calorias'), findsNothing);
    expect(find.text('Bateria'), findsNothing);
  });
}
