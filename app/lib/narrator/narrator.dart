// Narrador (F03): API generica de voz do app. Qualquer parte (gravacao, plano
// 5 km do F06, sensores do F11) enfileira frases com prioridade; o Narrador
// fala uma de cada vez, sem sobrepor, na ordem da fila.
library;

// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'domain/announcement.dart';
import 'domain/announcement_queue.dart';
import 'voice/voice_announcer.dart';

/// Gancho para quem muda o tom das falas (o Modo Gentil, quando existir):
/// recebe a frase e devolve outra, ou null para calar.
typedef AnnouncementFilter = Announcement? Function(Announcement a);

class Narrator {
  final VoiceAnnouncer _voice;
  final int Function() _now;
  final AnnouncementFilter? _filter;
  final AnnouncementQueue _queue = AnnouncementQueue();

  Announcement? _current;
  Completer<void>? _idle;
  bool _disposed = false;

  Narrator(
    VoiceAnnouncer voice, {
    int Function()? now,
    AnnouncementFilter? filter,
  }) : _voice = voice,
       _now = now ?? (() => DateTime.now().millisecondsSinceEpoch),
       _filter = filter;

  bool get isSpeaking => _current != null;

  /// Enfileira uma frase. Uma [AnnouncementPriority.critical] interrompe a
  /// fala menor que estiver tocando, e a interrompida e DESCARTADA (nao volta
  /// para a fila): repetir um split pela metade, segundos depois e com numeros
  /// ja velhos, atrapalha mais do que ajuda. As pendentes continuam na fila.
  void enqueue(Announcement a) {
    if (_disposed) return;
    final filtered = _filter == null ? a : _filter(a);
    if (filtered == null) return;
    _queue.add(filtered, _now());
    final current = _current;
    if (current != null &&
        filtered.priority == AnnouncementPriority.critical &&
        current.priority != AnnouncementPriority.critical) {
      unawaited(_safe(_voice.stop()));
    }
    _drain();
  }

  /// Enfileira [a] trocando a fala de mesma [Announcement.key]: a pendente sai
  /// da fila e, se a que esta tocando tem a mesma chave, e cortada. As outras
  /// falas pendentes ficam (ex.: "Ouvir exemplo" durante uma gravacao).
  void replace(Announcement a) {
    if (_disposed) return;
    final key = a.key;
    final current = _current;
    if (key != null && current != null && current.key == key) {
      unawaited(_safe(_voice.stop()));
    }
    enqueue(a);
  }

  /// Atalho de [enqueue] para quem so tem o texto.
  void say(
    String text, {
    AnnouncementPriority priority = AnnouncementPriority.normal,
    String? key,
    int? maxAgeMs,
  }) => enqueue(Announcement(text, priority: priority, key: key, maxAgeMs: maxAgeMs));

  /// Cala a fala corrente e descarta as pendentes.
  Future<void> stop() async {
    _queue.clear();
    if (_current != null) await _safe(_voice.stop());
  }

  /// Completa quando nao houver fala tocando nem pendente.
  Future<void> whenIdle() => _idle?.future ?? Future<void>.value();

  Future<void> dispose() async {
    _disposed = true;
    await stop();
  }

  void _drain() {
    if (_idle != null) return; // ja drenando
    final idle = _idle = Completer<void>();
    unawaited(() async {
      try {
        while (true) {
          final next = _queue.takeNext(_now());
          if (next == null || _disposed) break;
          _current = next;
          await _safe(_voice.speak(next.text));
          _current = null;
        }
      } finally {
        _current = null;
        _idle = null;
        idle.complete();
      }
    }());
  }

  static Future<void> _safe(Future<void> op) async {
    try {
      await op;
    } catch (_) {
      // TTS indisponivel ou com erro: a frase fica sem som, a fila segue.
    }
  }
}
