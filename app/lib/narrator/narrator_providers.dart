/// Providers do Narrador por voz (F03).
library;

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../recording/presentation/recording_ui_state.dart';
import 'narrator.dart';
import 'recording_narration.dart';
import 'voice/flutter_tts_voice_announcer.dart';
import 'voice/voice_announcer.dart';

final bool _underFlutterTest =
    !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

/// Voz do sistema (TTS). Em `flutter test` e na web, sem voz.
final voiceAnnouncerProvider = Provider<VoiceAnnouncer>((ref) {
  return _underFlutterTest || kIsWeb
      ? const NoopVoiceAnnouncer()
      : FlutterTtsVoiceAnnouncer();
});

/// Gancho do Modo Gentil (ainda nao existe): quando existir, sobrescreve este
/// provider com um filtro que reescreve ou cala frases. Null = sem filtro.
final announcementFilterProvider = Provider<AnnouncementFilter?>((ref) => null);

/// API generica de voz: `ref.read(narratorProvider).say(...)` ou `enqueue`
/// com prioridade. Usada pela gravacao e, depois, pelo plano 5 km (F06) e
/// pelos sensores (F11).
final narratorProvider = Provider<Narrator>((ref) {
  final n = Narrator(
    ref.watch(voiceAnnouncerProvider),
    filter: ref.watch(announcementFilterProvider),
  );
  ref.onDispose(n.dispose);
  return n;
});

/// Liga a gravacao ao Narrador. Basta ler uma vez (a tela de gravacao le ao
/// abrir); daí em diante cada estado da gravacao passa pelo detector.
final recordingNarrationProvider = Provider<RecordingNarration>((ref) {
  final bridge = RecordingNarration(
    narrator: ref.watch(narratorProvider),
    settings: () => ref.read(settingsProvider).narrator,
    useMetric: () => ref.read(settingsProvider).useMetric,
  );
  ref.listen<RecordingUiState>(
    recordingControllerProvider,
    (_, next) => bridge.onState(next),
    fireImmediately: true,
  );
  ref.listen<bool>(
    settingsProvider.select((s) => s.narrator.enabled),
    (_, enabled) => bridge.onEnabledChanged(enabled),
  );
  return bridge;
});
