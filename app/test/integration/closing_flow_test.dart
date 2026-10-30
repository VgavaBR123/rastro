// Integracao do Fechamento gentil (F04): duas gravacoes reais (controller com
// fakes, relogio injetado) -> Salvar com RPE e humor -> frases que comparam a
// pessoa com ela mesma -> Estatisticas com a carga da semana -> upload com
// x-rpe e x-mood nos metadados. Com o Modo Gentil, as frases nunca falam de
// rapidez. Banco Drift em memoria.
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/activity/stats_summary.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/auth/session_store.dart';
import 'package:strava_estudo_app/closing/closing_service.dart';
import 'package:strava_estudo_app/closing/domain/effort.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/persistence/recording_repository.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/location_sample.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/presentation/recording_controller.dart';
import 'package:strava_estudo_app/sync/upload/activity_uploader.dart';
import 'package:strava_estudo_app/sync/upload/dio_activity_uploader.dart';
import 'package:strava_estudo_app/sync/upload/sync_service.dart';

import '../recording/fakes.dart';

const int _dayMs = 24 * 60 * 60 * 1000;

/// Ponto i, ~11 m por segundo para leste.
LocationSample s(int i, int t0) => LocationSample(
  position: GeoPoint(latitude: 0, longitude: 0.0001 * i, altitudeMeters: 100),
  wallClockMs: t0 + 1000 * i,
  monotonicMs: 1000 * i,
  horizontalAccuracyMeters: 5,
  verticalAccuracyMeters: 3,
  speedMetersPerSecond: 11,
);

class CapturingUploader implements ActivityUploader {
  final Map<String, UploadMetadata?> sent = {};
  @override
  Future<String> upload(Uint8List fitBytes, {required String activityGuid, UploadMetadata? metadata}) async {
    sent[activityGuid] = metadata;
    return 'r-$activityGuid';
  }
}

void main() {
  test('gravar, salvar com esforco, frases, carga e upload', () async {
    final db = RecordingDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = RecordingRepository(db);
    // Terca e quinta da mesma semana, as 7h.
    final t1 = DateTime(2026, 10, 20, 7).millisecondsSinceEpoch;
    final t2 = t1 + 2 * _dayMs;

    Future<String> record(int t0, int pontos, {int? rpe, Mood? mood}) async {
      var clock = t0;
      final source = FakeLocationSource();
      final c = RecordingController(
        source: source,
        repo: repo,
        service: FakeRecordingService(),
        now: () => clock,
      );
      await c.start(ActivityType.run, autoPauseEnabled: false);
      for (var i = 0; i < pontos; i++) {
        clock = t0 + 1000 * i;
        source.add(s(i, t0));
      }
      await pumpEventQueue(times: 50);
      final guid = c.activityGuid!;
      await c.stop();
      await pumpEventQueue(times: 20);
      c.dispose();
      await repo.saveDetails(guid, title: 'Treino', rpe: rpe, mood: mood);
      return guid;
    }

    final first = await record(t1, 120, rpe: 4, mood: Mood.good);
    final firstPhrases = await ClosingService(repo).phrasesFor(first, gentle: false, metric: true);
    expect(firstPhrases.first, 'Sua primeira corrida registrada aqui. Bom comeco.');
    expect(firstPhrases.length, inInclusiveRange(2, 3));

    final second = await record(t2, 240, rpe: 7, mood: Mood.tired);
    final saved = (await repo.activity(second))!;
    expect(saved.rpe, 7);
    expect(Mood.fromDb(saved.mood), Mood.tired);

    final phrases = await ClosingService(repo).phrasesFor(second, gentle: false, metric: true);
    expect(phrases, contains('Sua corrida mais longa das ultimas 4 semanas.'));
    expect(phrases.length, inInclusiveRange(2, 3));
    final gentle = await ClosingService(repo).phrasesFor(second, gentle: true, metric: true);
    expect(gentle.any((p) => p.contains('rapid')), isFalse);

    // Estatisticas: carga da semana = soma de RPE x minutos das duas.
    final container = ProviderContainer(overrides: [
      recordingDatabaseProvider.overrideWithValue(db),
      sessionStoreProvider.overrideWithValue(InMemorySessionStore()),
      statsClockProvider.overrideWithValue(() => DateTime.fromMillisecondsSinceEpoch(t2 + 3600000)),
    ]);
    addTearDown(container.dispose);
    final sub = container.listen(statsProvider, (_, _) {});
    addTearDown(sub.close);
    final stats = await container.read(statsProvider.future);
    final a1 = (await repo.activity(first))!;
    final expected = trainingLoad(rpe: 4, timerMs: a1.timerTimeMs)! +
        trainingLoad(rpe: 7, timerMs: saved.timerTimeMs)!;
    expect(stats.summary.weeks.last.load, expected);
    expect(stats.summary.loadTotal(StatsPeriod.week), expected);

    // Upload: RPE e humor nos metadados e nos headers do contrato.
    final up = CapturingUploader();
    await SyncService(db, up).processPending();
    expect(up.sent[second]!.rpe, 7);
    expect(up.sent[second]!.mood, 'tired');
    expect(metadataHeaders(up.sent[first])['x-rpe'], '4');
    expect(metadataHeaders(up.sent[first])['x-mood'], 'good');
  });
}
