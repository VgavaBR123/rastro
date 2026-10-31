// Ponte gravacao -> Narrador (F03): cada estado da gravacao vira fala
// conforme as preferencias e a unidade das Configuracoes.
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/narrator/domain/narrator_settings.dart';
import 'package:strava_estudo_app/narrator/narrator.dart';
import 'package:strava_estudo_app/narrator/recording_narration.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/domain/recording_session.dart';
import 'package:strava_estudo_app/recording/presentation/recording_ui_state.dart';

import 'fake_voice_announcer.dart';

RecordingUiState ui({
  RecordingState state = RecordingState.recording,
  double distance = 0,
  int timerMs = 0,
  List<int> km = const [],
  List<int> mi = const [],
  List<LapRecord> laps = const [],
  ActivityType type = ActivityType.run,
}) => RecordingUiState(
  state: state,
  distanceMeters: distance,
  timerMs: timerMs,
  activityType: type,
  splitDurationsKmMs: km,
  splitDurationsMileMs: mi,
  closedLaps: laps,
);

void main() {
  late FakeVoiceAnnouncer voice;
  late Narrator narrator;
  var settings = const NarratorSettings(enabled: true);
  var metric = true;
  late RecordingNarration bridge;

  setUp(() {
    voice = FakeVoiceAnnouncer();
    narrator = Narrator(voice, now: () => 0);
    settings = const NarratorSettings(enabled: true);
    metric = true;
    bridge = RecordingNarration(
      narrator: narrator,
      settings: () => settings,
      useMetric: () => metric,
    );
  });

  Future<void> feed(RecordingUiState s) async {
    bridge.onState(s);
    await narrator.whenIdle();
  }

  test('corrida: inicio, split, auto-pausa, retomada e fim', () async {
    await feed(ui());
    await feed(ui(distance: 1003, timerMs: 332000, km: [332000]));
    await feed(ui(state: RecordingState.autoPaused, distance: 1003, timerMs: 332000, km: [332000]));
    await feed(ui(distance: 1003, timerMs: 332000, km: [332000]));
    await feed(ui(state: RecordingState.finished, distance: 2000, timerMs: 600000, km: [332000, 268000]));
    expect(voice.spoken, [
      'Corrida iniciada.',
      'Um quilômetro. Tempo cinco minutos e trinta e dois segundos. '
          'Pace do quilômetro cinco e trinta e dois.',
      'Pausa automática.',
      'Gravação retomada.',
      'Corrida encerrada. Distância dois quilômetros. Tempo dez minutos. '
          'Pace médio cinco minutos.',
    ]);
  });

  test('desligado nao fala; ligar no meio nao despeja o passado', () async {
    settings = const NarratorSettings();
    await feed(ui());
    await feed(ui(distance: 2100, timerMs: 650000, km: [330000, 320000]));
    expect(voice.spoken, isEmpty);
    settings = const NarratorSettings(enabled: true);
    await feed(ui(distance: 2200, timerMs: 680000, km: [330000, 320000]));
    expect(voice.spoken, isEmpty);
    await feed(ui(distance: 3000, timerMs: 950000, km: [330000, 320000, 300000]));
    expect(voice.spoken.single, startsWith('Três quilômetros.'));
  });

  test('imperial usa os splits de milha', () async {
    metric = false;
    settings = settings.copyWith(sayTime: false);
    await feed(ui());
    await feed(ui(distance: 1100, timerMs: 300000, km: [280000]));
    expect(voice.spoken, ['Corrida iniciada.']);
    await feed(ui(distance: 1610, timerMs: 480000, km: [280000], mi: [480000]));
    expect(voice.spoken.last, 'Uma milha. Pace da milha oito minutos.');
  });

  test('gatilho de tempo vem das preferencias', () async {
    settings = settings.copyWith(timeEveryMinutes: 5, statusAnnouncements: false);
    await feed(ui());
    await feed(ui(distance: 900, timerMs: 300500));
    expect(voice.spoken, ['Cinco minutos. Distância novecentos metros. Pace médio cinco e trinta e quatro.']);
  });

  test('volta fechada', () async {
    settings = settings.copyWith(statusAnnouncements: false, essentialOnly: true);
    await feed(ui());
    await feed(ui(
      distance: 400,
      timerMs: 80000,
      laps: const [
        LapRecord(
          number: 1,
          startTimerMs: 0,
          endTimerMs: 80000,
          endElapsedMs: 80000,
          startDistanceMeters: 0,
          endDistanceMeters: 400,
        ),
      ],
    ));
    expect(voice.spoken, ['Volta um. Um minuto e vinte segundos.']);
  });

  test('sessao guiada do plano 5 km: as voltas automaticas dos blocos nao sao faladas', () async {
    var guided = true;
    bridge = RecordingNarration(
      narrator: narrator,
      settings: () => settings,
      useMetric: () => metric,
      guidedActive: () => guided,
    );
    settings = settings.copyWith(statusAnnouncements: false, essentialOnly: true);
    const lap = LapRecord(
      number: 1,
      startTimerMs: 0,
      endTimerMs: 80000,
      endElapsedMs: 80000,
      startDistanceMeters: 0,
      endDistanceMeters: 400,
    );
    await feed(ui());
    await feed(ui(distance: 400, timerMs: 80000, laps: const [lap]));
    expect(voice.spoken, isEmpty);
    // Fora do plano, volta a falar as voltas.
    guided = false;
    await feed(ui(distance: 800, timerMs: 160000, laps: const [
      lap,
      LapRecord(
        number: 2,
        startTimerMs: 80000,
        endTimerMs: 160000,
        endElapsedMs: 160000,
        startDistanceMeters: 400,
        endDistanceMeters: 800,
      ),
    ]));
    expect(voice.spoken, hasLength(1));
    expect(voice.spoken.single, startsWith('Volta dois'));
  });

  test('sessao guiada do plano 5 km: o Narrador geral fala sem ritmo (como no Modo Gentil)', () async {
    var guided = true;
    bridge = RecordingNarration(
      narrator: narrator,
      settings: () => settings,
      useMetric: () => metric,
      guidedActive: () => guided,
    );
    await feed(ui());
    await feed(ui(distance: 1003, timerMs: 332000, km: [332000]));
    final split = voice.spoken.last;
    expect(split, startsWith('Um quilômetro.'));
    expect(split.toLowerCase(), isNot(contains('pace')));
    // Fim do plano: o ritmo volta.
    guided = false;
    await feed(ui(distance: 2003, timerMs: 664000, km: [332000, 332000]));
    expect(voice.spoken.last.toLowerCase(), contains('pace'));
  });

  test('pedal diz iniciado', () async {
    await feed(ui(type: ActivityType.ride));
    expect(voice.spoken, ['Pedal iniciado.']);
  });

  test('desligar no meio cala o narrador', () async {
    final slow = FakeVoiceAnnouncer(autoComplete: false);
    final n = Narrator(slow, now: () => 0);
    final b = RecordingNarration(narrator: n, settings: () => settings, useMetric: () => true);
    b.onState(ui());
    await Future<void>.delayed(Duration.zero);
    expect(slow.isSpeaking, isTrue);
    await b.onEnabledChanged(false);
    expect(slow.stops, 1);
    await n.whenIdle();
  });

  // Revisao F03: descartar a gravacao nao pode falar o resumo do fim.
  test('descarte: suppressNextFinish cala o resumo do fim', () async {
    await feed(ui());
    await feed(ui(state: RecordingState.manuallyPaused, distance: 800, timerMs: 240000));
    bridge.suppressNextFinish();
    await feed(ui(state: RecordingState.finished, distance: 800, timerMs: 240000));
    expect(voice.spoken, ['Corrida iniciada.', 'Gravação pausada.']);
  });

  test('suppressNextFinish vale so para a gravacao corrente', () async {
    await feed(ui());
    bridge.suppressNextFinish();
    await feed(ui(state: RecordingState.finished, distance: 800, timerMs: 240000));
    voice.spoken.clear();
    // Gravacao seguinte: o fim volta a ser falado.
    await feed(ui());
    await feed(ui(state: RecordingState.finished, distance: 1000, timerMs: 300000));
    expect(voice.spoken.last, startsWith('Corrida encerrada.'));
  });

  test('pausa tecnica (abrir Salvar) nao e anunciada; o fim continua', () async {
    await feed(ui());
    bridge.silenceNextPause();
    await feed(ui(state: RecordingState.manuallyPaused, distance: 1000, timerMs: 300000));
    await feed(ui(state: RecordingState.finished, distance: 1000, timerMs: 300000));
    expect(voice.spoken, [
      'Corrida iniciada.',
      'Corrida encerrada. Distância um quilômetro. Tempo cinco minutos. '
          'Pace médio cinco minutos.',
    ]);
  });

  test('silenceNextPause e de uma vez so: a pausa seguinte e falada', () async {
    await feed(ui());
    bridge.silenceNextPause();
    // Nenhuma pausa aconteceu nesse estado: o pedido expira.
    await feed(ui(distance: 100, timerMs: 30000));
    await feed(ui(state: RecordingState.manuallyPaused, distance: 100, timerMs: 30000));
    expect(voice.spoken.last, 'Gravação pausada.');
  });

  // Limitacao documentada: todos os splits dividem a chave de fila
  // narrator.split. Se o Narrador ja esta falando quando dois splits fecham no
  // mesmo update (buraco no GPS), so o mais recente fica na fila.
  test('dois splits no mesmo update com o narrador ocupado: fica o mais recente', () async {
    final slow = FakeVoiceAnnouncer(autoComplete: false);
    final n = Narrator(slow, now: () => 0);
    settings = settings.copyWith(essentialOnly: true);
    final b = RecordingNarration(narrator: n, settings: () => settings, useMetric: () => true);
    b.onState(ui());
    await Future<void>.delayed(Duration.zero);
    expect(slow.spoken, ['Corrida iniciada.']);
    b.onState(ui(distance: 2050, timerMs: 600000, km: [300000, 290000]));
    slow.finishCurrent();
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    slow.finishCurrent();
    await n.whenIdle();
    expect(slow.spoken, ['Corrida iniciada.', 'Dois quilômetros. Pace quatro e cinquenta.']);
  });
}
