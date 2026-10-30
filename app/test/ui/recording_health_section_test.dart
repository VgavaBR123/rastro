// Cartao "Saude da gravacao" (F01) no detalhe da atividade: lacunas, precisao
// media, pontos descartados e bateria gasta, nos dois temas e em imperial.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/persistence/recording_repository.dart';
import 'package:strava_estudo_app/recording/domain/gap_monitor.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/domain/waypoint.dart' as dom;
import 'package:strava_estudo_app/ui/activity_detail_screen.dart';
import 'package:strava_estudo_app/ui/theme/app_theme.dart';

dom.Waypoint ponto(double dist, int t, double acc) => dom.Waypoint(
  position: GeoPoint(latitude: dist / 111320.0, longitude: 0),
  cumulativeDistanceMeters: dist,
  elapsedTimeMs: t,
  timerTimeMs: t,
  classification: dom.WaypointClassification.accept,
  horizontalAccuracyMeters: acc,
);

Future<RecordingDatabase> gravada({
  bool comLacunas = true,
  bool comBatimento = true,
}) async {
  final db = RecordingDatabase(NativeDatabase.memory());
  final repo = RecordingRepository(db);
  await repo.startActivity(
    guid: 'a',
    type: ActivityType.run,
    startTimestampMs: 1000,
    startBatteryLevel: 90,
  );
  await repo.appendWaypoints('a', [ponto(0, 0, 4), ponto(100, 30000, 6)]);
  if (comLacunas) {
    await repo.recordGap(
      'a',
      const RecordingGap(
        startMs: 0,
        endMs: 45000,
        reason: GapReason.noGpsSignal,
      ),
    );
    await repo.recordGap(
      'a',
      const RecordingGap(
        startMs: 100000,
        endMs: 120000,
        reason: GapReason.processStopped,
      ),
    );
  }
  if (comBatimento) {
    await repo.heartbeat('a', nowMs: 1, paused: false, discardedPoints: 7);
  }
  await repo.finish(
    'a',
    200000,
    endBattery: 81,
    distanceMeters: 100,
    timerTimeMs: 30000,
  );
  return db;
}

Future<void> abrir(
  WidgetTester tester,
  RecordingDatabase db, {
  ThemeData? theme,
}) async {
  await tester.binding.setSurfaceSize(const Size(600, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final activity = (await RecordingRepository(db).recent()).first;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [recordingDatabaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        theme: theme ?? AppTheme.dark,
        home: ActivityDetailScreen(activity: activity),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

String texto(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(Key(key))).data!;

void main() {
  testWidgets('mostra lacunas, precisao, descartes e bateria', (tester) async {
    final db = await gravada();
    addTearDown(db.close);
    await abrir(tester, db);

    expect(find.byKey(const Key('recordingHealth')), findsOneWidget);
    expect(find.text('Saude da gravacao'), findsOneWidget);
    expect(texto(tester, 'healthGaps'), '2 (1 min 05 s)');
    expect(texto(tester, 'healthAccuracy'), '5 m');
    expect(texto(tester, 'healthDiscarded'), '7');
    expect(texto(tester, 'healthBattery'), '9%');
  });

  testWidgets('sem lacunas diz Nenhuma; tema claro', (tester) async {
    final db = await gravada(comLacunas: false);
    addTearDown(db.close);
    await abrir(tester, db, theme: AppTheme.light);
    expect(texto(tester, 'healthGaps'), 'Nenhuma');
    expect(tester.takeException(), isNull);
  });

  testWidgets('imperial mostra a precisao em pes', (tester) async {
    final db = await gravada();
    addTearDown(db.close);
    await db.saveSettings(useMetric: false);
    await abrir(tester, db);
    expect(texto(tester, 'healthAccuracy'), '16 ft');
  });

  testWidgets(
    'atividade sem batimento (antiga ou baixada): lacunas e descartes sem dados',
    (tester) async {
      final db = await gravada(comLacunas: false, comBatimento: false);
      addTearDown(db.close);
      await abrir(tester, db);
      expect(find.byKey(const Key('recordingHealth')), findsOneWidget);
      expect(texto(tester, 'healthGaps'), 'Sem dados');
      expect(texto(tester, 'healthDiscarded'), 'Sem dados');
      // O que existe para qualquer atividade continua aparecendo.
      expect(texto(tester, 'healthAccuracy'), '5 m');
      expect(texto(tester, 'healthBattery'), '9%');
      expect(find.byIcon(Icons.verified_rounded), findsNothing);
    },
  );
}
