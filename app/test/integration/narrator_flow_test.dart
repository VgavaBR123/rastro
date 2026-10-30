// Integracao do Narrador por voz (F03): preferencias salvas no banco Drift em
// memoria -> gravacao real (RecordingController + dominio) alimentada por GPS
// falso -> ponte -> fila -> voz falsa. Confere o que seria falado do inicio ao
// fim, sem sobreposicao.
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/auth/session_store.dart';
import 'package:strava_estudo_app/narrator/domain/announcement.dart';
import 'package:strava_estudo_app/narrator/domain/narrator_settings.dart';
import 'package:strava_estudo_app/narrator/narrator_providers.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/location_sample.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';

import '../narrator/fake_voice_announcer.dart';
import '../recording/fakes.dart';

/// Reta para leste a ~4,45 m/s, uma amostra por segundo.
LocationSample p(int i) => LocationSample(
  position: GeoPoint(latitude: 0, longitude: 0.00004 * i, altitudeMeters: 100),
  wallClockMs: 1000 * i,
  monotonicMs: 1000 * i,
  horizontalAccuracyMeters: 5,
  verticalAccuracyMeters: 3,
  speedMetersPerSecond: 4.45,
);

void main() {
  late RecordingDatabase db;
  late FakeLocationSource source;
  late FakeVoiceAnnouncer voice;
  late ProviderContainer container;

  setUp(() {
    db = RecordingDatabase(NativeDatabase.memory());
    source = FakeLocationSource();
    voice = FakeVoiceAnnouncer();
    container = ProviderContainer(
      overrides: [
        recordingDatabaseProvider.overrideWithValue(db),
        locationSourceProvider.overrideWithValue(source),
        sessionStoreProvider.overrideWithValue(InMemorySessionStore()),
        voiceAnnouncerProvider.overrideWithValue(voice),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> settle() => pumpEventQueue(times: 20);

  Future<void> run({required int seconds, int from = 0}) async {
    for (var i = from; i < from + seconds; i++) {
      source.add(p(i));
      await settle();
    }
  }

  test('corrida com o narrador ligado: inicio, km, pausa, volta e fim', () async {
    final settings = container.read(settingsProvider.notifier);
    await settings.ensureLoaded();
    await settings.setNarrator(const NarratorSettings(enabled: true));

    container.read(recordingNarrationProvider);
    final ctrl = container.read(recordingControllerProvider.notifier);
    await ctrl.start(ActivityType.run, autoPauseEnabled: false);
    await settle();

    await run(seconds: 240); // passa de 1 km
    ctrl.pause();
    await settle();
    ctrl.resume();
    await settle();
    await run(seconds: 10, from: 240);
    await ctrl.lap();
    await settle();
    await ctrl.stop();
    await container.read(narratorProvider).whenIdle();

    expect(voice.spoken.first, 'Corrida iniciada.');
    expect(voice.spoken[1], startsWith('Um quilômetro. Tempo '));
    expect(voice.spoken[1], contains('Pace do quilômetro três e '));
    expect(voice.spoken[2], 'Gravação pausada.');
    expect(voice.spoken[3], 'Gravação retomada.');
    expect(voice.spoken[4], startsWith('Volta um. Tempo da volta quatro minutos'));
    expect(voice.spoken.last, startsWith('Corrida encerrada. Distância um vírgula'));
    expect(voice.spoken, hasLength(6));
    expect(voice.maxConcurrent, 1);

    // A preferencia ficou no banco.
    final row = await db.loadSettings();
    expect(NarratorSettings.fromJsonString(row.narratorPrefs).enabled, isTrue);
  });

  test('descartar: o resumo de fim nao e falado e a proxima gravacao fala', () async {
    final settings = container.read(settingsProvider.notifier);
    await settings.ensureLoaded();
    await settings.setNarrator(const NarratorSettings(enabled: true));
    final bridge = container.read(recordingNarrationProvider);
    final ctrl = container.read(recordingControllerProvider.notifier);
    await ctrl.start(ActivityType.run, autoPauseEnabled: false);
    await run(seconds: 30);
    ctrl.pause();
    await settle();
    bridge.suppressNextFinish();
    await ctrl.stop();
    await container.read(narratorProvider).whenIdle();
    expect(voice.spoken, ['Corrida iniciada.', 'Gravação pausada.']);

    await ctrl.start(ActivityType.run, autoPauseEnabled: false);
    await run(seconds: 30, from: 30);
    await ctrl.stop();
    await container.read(narratorProvider).whenIdle();
    expect(voice.spoken.last, startsWith('Corrida encerrada.'));
  });

  test('narrador desligado (padrao): a gravacao fica muda', () async {
    await container.read(settingsProvider.notifier).ensureLoaded();
    container.read(recordingNarrationProvider);
    final ctrl = container.read(recordingControllerProvider.notifier);
    await ctrl.start(ActivityType.walk, autoPauseEnabled: false);
    await run(seconds: 240);
    await ctrl.stop();
    await container.read(narratorProvider).whenIdle();
    expect(voice.spoken, isEmpty);
  });

  test('desligar no meio cala e nada mais e dito', () async {
    final settings = container.read(settingsProvider.notifier);
    await settings.ensureLoaded();
    await settings.setNarrator(const NarratorSettings(enabled: true));
    container.read(recordingNarrationProvider);
    final ctrl = container.read(recordingControllerProvider.notifier);
    await ctrl.start(ActivityType.ride, autoPauseEnabled: false);
    await settle();
    expect(voice.spoken, ['Pedal iniciado.']);
    await settings.setNarratorEnabled(false);
    await run(seconds: 240);
    await ctrl.stop();
    await container.read(narratorProvider).whenIdle();
    expect(voice.spoken, ['Pedal iniciado.']);
  });

  test('API generica: outra feature enfileira com prioridade na mesma voz', () async {
    final slow = FakeVoiceAnnouncer(autoComplete: false);
    final c = ProviderContainer(overrides: [voiceAnnouncerProvider.overrideWithValue(slow)]);
    addTearDown(c.dispose);
    final n = c.read(narratorProvider);
    n.say('Corra por um minuto.');
    await settle();
    n.say('Frequência cardíaca alta.', priority: AnnouncementPriority.critical);
    await settle();
    expect(slow.stops, 1);
    expect(slow.spoken, ['Corra por um minuto.', 'Frequência cardíaca alta.']);
    slow.finishCurrent();
    await n.whenIdle();
  });

  test('gancho do Modo Gentil por provider', () async {
    final c = ProviderContainer(
      overrides: [
        voiceAnnouncerProvider.overrideWithValue(voice),
        announcementFilterProvider.overrideWithValue(
          (a) => Announcement('${a.text} Muito bem.', priority: a.priority),
        ),
      ],
    );
    addTearDown(c.dispose);
    c.read(narratorProvider).say('Um quilômetro.');
    await c.read(narratorProvider).whenIdle();
    expect(voice.spoken, ['Um quilômetro. Muito bem.']);
  });
}
