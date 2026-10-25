// Widget tests do historico e do detalhe, com DB em memoria semeado.
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
import 'package:strava_estudo_app/ui/history_screen.dart';

dom.Waypoint acc(double lat, double dist) => dom.Waypoint(
      position: GeoPoint(latitude: lat, longitude: 0, altitudeMeters: 100),
      cumulativeDistanceMeters: dist,
      elapsedTimeMs: 0,
      timerTimeMs: 60000,
      classification: dom.WaypointClassification.accept,
      horizontalAccuracyMeters: 5,
    );

Future<RecordingDatabase> seededDb() async {
  final db = RecordingDatabase(NativeDatabase.memory());
  final repo = RecordingRepository(db);
  await repo.startActivity(guid: 'a', type: ActivityType.run, startTimestampMs: 1000);
  await repo.appendWaypoints('a', [acc(0.0, 0), acc(0.001, 1200)]);
  await repo.finish('a', 61000, distanceMeters: 1200, timerTimeMs: 60000);
  return db;
}

void main() {
  testWidgets('Historico lista a atividade finalizada', (tester) async {
    final db = await seededDb();
    addTearDown(db.close);

    await tester.pumpWidget(ProviderScope(
      overrides: [recordingDatabaseProvider.overrideWithValue(db)],
      child: const MaterialApp(home: HistoryScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('Corrida'), findsOneWidget);
    expect(find.byType(ListTile), findsOneWidget);
  });

  testWidgets('Detalhe mostra metricas da atividade', (tester) async {
    final db = await seededDb();
    addTearDown(db.close);
    final activity = (await RecordingRepository(db).recent()).first;

    await tester.pumpWidget(ProviderScope(
      overrides: [recordingDatabaseProvider.overrideWithValue(db)],
      child: MaterialApp(home: ActivityDetailScreen(activity: activity)),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Distancia'), findsOneWidget);
    expect(find.text('Tempo'), findsOneWidget);
    expect(find.text('Pace'), findsOneWidget);
    expect(find.text('1.20 km'), findsOneWidget); // 1200 m
  });
}
