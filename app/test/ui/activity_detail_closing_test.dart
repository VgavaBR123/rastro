// Fechamento gentil (F04) no Detalhe: esforco, humor e carga do treino
// (sRPE); Modo Gentil sem pace (grade, splits e voltas).
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/closing/domain/effort.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/persistence/recording_repository.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/domain/waypoint.dart' as dom;
import 'package:strava_estudo_app/ui/activity_detail_screen.dart';
import 'package:strava_estudo_app/ui/theme/app_theme.dart';

dom.Waypoint ponto(double dist, int timerMs) => dom.Waypoint(
  position: GeoPoint(latitude: dist / 111320.0, longitude: 0, altitudeMeters: 100),
  cumulativeDistanceMeters: dist,
  elapsedTimeMs: timerMs,
  timerTimeMs: timerMs,
  classification: dom.WaypointClassification.accept,
  horizontalAccuracyMeters: 5,
);

/// 2 km em 12 min (6:00 /km), uma volta.
Future<RecordingDatabase> seed({int? rpe, Mood? mood, bool gentle = false}) async {
  final db = RecordingDatabase(NativeDatabase.memory());
  final repo = RecordingRepository(db);
  await repo.startActivity(guid: 'a', type: ActivityType.run, startTimestampMs: 1000);
  await repo.appendWaypoints('a', [
    for (var i = 0; i <= 20; i++) ponto(i * 100.0, i * 36000),
  ]);
  await repo.saveLap(
    'a',
    number: 1,
    startTimerMs: 0,
    endTimerMs: 720000,
    endElapsedMs: 720000,
    startDistanceMeters: 0,
    endDistanceMeters: 2000,
  );
  await repo.finish('a', 721000, distanceMeters: 2000, timerTimeMs: 720000);
  await repo.saveDetails('a', rpe: rpe, mood: mood);
  if (gentle) await db.saveSettings(gentleMode: true);
  return db;
}

Future<void> abrir(WidgetTester tester, RecordingDatabase db) async {
  await tester.binding.setSurfaceSize(const Size(600, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final activity = (await RecordingRepository(db).recent()).first;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [recordingDatabaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: ActivityDetailScreen(activity: activity),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder em(String key, String texto) =>
    find.descendant(of: find.byKey(Key(key)), matching: find.text(texto));

void main() {
  testWidgets('esforco, humor e carga (RPE x minutos)', (tester) async {
    final db = await seed(rpe: 7, mood: Mood.tired);
    addTearDown(db.close);
    await abrir(tester, db);
    expect(em('detailEffort', '7'), findsOneWidget);
    expect(em('detailEffort', 'Esforco'), findsOneWidget);
    expect(em('detailLoad', '84'), findsOneWidget); // 7 x 12 min
    expect(em('detailMood', 'Cansado'), findsOneWidget);
    expect(find.byKey(const Key('detailEffortLabel')), findsOneWidget);
    expect(find.text('Forte'), findsOneWidget);
  });

  testWidgets('sem RPE nem humor: os blocos somem', (tester) async {
    final db = await seed();
    addTearDown(db.close);
    await abrir(tester, db);
    expect(find.byKey(const Key('detailEffort')), findsNothing);
    expect(find.byKey(const Key('detailLoad')), findsNothing);
    expect(find.byKey(const Key('detailMood')), findsNothing);
    expect(find.byKey(const Key('detailPace')), findsOneWidget);
  });

  testWidgets('Modo Gentil: sem pace na grade, nos splits e nas voltas', (tester) async {
    final db = await seed(rpe: 5, gentle: true);
    addTearDown(db.close);
    await abrir(tester, db);
    expect(find.byKey(const Key('detailPace')), findsNothing);
    expect(find.textContaining('/km'), findsNothing);
    expect(find.byKey(const Key('detailTime')), findsOneWidget);
    expect(find.byKey(const Key('detailDistance')), findsOneWidget);
    expect(em('detailEffort', '5'), findsOneWidget);
    expect(find.byKey(const Key('splitsSection')), findsOneWidget);
    expect(find.byKey(const Key('lapsSection')), findsOneWidget);
  });
}
