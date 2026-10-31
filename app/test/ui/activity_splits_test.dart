// Widget test dos splits na tela de detalhe, com DB em memoria semeado.
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
  int timerMs, {
  dom.WaypointClassification cls = dom.WaypointClassification.accept,
}) =>
    dom.Waypoint(
      position: GeoPoint(latitude: dist / 111320.0, longitude: 0, altitudeMeters: 100),
      cumulativeDistanceMeters: dist,
      elapsedTimeMs: timerMs,
      timerTimeMs: timerMs,
      classification: cls,
      horizontalAccuracyMeters: 5,
    );

/// 2500 m a 5 min/km: dois splits fechados e um parcial de 500 m.
Future<RecordingDatabase> seededDb() async {
  final db = RecordingDatabase(NativeDatabase.memory());
  final repo = RecordingRepository(db);
  await repo.startActivity(guid: 'a', type: ActivityType.run, startTimestampMs: 1000);
  await repo.appendWaypoints('a', [
    ponto(0, 0),
    ponto(1000, 300000),
    // Ponto descartado pelo pipeline: nao deve influenciar os splits.
    ponto(9999, 300001, cls: dom.WaypointClassification.ignoreBadAccuracy),
    ponto(2000, 600000),
    ponto(2500, 750000),
  ]);
  await repo.finish('a', 751000, distanceMeters: 2500, timerTimeMs: 750000);
  return db;
}

Future<void> abrirDetalhe(WidgetTester tester, RecordingDatabase db) async {
  final activity = (await RecordingRepository(db).recent()).first;
  await tester.pumpWidget(ProviderScope(
    overrides: [recordingDatabaseProvider.overrideWithValue(db)],
    child: MaterialApp(home: ActivityDetailScreen(activity: activity)),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Detalhe lista os splits por km, com o parcial marcado',
      (tester) async {
    final db = await seededDb();
    addTearDown(db.close);
    await tester.binding.setSurfaceSize(const Size(600, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await abrirDetalhe(tester, db);

    expect(find.text('Splits por km'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3 (parcial)'), findsOneWidget);
    // Marcas de 1 km e 2 km.
    expect(find.text('1,00 km'), findsOneWidget);
    expect(find.text('2,00 km'), findsOneWidget);
    // O trecho parcial nao atingiu marca: mostra a distancia percorrida.
    expect(find.text('500 m'), findsOneWidget);
    // Trechos de 5 min a 5:00 /km; o parcial tem 2:30.
    expect(find.text('5:00'), findsNWidgets(2));
    expect(find.text('2:30'), findsOneWidget);
    // Tres paces de split + o pace medio da atividade (2500 m / 12:30).
    expect(find.text('5:00 /km'), findsNWidgets(4));
  });

  testWidgets('Detalhe usa milha quando a configuracao e imperial',
      (tester) async {
    final db = await seededDb();
    addTearDown(db.close);
    await db.saveSettings(useMetric: false);
    await tester.binding.setSurfaceSize(const Size(600, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await abrirDetalhe(tester, db);

    expect(find.text('Splits por milha'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2 (parcial)'), findsOneWidget);
    expect(find.textContaining('/mi'), findsWidgets);
  });

  testWidgets('Atividade sem pontos mostra aviso de ausencia de splits',
      (tester) async {
    final db = RecordingDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = RecordingRepository(db);
    await repo.startActivity(guid: 'b', type: ActivityType.walk, startTimestampMs: 1000);
    await repo.finish('b', 2000, distanceMeters: 0, timerTimeMs: 0);

    await abrirDetalhe(tester, db);

    expect(find.text('Sem splits nesta atividade.'), findsOneWidget);
  });
}
