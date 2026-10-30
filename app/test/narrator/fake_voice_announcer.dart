// Voz falsa para os testes do Narrador: registra o que foi falado e deixa o
// teste decidir quando cada fala termina.
import 'dart:async';

import 'package:strava_estudo_app/narrator/voice/voice_announcer.dart';

class FakeVoiceAnnouncer implements VoiceAnnouncer {
  /// true: cada fala termina na hora. false: so com [finishCurrent] ou [stop].
  final bool autoComplete;

  /// Lanca ao falar (TTS quebrado).
  bool failSpeak = false;

  FakeVoiceAnnouncer({this.autoComplete = true});

  final List<String> spoken = [];
  int stops = 0;
  int maxConcurrent = 0;
  int _concurrent = 0;
  Completer<void>? _current;

  bool get isSpeaking => _current != null;

  @override
  Future<void> speak(String text) async {
    if (failSpeak) throw StateError('tts quebrado');
    spoken.add(text);
    _concurrent++;
    if (_concurrent > maxConcurrent) maxConcurrent = _concurrent;
    try {
      if (autoComplete) return;
      final c = _current = Completer<void>();
      await c.future;
    } finally {
      _concurrent--;
    }
  }

  /// Termina a fala corrente.
  void finishCurrent() {
    final c = _current;
    _current = null;
    if (c != null && !c.isCompleted) c.complete();
  }

  @override
  Future<void> stop() async {
    stops++;
    finishCurrent();
  }
}
