// Modo Gentil (F04) na ponte gravacao -> Narrador: le a configuracao a cada
// estado, entao ligar no meio da gravacao ja vale para o proximo split.
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/narrator/domain/narrator_settings.dart';
import 'package:strava_estudo_app/narrator/narrator.dart';
import 'package:strava_estudo_app/narrator/recording_narration.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/presentation/recording_ui_state.dart';

import 'fake_voice_announcer.dart';

RecordingUiState ui({
  RecordingState state = RecordingState.recording,
  double distance = 0,
  int timerMs = 0,
  List<int> km = const [],
}) => RecordingUiState(
  state: state,
  distanceMeters: distance,
  timerMs: timerMs,
  activityType: ActivityType.run,
  splitDurationsKmMs: km,
);

void main() {
  test('Modo Gentil ligado no meio: proximos splits sem pace', () async {
    final voice = FakeVoiceAnnouncer();
    final narrator = Narrator(voice, now: () => 0);
    var gentle = false;
    final bridge = RecordingNarration(
      narrator: narrator,
      settings: () => const NarratorSettings(enabled: true),
      useMetric: () => true,
      gentle: () => gentle,
    );
    Future<void> feed(RecordingUiState s) async {
      bridge.onState(s);
      await narrator.whenIdle();
    }

    await feed(ui());
    await feed(ui(distance: 1000, timerMs: 332000, km: [332000]));
    gentle = true;
    await feed(ui(distance: 2000, timerMs: 652000, km: [332000, 320000]));
    await feed(ui(
      state: RecordingState.finished,
      distance: 2100,
      timerMs: 680000,
      km: [332000, 320000],
    ));
    expect(voice.spoken[1], contains('Pace'));
    expect(voice.spoken[2], 'Dois quilômetros. Tempo dez minutos e cinquenta e dois segundos.');
    expect(voice.spoken[3], isNot(contains('Pace')));
  });
}
