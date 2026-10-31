// Sessao guiada do plano 5 km (F06) de ponta a ponta no host: banco Drift em
// memoria -> gravacao real (RecordingController) -> sessao guiada com relogio
// e tick falsos -> voltas, voz (fila do Narrador), vibracao e resultado.
//
// O plano anda pelos ticks: quase todos os cenarios rodam SEM ponto de GPS
// depois do inicio (tela desligada / GPS fraco), provando que nao trava.
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/auth/session_store.dart';
import 'package:strava_estudo_app/narrator/domain/narrator_settings.dart';
import 'package:strava_estudo_app/narrator/narrator_providers.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/plan5k/domain/plan_progress.dart';
import 'package:strava_estudo_app/plan5k/domain/plan_table.dart';
import 'package:strava_estudo_app/plan5k/guided_session.dart';
import 'package:strava_estudo_app/plan5k/plan_providers.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/location_sample.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';

import '../narrator/fake_voice_announcer.dart';
import '../recording/fakes.dart';

const s = 1000;

/// Plano de teste: 3 sessoes por semana iguais, blocos de 30 s.
/// Aquece 30 s, corre 30 s, caminha 30 s, corre 30 s, desacelera 30 s = 150 s.
const testSession = [
  PlanBlock(BlockKind.warmup, 30 * s),
  PlanBlock(BlockKind.run, 30 * s),
  PlanBlock(BlockKind.walk, 30 * s),
  PlanBlock(BlockKind.run, 30 * s),
  PlanBlock(BlockKind.cooldown, 30 * s),
];
final testTable = [
  for (var w = 1; w <= kPlanWeeks; w++)
    for (var n = 1; n <= kSessionsPerWeek; n++)
      PlanSession(week: w, number: n, blocks: testSession),
];

class FakeHaptics implements PlanHaptics {
  int changes = 0;
  int warnings = 0;
  @override
  Future<void> blockChange() async => changes++;
  @override
  Future<void> warning() async => warnings++;
}

LocationSample p(int i) => LocationSample(
  position: GeoPoint(latitude: 0, longitude: 0.00002 * i, altitudeMeters: 100),
  wallClockMs: 1000 * i,
  monotonicMs: 1000 * i,
  horizontalAccuracyMeters: 5,
  verticalAccuracyMeters: 3,
  speedMetersPerSecond: 2.2,
);

void main() {
  late RecordingDatabase db;
  late FakeLocationSource source;
  late FakeVoiceAnnouncer voice;
  late FakeHaptics haptics;
  late FakeHeartbeatTicker ticker;
  late FakeRecordingService service;
  late ProviderContainer container;
  var nowMs = 0;

  ProviderContainer build() => ProviderContainer(
    overrides: [
      recordingDatabaseProvider.overrideWithValue(db),
      locationSourceProvider.overrideWithValue(source),
      recordingServiceProvider.overrideWithValue(service),
      sessionStoreProvider.overrideWithValue(InMemorySessionStore()),
      voiceAnnouncerProvider.overrideWithValue(voice),
      planHapticsProvider.overrideWithValue(haptics),
      planTickerProvider.overrideWithValue(ticker),
      planMonotonicNowProvider.overrideWithValue(() => nowMs),
      plan5kTableProvider.overrideWithValue(testTable),
    ],
  );

  setUp(() {
    db = RecordingDatabase(NativeDatabase.memory());
    source = FakeLocationSource();
    voice = FakeVoiceAnnouncer();
    haptics = FakeHaptics();
    ticker = FakeHeartbeatTicker();
    service = FakeRecordingService();
    nowMs = 0;
    container = build();
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> settle() => pumpEventQueue(times: 30);

  /// Avanca o relogio de [seconds] em passos de 1 s, com um tick por passo.
  Future<void> tickFor(int seconds) async {
    for (var i = 0; i < seconds; i++) {
      nowMs += 1000;
      ticker.tick();
      await settle();
    }
  }

  Future<GuidedSessionController> startGuided({int week = 1}) async {
    await container.read(settingsProvider.notifier).ensureLoaded();
    final plan = container.read(planServiceProvider);
    if (!(await plan.progress()).state.started) await plan.startPlan(week);
    final next = (await plan.progress()).next!;
    final g = container.read(guidedSessionProvider.notifier);
    final ctrl = container.read(recordingControllerProvider.notifier);
    await ctrl.start(ActivityType.run, autoPauseEnabled: false);
    source.add(p(0));
    await settle();
    await g.begin(next, round: 0);
    await settle();
    return g;
  }

  test('sessao inteira so com ticks (sem GPS): voltas, falas, vibracao e concluida', () async {
    final g = await startGuided();
    final ctrl = container.read(recordingControllerProvider.notifier);
    final guid = ctrl.activityGuid!;
    expect(voice.spoken, ['Aquecimento. Caminhe por 30 segundos.']);
    expect(container.read(guidedSessionProvider)!.view.index, 0);
    // Notificacao mostra o bloco atual.
    expect(service.updates.last.text, contains('Plano: Aquecer caminhando 30 s (bloco 1 de 5)'));

    await tickFor(20);
    expect(voice.spoken.last, 'Faltam 10 segundos para correr.');
    expect(haptics.warnings, 1);
    await tickFor(10);
    expect(voice.spoken.last, 'Corra por 30 segundos.');
    expect(haptics.changes, 1);
    expect(container.read(recordingControllerProvider).completedLaps, 1);
    expect(service.updates.last.text, contains('Plano: Correr 30 s (bloco 2 de 5)'));

    await tickFor(45); // 75 s: metade da sessao, dentro da caminhada
    expect(voice.spoken, contains('Caminhe por 30 segundos.'));
    expect(voice.spoken.last, 'Metade da sessao.');
    await tickFor(15); // 90 s: ultima corrida
    expect(voice.spoken.last, 'Ultimo bloco de corrida. Corra por 30 segundos.');
    await tickFor(30); // 120 s: fim das corridas
    expect(voice.spoken.last, 'Corridas de hoje concluidas. Caminhe 30 segundos para desacelerar.');
    await tickFor(30); // 150 s: fim
    expect(voice.spoken.last, 'Plano de hoje concluido.');
    expect(container.read(recordingControllerProvider).completedLaps, 5);
    expect(container.read(guidedSessionProvider)!.view.completed, isTrue);
    // Verificacao do F06: o tempo em movimento da GRAVACAO nao anda sem ponto
    // de GPS (o relogio da sessao so avanca na amostra). Por isso o plano tem
    // relogio proprio: ele andou 150 s enquanto a gravacao ficou parada.
    expect(container.read(recordingControllerProvider).timerMs, 0);
    expect(container.read(guidedSessionProvider)!.view.elapsedMs, 150 * s);
    // Nenhuma fala do plano tem ritmo.
    expect(voice.spoken.where((t) => t.toLowerCase().contains('pace')), isEmpty);

    await ctrl.stop();
    expect(await g.whenFinished, SessionStatus.done);
    final r = (await container.read(planRepositoryProvider).results()).single;
    expect(r.activityGuid, guid);
    expect(r.status, SessionStatus.done);
    expect(r.movingMs, 150 * s);
    final progress = await container.read(planServiceProvider).progress();
    expect(progress.next!.number, 2);
  });

  test('pontos de GPS e ticks juntos nao contam o tempo em dobro', () async {
    await startGuided();
    for (var i = 1; i <= 30; i++) {
      nowMs += 1000;
      source.add(p(i));
      await settle();
      ticker.tick();
      await settle();
    }
    expect(container.read(guidedSessionProvider)!.view.elapsedMs, 30 * s);
    expect(container.read(recordingControllerProvider).completedLaps, 1);
    await container.read(recordingControllerProvider.notifier).stop();
  });

  test('pausa manual congela o plano; retomar continua de onde parou', () async {
    await startGuided();
    final ctrl = container.read(recordingControllerProvider.notifier);
    await tickFor(10);
    ctrl.pause();
    await settle();
    await tickFor(120);
    final v = container.read(guidedSessionProvider)!.view;
    expect(v.elapsedMs, 10 * s);
    expect(v.index, 0);
    expect(container.read(recordingControllerProvider).completedLaps, 0);
    ctrl.resume();
    await settle();
    await tickFor(20);
    expect(container.read(guidedSessionProvider)!.view.elapsedMs, 30 * s);
    expect(container.read(guidedSessionProvider)!.view.index, 1);
    await ctrl.stop();
  });

  test('pausa automatica (decidida no ponto de GPS) tambem congela', () async {
    await container.read(settingsProvider.notifier).ensureLoaded();
    final plan = container.read(planServiceProvider);
    await plan.startPlan(1);
    final next = (await plan.progress()).next!;
    final ctrl = container.read(recordingControllerProvider.notifier);
    await ctrl.start(ActivityType.walk, autoPauseEnabled: true);
    final g = container.read(guidedSessionProvider.notifier);
    await g.begin(next, round: 0);
    // Pontos parados (velocidade 0) por 15 s levam a pausa automatica.
    for (var i = 0; i < 15; i++) {
      nowMs = i * 1000;
      source.add(LocationSample(
        position: const GeoPoint(latitude: 0, longitude: 0),
        wallClockMs: i * 1000,
        monotonicMs: i * 1000,
        horizontalAccuracyMeters: 5,
        speedMetersPerSecond: 0,
      ));
      ticker.tick();
      await settle();
    }
    expect(container.read(recordingControllerProvider).state, RecordingState.autoPaused);
    final frozen = container.read(guidedSessionProvider)!.view.elapsedMs;
    await tickFor(60);
    expect(container.read(guidedSessionProvider)!.view.elapsedMs, frozen);
    await ctrl.stop();
  });

  test('encerrar no meio: parcial, a proxima sessao continua a mesma', () async {
    final g = await startGuided();
    final ctrl = container.read(recordingControllerProvider.notifier);
    await tickFor(100); // 100 de 150 s = 67%
    await ctrl.stop();
    expect(await g.whenFinished, SessionStatus.partial);
    expect(container.read(guidedSessionProvider)!.result, SessionStatus.partial);
    final progress = await container.read(planServiceProvider).progress();
    expect(progress.next!.number, 1);
    expect(progress.markOf(1, 1), SessionMark.partial);
  });

  test('um segundo antes do desaquecimento ainda e parcial', () async {
    final g = await startGuided();
    await tickFor(119);
    await container.read(recordingControllerProvider.notifier).stop();
    expect(await g.whenFinished, SessionStatus.partial);
  });

  test('chegar no desaquecimento (sem terminar) ja conta como concluida', () async {
    final g = await startGuided();
    await tickFor(120);
    await container.read(recordingControllerProvider.notifier).stop();
    expect(await g.whenFinished, SessionStatus.done);
  });

  test('salto grande entre ticks: fecha as voltas certas e fala so o bloco atual', () async {
    await startGuided();
    voice.spoken.clear();
    nowMs += 100 * s; // app suspenso: um tick so depois de 100 s
    ticker.tick();
    await settle();
    expect(container.read(recordingControllerProvider).completedLaps, 3);
    expect(voice.spoken, ['Ultimo bloco de corrida. Corra por 30 segundos.']);
    expect(haptics.changes, 1);
    await container.read(recordingControllerProvider.notifier).stop();
  });

  test('voz do plano desligada: nada falado, mas vibra e fecha as voltas', () async {
    await container.read(settingsProvider.notifier).setPlan5kVoice(false);
    await startGuided();
    await tickFor(60);
    expect(voice.spoken, isEmpty);
    expect(haptics.changes, 2);
    expect(container.read(recordingControllerProvider).completedLaps, 2);
    await container.read(recordingControllerProvider.notifier).stop();
  });

  test('narrador geral ligado: a troca de bloco tem prioridade e as voltas nao sao faladas', () async {
    final settings = container.read(settingsProvider.notifier);
    await settings.ensureLoaded();
    await settings.setNarrator(const NarratorSettings(enabled: true, timeEveryMinutes: 1));
    container.read(recordingNarrationProvider);
    await startGuided();
    expect(voice.spoken, ['Corrida iniciada.', 'Aquecimento. Caminhe por 30 segundos.']);
    await tickFor(30);
    expect(voice.spoken.last, 'Corra por 30 segundos.');
    expect(voice.spoken.where((t) => t.startsWith('Volta')), isEmpty);
    await container.read(recordingControllerProvider.notifier).stop();
  });

  test('descartar a gravacao: a sessao nao conta', () async {
    final g = await startGuided();
    await tickFor(140);
    g.abandon();
    await container.read(recordingControllerProvider.notifier).stop();
    expect(await g.whenFinished, isNull);
    expect(container.read(guidedSessionProvider), isNull);
    expect(await container.read(planRepositoryProvider).results(), isEmpty);
  });

  test('crash e recuperacao: o plano continua do ponto salvo, sem repetir falas', () async {
    await startGuided();
    final ctrl = container.read(recordingControllerProvider.notifier);
    final guid = ctrl.activityGuid!;
    await tickFor(45); // 45 s: troca aos 30 s salvou 30 s; 15 s depois salvou 45 s
    // App morto: some o container, o banco fica.
    container.dispose();
    voice.spoken.clear();
    nowMs = 1000000;
    source = FakeLocationSource();
    ticker = FakeHeartbeatTicker();
    container = build();
    await container.read(settingsProvider.notifier).ensureLoaded();

    final interrupted = (await container.read(recordingRepositoryProvider).interrupted()).single;
    expect(interrupted.activity.guid, guid);
    final ctrl2 = container.read(recordingControllerProvider.notifier);
    await ctrl2.resumeInterrupted(interrupted);
    final g2 = container.read(guidedSessionProvider.notifier);
    expect(await g2.resume(guid), isTrue);
    await settle();
    final v = container.read(guidedSessionProvider)!.view;
    expect(v.elapsedMs, 45 * s);
    expect(v.index, 1);
    expect(voice.spoken, ['Sessao retomada. Corra por mais 15 segundos.']);
    await tickFor(15);
    expect(voice.spoken.last, 'Caminhe por 30 segundos.');
    await tickFor(105);
    await ctrl2.stop();
    expect(await g2.whenFinished, SessionStatus.done);
  });

  test('recuperacao de gravacao comum nao liga plano', () async {
    final g = container.read(guidedSessionProvider.notifier);
    expect(await g.resume('act_qualquer'), isFalse);
    expect(container.read(guidedSessionProvider), isNull);
  });

  test('repete a semana quando uma sessao concluida teve RPE >= 8', () async {
    final plan = container.read(planServiceProvider);
    final repo = container.read(recordingRepositoryProvider);
    for (var n = 1; n <= 3; n++) {
      final g = await startGuided();
      final guid = container.read(recordingControllerProvider.notifier).activityGuid!;
      await tickFor(150);
      await repo.saveDetails(guid, rpe: n == 2 ? 9 : 4);
      await container.read(recordingControllerProvider.notifier).stop();
      expect(await g.whenFinished, SessionStatus.done);
      nowMs += 10000;
      // O controller da gravacao gera o guid pelo relogio de parede: espera
      // um milissegundo para nao repetir.
      await Future<void>.delayed(const Duration(milliseconds: 2));
      if (n < 3) expect(await plan.resolveWeek(), isNull);
    }
    expect(await plan.resolveWeek(), WeekResolution.suggestRepeat);
    await plan.repeatWeek();
    final p = await plan.progress();
    expect(p.state.repeatsOf(1), 1);
    expect(p.next!.week, 1);
    expect(p.next!.number, 1);
  });
}
