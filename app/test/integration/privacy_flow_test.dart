// Integracao da Privacidade automatica (F02): tres gravacoes reais (controller
// com fakes) saindo de casa -> sugestao "parece que aqui e sua casa" ->
// aceitar -> a tela Compartilhar mostra a rota cortada com a etiqueta -> o
// upload leva o FIT sem as pontas, com distancia e tempo totais -> a
// atividade nova nasce "so eu". Banco Drift em memoria.
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/persistence/recording_repository.dart';
import 'package:strava_estudo_app/platform/activity_sharer.dart';
import 'package:strava_estudo_app/privacy/domain/route_trim.dart';
import 'package:strava_estudo_app/privacy/privacy_repository.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/location_sample.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/presentation/recording_controller.dart';
import 'package:strava_estudo_app/sync/upload/activity_uploader.dart';
import 'package:strava_estudo_app/sync/upload/fit_activity_builder.dart';
import 'package:strava_estudo_app/sync/upload/sync_service.dart';
import 'package:strava_estudo_app/ui/route_preview.dart';
import 'package:strava_estudo_app/ui/share/share_activity_screen.dart';
import 'package:strava_estudo_app/ui/theme/app_theme.dart';

import '../fixtures/fake_sharer.dart';
import '../recording/fakes.dart';

/// Ponto i da rota que sai de casa (0, 0) para leste, ~11 m por segundo.
LocationSample s(int i) => LocationSample(
  position: GeoPoint(latitude: 0, longitude: 0.0001 * i, altitudeMeters: 100),
  wallClockMs: 1000 * i,
  monotonicMs: 1000 * i,
  horizontalAccuracyMeters: 5,
  verticalAccuracyMeters: 3,
  speedMetersPerSecond: 11,
);

class CapturingUploader implements ActivityUploader {
  final Map<String, (Uint8List, UploadMetadata?)> sent = {};
  @override
  Future<String> upload(Uint8List fitBytes, {required String activityGuid, UploadMetadata? metadata}) async {
    sent[activityGuid] = (fitBytes, metadata);
    return 'r-$activityGuid';
  }
}

void main() {
  testWidgets('casa detectada, imagem e upload cortados, nova atividade so eu', (tester) async {
    final db = RecordingDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = RecordingRepository(db);
    final privacy = PrivacyRepository(db);
    final guids = <String>[];

    // 1) Tres gravacoes de tamanhos diferentes, todas saindo de casa.
    await tester.runAsync(() async {
      for (final pontos in [120, 200, 280]) {
        final source = FakeLocationSource();
        final c = RecordingController(
          source: source,
          repo: repo,
          service: FakeRecordingService(),
        );
        await c.start(ActivityType.run, autoPauseEnabled: false);
        for (var i = 0; i < pontos; i++) {
          source.add(s(i));
        }
        await pumpEventQueue(times: 50);
        guids.add(c.activityGuid!);
        await c.stop();
        await pumpEventQueue(times: 20);
        c.dispose();
      }
    });

    // Atividade nova nasce "so eu".
    final a0 = (await tester.runAsync(() => repo.activity(guids[0])))!;
    expect(ActivityVisibility.fromDb(a0.visibility), ActivityVisibility.onlyMe);

    // 2) A sugestao aparece so para a casa (os fins sao diferentes).
    final suggestions = (await tester.runAsync(privacy.suggestions))!;
    expect(suggestions, hasLength(1));
    expect(haversineMeters(suggestions.single.center, const GeoPoint(latitude: 0, longitude: 0)),
        lessThan(30));

    // 3) Aceita.
    await tester.runAsync(() => privacy.addZone(suggestions.single.toZone()));
    expect((await tester.runAsync(privacy.suggestions))!, isEmpty);

    // 4) Tela Compartilhar: rota cortada com etiqueta.
    final dir = Directory.systemTemp.createTempSync('priv_flow');
    addTearDown(() => dir.deleteSync(recursive: true));
    final last = (await tester.runAsync(() => repo.activity(guids.last)))!;
    final full = (await tester.runAsync(() => repo.routePoints(guids.last)))!;
    await tester.binding.setSurfaceSize(const Size(420, 960));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ProviderScope(
      overrides: [
        recordingDatabaseProvider.overrideWithValue(db),
        activitySharerProvider.overrideWithValue(FakeActivitySharer()),
        shareImageDirectoryProvider.overrideWithValue(() async => dir),
      ],
      child: MaterialApp(theme: AppTheme.dark, home: ShareActivityScreen(activity: last)),
    ));
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.text('Inicio e fim ocultos'), findsOneWidget);
    final shown = tester.widget<RoutePreview>(find.byKey(const Key('share_card_route'))).route;
    expect(shown.length, lessThan(full.length));
    // O primeiro ponto mostrado esta fora do raio de corte desta atividade.
    expect(
      haversineMeters(const GeoPoint(latitude: 0, longitude: 0), shown.first),
      greaterThan(cutRadiusForActivity(last.guid)),
    );

    // 5) Upload: FIT so com os pontos visiveis e totais preservados.
    final up = CapturingUploader();
    await tester.runAsync(() => SyncService(db, up).processPending());
    expect(up.sent.keys, unorderedEquals(guids));
    final (fit, meta) = up.sent[last.guid]!;
    final visible = (await tester.runAsync(() => privacy.exportWaypoints(last)))!;
    expect(visible.length, shown.length);
    expect(fit, buildFitFromWaypoints(last, visible));
    expect(meta!.distanceMeters, last.distanceMeters);
    expect(meta.timerTimeMs, last.timerTimeMs);
  });
}
