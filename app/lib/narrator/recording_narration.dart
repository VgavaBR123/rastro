// Ponte entre a gravacao e o Narrador (F03): recebe cada estado da gravacao,
// detecta os eventos e enfileira as falas conforme as preferencias.
library;

// ignore_for_file: prefer_initializing_formals

import '../recording/domain/recording_models.dart';
import '../recording/presentation/recording_ui_state.dart';
import 'domain/narration_composer.dart';
import 'domain/narration_event.dart';
import 'domain/narration_event_detector.dart';
import 'domain/narrator_settings.dart';
import 'narrator.dart';

class RecordingNarration {
  final Narrator _narrator;
  final NarratorSettings Function() _settings;
  final bool Function() _useMetric;

  /// Modo Gentil (F04): lido a cada estado, como as preferencias.
  final bool Function() _gentle;

  /// Plano 5 km (F06): sessao guiada ativa. As voltas sao fechadas pelo plano
  /// a cada troca de bloco e o Narrador nao as anuncia (a voz do plano ja fala
  /// a troca); as outras falas (split, tempo) saem como no Modo Gentil, sem
  /// ritmo, porque o plano e por tempo.
  final bool Function() _guidedActive;
  final NarrationComposer _composer;
  final NarrationEventDetector _detector = NarrationEventDetector();

  /// Descarte pedido: o proximo fim desta gravacao fica mudo.
  bool _suppressFinish = false;

  /// Pausa tecnica pedida: o proximo estado nao anuncia pausa manual.
  bool _silencePause = false;

  RecordingNarration({
    required Narrator narrator,
    required NarratorSettings Function() settings,
    required bool Function() useMetric,
    bool Function()? gentle,
    bool Function()? guidedActive,
    NarrationComposer composer = const NarrationComposer(),
  }) : _narrator = narrator,
       _settings = settings,
       _useMetric = useMetric,
       _gentle = gentle ?? _never,
       _guidedActive = guidedActive ?? _never,
       _composer = composer;

  /// Novo estado da gravacao. Com o Narrador desligado o detector continua
  /// acompanhando (ligar no meio nao despeja splits antigos), mas nada e dito.
  void onState(RecordingUiState s) {
    final prefs = _settings();
    final metric = _useMetric();
    final events = _detector.onSnapshot(
      NarrationSnapshot(
        state: s.state,
        type: s.activityType ?? ActivityType.run,
        distanceMeters: s.distanceMeters,
        timerMs: s.timerMs,
        splitDurationsMs: metric ? s.splitDurationsKmMs : s.splitDurationsMileMs,
        laps: [
          for (final l in s.closedLaps)
            LapMark(
              number: l.number,
              durationMs: l.durationMs,
              distanceMeters: l.distanceMeters,
            ),
        ],
        metric: metric,
      ),
      timeEveryMinutes: prefs.timeEveryMinutes,
    );
    // Pedidos de silencio sao de uma vez so: a pausa vale para este estado;
    // o fim vale ate a gravacao corrente acabar (finished ou descartada).
    final silencePause = _silencePause;
    _silencePause = false;
    final suppressFinish = _suppressFinish;
    if (!s.isActive) _suppressFinish = false;
    if (!prefs.enabled) return;
    final guided = _guidedActive();
    final gentle = _gentle() || guided;
    for (final e in events) {
      if (e is LapClosed && guided) continue;
      if (e is ManuallyPaused && silencePause) continue;
      if (e is RecordingFinished && suppressFinish) continue;
      final a = _composer.compose(e, prefs, gentle: gentle);
      if (a != null) _narrator.enqueue(a);
    }
  }

  /// A gravacao vai ser descartada: o fim que vem a seguir nao e anunciado
  /// (falar o resumo de uma atividade apagada so confunde). Chamar antes de
  /// encerrar o controller.
  void suppressNextFinish() => _suppressFinish = true;

  /// A pausa que vem a seguir e tecnica (o app pausa para abrir Salvar), nao
  /// da pessoa: nao diz "Gravacao pausada". Vale so para o proximo estado.
  void silenceNextPause() => _silencePause = true;

  /// Desligou o Narrador: cala na hora.
  Future<void> onEnabledChanged(bool enabled) async {
    if (!enabled) await _narrator.stop();
  }
}

bool _never() => false;
