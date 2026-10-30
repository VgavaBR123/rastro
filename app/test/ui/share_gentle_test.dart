// Modo Gentil (F04) no que sai do aparelho e nos cartoes: a imagem
// compartilhada, o texto e o cartao do feed mostram tempo, distancia e
// esforco, nunca pace ou velocidade.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/core/format/activity_share_text.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/persistence/recording_repository.dart';
import 'package:strava_estudo_app/platform/activity_sharer.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/domain/waypoint.dart' as dom;
import 'package:strava_estudo_app/ui/components/activity_card.dart';
import 'package:strava_estudo_app/ui/share/share_activity_screen.dart';
import 'package:strava_estudo_app/ui/share/share_card.dart';
import 'package:strava_estudo_app/ui/theme/app_colors.dart';
import 'package:strava_estudo_app/ui/theme/app_theme.dart';

import '../fixtures/fake_sharer.dart';

ShareCardData data({required ActivityType type, bool gentle = false, int? rpe}) => ShareCardData(
  title: 'Treino',
  type: type,
  startTimestampMs: 0,
  distanceMeters: 5000,
  timerMs: 1500000,
  route: const [],
  metric: true,
  gainMeters: 30,
  gentle: gentle,
  rpe: rpe,
);

void main() {
  final c = AppTheme.dark.extension<AppColors>()!;

  test('cartao: sem pace no Modo Gentil, com esforco quando ha', () {
    final normal = shareCardMetrics(data(type: ActivityType.run, rpe: 6), c);
    expect(normal.map((m) => m.label), ['Distancia', 'Pace', 'Tempo', 'Subida']);

    final gentle = shareCardMetrics(data(type: ActivityType.run, gentle: true, rpe: 6), c);
    expect(gentle.map((m) => m.label), ['Distancia', 'Tempo', 'Esforco', 'Subida']);
    expect(gentle[2].value, '6/10');

    final ride = shareCardMetrics(data(type: ActivityType.ride, gentle: true), c);
    expect(ride.map((m) => m.label), ['Distancia', 'Tempo', 'Subida']);
  });

  test('texto compartilhado sem ritmo no Modo Gentil', () {
    expect(
      activityShareText(
        title: 'Longao',
        type: ActivityType.run,
        distanceMeters: 5000,
        timerMs: 1500000,
        metric: true,
        gentle: true,
      ),
      'Longao\nCorrida | 5.00 km | 25:00',
    );
  });

  testWidgets('tela Compartilhar com Modo Gentil: imagem sem pace', (tester) async {
    final db = RecordingDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final dir = Directory.systemTemp.createTempSync('share_gentle');
    addTearDown(() => dir.deleteSync(recursive: true));
    final repo = RecordingRepository(db);
    await repo.startActivity(guid: 'a', type: ActivityType.run, startTimestampMs: 1000);
    await repo.appendWaypoints('a', [
      for (var i = 0; i < 3; i++)
        dom.Waypoint(
          position: GeoPoint(latitude: i * 0.005, longitude: 0),
          cumulativeDistanceMeters: i * 600.0,
          elapsedTimeMs: i * 180000,
          timerTimeMs: i * 180000,
          classification: dom.WaypointClassification.accept,
        ),
    ]);
    await repo.finish('a', 361000, distanceMeters: 1200, timerTimeMs: 360000);
    await repo.saveDetails('a', title: 'Parque', rpe: 4);
    await db.saveSettings(gentleMode: true);

    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final activity = (await repo.recent()).single;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        recordingDatabaseProvider.overrideWithValue(db),
        activitySharerProvider.overrideWithValue(FakeActivitySharer()),
        shareImageDirectoryProvider.overrideWithValue(() async => dir),
      ],
      child: MaterialApp(theme: AppTheme.dark, home: ShareActivityScreen(activity: activity)),
    ));
    await tester.pumpAndSettle();
    final card = find.byType(ShareCard);
    expect(find.descendant(of: card, matching: find.text('Pace')), findsNothing);
    expect(find.descendant(of: card, matching: find.textContaining('/km')), findsNothing);
    expect(find.descendant(of: card, matching: find.text('Esforco')), findsOneWidget);
  });

  testWidgets('cartao do feed no Modo Gentil: esforco no lugar do pace', (tester) async {
    final a = Activity(
      guid: 'g',
      activityType: ActivityType.run,
      startTimestampMs: 0,
      timerTimeMs: 1500000,
      distanceMeters: 5000,
      isIndoor: false,
      isFinished: true,
      syncState: SyncState.synced,
      autoPauseEnabled: true,
      visibility: 'private',
      hideEdgesMeters: 0,
      heartbeatPaused: false,
      discardedPointCount: 0,
      rpe: 8,
    );
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: ActivityCard(activity: a, useMetric: true, compact: true, gentle: true),
      ),
    ));
    expect(find.text('Pace'), findsNothing);
    expect(find.textContaining('/km'), findsNothing);
    expect(find.text('Esforco'), findsOneWidget);
    expect(find.text('8/10'), findsOneWidget);
  });
}
