// Tela Compartilhar: previa do cartao, troca de estilo, imagem PNG de
// 1080 x 1920 gravada na pasta de compartilhar, so texto e falha da
// plataforma.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/persistence/recording_repository.dart';
import 'package:strava_estudo_app/platform/activity_sharer.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/domain/waypoint.dart' as dom;
import 'package:strava_estudo_app/ui/share/share_activity_screen.dart';
import 'package:strava_estudo_app/ui/share/share_card.dart';
import 'package:strava_estudo_app/ui/theme/app_theme.dart';

import '../fixtures/fake_sharer.dart';

dom.Waypoint acc(double lat, double dist, double alt, int t) => dom.Waypoint(
  position: GeoPoint(latitude: lat, longitude: lat / 2, altitudeMeters: alt),
  cumulativeDistanceMeters: dist,
  elapsedTimeMs: t,
  timerTimeMs: t,
  classification: dom.WaypointClassification.accept,
  horizontalAccuracyMeters: 5,
  verticalAccuracyMeters: 2,
);

void main() {
  late RecordingDatabase db;
  late Directory dir;
  late FakeActivitySharer sharer;

  setUp(() async {
    db = RecordingDatabase(NativeDatabase.memory());
    dir = Directory.systemTemp.createTempSync('share_test');
    sharer = FakeActivitySharer();
    final repo = RecordingRepository(db);
    final start = DateTime(2026, 10, 26, 7).millisecondsSinceEpoch;
    await repo.startActivity(guid: 'a', type: ActivityType.run, startTimestampMs: start);
    await repo.appendWaypoints('a', [
      acc(0.0, 0, 100, 0),
      acc(0.005, 600, 130, 180000),
      acc(0.01, 1200, 160, 360000),
    ]);
    await repo.finish('a', start + 360000, distanceMeters: 1200, timerTimeMs: 360000);
    await repo.saveDetails('a', title: 'Treino no parque');
  });

  tearDown(() async {
    await db.close();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final activity = (await RecordingRepository(db).recent()).single;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        recordingDatabaseProvider.overrideWithValue(db),
        activitySharerProvider.overrideWithValue(sharer),
        shareImageDirectoryProvider.overrideWithValue(() async => dir),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: ShareActivityScreen(activity: activity),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('previa mostra titulo, metricas e rota; estilo troca', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Treino no parque'), findsOneWidget);
    expect(find.byKey(const Key('share_card_route')), findsOneWidget);
    for (final label in ['Distancia', 'Pace', 'Tempo', 'Subida']) {
      expect(find.byKey(Key('share_metric_$label')), findsOneWidget);
    }
    ShareCard card() => tester.widget<ShareCard>(find.byKey(const Key('share_card')));
    expect(card().style, ShareCardStyle.card);

    await tester.tap(find.byKey(const Key('share_style_transparent')));
    await tester.pumpAndSettle();
    expect(card().style, ShareCardStyle.transparent);
  });

  testWidgets('Compartilhar imagem grava PNG 1080x1920 e manda com o texto', (tester) async {
    await pumpScreen(tester);
    // Uma imagem antiga na pasta e apagada.
    File('${dir.path}/velha.png').writeAsBytesSync([1, 2, 3]);

    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('share_image')));
      // Captura e escrita do arquivo sao assincronas de verdade.
      for (var i = 0; i < 50 && sharer.images.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await tester.pump();
      }
    });
    await tester.pump();

    final shared = sharer.images.single;
    expect(shared.path, endsWith('rastro-a.png'));
    expect(shared.text, startsWith('Treino no parque\n'));
    expect(File('${dir.path}/velha.png').existsSync(), isFalse);

    final size = await tester.runAsync(() async {
      final bytes = File(shared.path).readAsBytesSync();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return Size(frame.image.width.toDouble(), frame.image.height.toDouble());
    });
    expect(size, const Size(1080, 1920));
  });

  testWidgets('So o texto manda o resumo sem imagem', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.byKey(const Key('share_text_only')));
    await tester.pump();
    expect(sharer.texts, ['Treino no parque\nCorrida | 1,20 km | 6:00 | 5:00 /km']);
    expect(sharer.images, isEmpty);
  });

  testWidgets('falha da plataforma vira SnackBar', (tester) async {
    sharer.fail = true;
    await pumpScreen(tester);
    await tester.tap(find.byKey(const Key('share_text_only')));
    await tester.pump();
    expect(find.text('Nao foi possivel compartilhar'), findsOneWidget);
  });
}
