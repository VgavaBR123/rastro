// Detector de eventos para o Narrador (F03): compara a foto atual da gravacao
// com a anterior e devolve o que mudou (inicio, split, volta, marca de tempo,
// pausa, retomada, fim). Dart puro e deterministico: o tempo e o cronometro
// da propria foto.
library;

import '../../recording/domain/recording_models.dart';
import 'narration_event.dart';

/// Foto do estado da gravacao, so com o que o Narrador usa.
class NarrationSnapshot {
  final RecordingState state;
  final ActivityType type;
  final double distanceMeters;
  final int timerMs;

  /// Duracao dos splits ja fechados, na unidade [metric].
  final List<int> splitDurationsMs;
  final List<LapMark> laps;
  final bool metric;

  const NarrationSnapshot({
    required this.state,
    required this.type,
    required this.distanceMeters,
    required this.timerMs,
    required this.splitDurationsMs,
    required this.laps,
    required this.metric,
  });

  bool get isActive =>
      state == RecordingState.recording ||
      state == RecordingState.autoPaused ||
      state == RecordingState.manuallyPaused;

  NarrationTotals get totals => NarrationTotals(
    type: type,
    distanceMeters: distanceMeters,
    timerMs: timerMs,
    metric: metric,
  );
}

/// Abaixo disso de cronometro, sem distancia nem splits, e inicio novo.
const int _kFreshStartMaxTimerMs = 5000;

class NarrationEventDetector {
  NarrationSnapshot? _prev;
  int _intervalMin = 0;
  int? _nextMarkMs;

  void reset() {
    _prev = null;
    _intervalMin = 0;
    _nextMarkMs = null;
  }

  /// Processa uma foto. [timeEveryMinutes] e o gatilho de tempo atual (0 =
  /// desligado); mudar no meio conta a partir da proxima marca.
  List<NarrationEvent> onSnapshot(NarrationSnapshot s, {int timeEveryMinutes = 0}) {
    final prev = _prev;
    final events = <NarrationEvent>[];

    if (prev == null || !prev.isActive) {
      if (!s.isActive) {
        _prev = null;
        return events;
      }
      final resumed =
          s.distanceMeters > 0 ||
          s.timerMs >= _kFreshStartMaxTimerMs ||
          s.splitDurationsMs.isNotEmpty ||
          s.laps.isNotEmpty;
      events.add(RecordingStarted(resumed: resumed, totals: s.totals));
      _prev = s;
      _setInterval(timeEveryMinutes, s.timerMs);
      return events;
    }

    if (!s.isActive) {
      if (s.state == RecordingState.finished) {
        events.add(RecordingFinished(totals: s.totals));
      }
      reset();
      return events;
    }

    final stateEvent = _stateChange(prev, s);
    if (stateEvent != null) events.add(stateEvent);

    // Troca de unidade no meio: os splits sao de outra lista; so rebase.
    if (s.metric == prev.metric) {
      for (var i = prev.splitDurationsMs.length; i < s.splitDurationsMs.length; i++) {
        events.add(SplitClosed(
          number: i + 1,
          durationMs: s.splitDurationsMs[i],
          previousDurationsMs: List.unmodifiable(s.splitDurationsMs.sublist(0, i)),
          totals: s.totals,
        ));
      }
    }
    for (var i = prev.laps.length; i < s.laps.length; i++) {
      events.add(LapClosed(
        lap: s.laps[i],
        previous: List.unmodifiable(s.laps.sublist(0, i)),
        totals: s.totals,
      ));
    }

    if (timeEveryMinutes != _intervalMin) {
      _setInterval(timeEveryMinutes, s.timerMs);
    } else {
      final next = _nextMarkMs;
      if (next != null && s.state == RecordingState.recording && s.timerMs >= next) {
        final iv = _intervalMin * 60000;
        final mark = (s.timerMs ~/ iv) * iv;
        events.add(TimeMark(markMs: mark, totals: s.totals));
        _nextMarkMs = mark + iv;
      }
    }

    _prev = s;
    return events;
  }

  void _setInterval(int minutes, int timerMs) {
    _intervalMin = minutes;
    if (minutes <= 0) {
      _nextMarkMs = null;
      return;
    }
    final iv = minutes * 60000;
    _nextMarkMs = (timerMs ~/ iv + 1) * iv;
  }

  NarrationEvent? _stateChange(NarrationSnapshot prev, NarrationSnapshot s) {
    if (prev.state == s.state) return null;
    final t = s.totals;
    return switch (s.state) {
      RecordingState.autoPaused => AutoPaused(totals: t),
      RecordingState.manuallyPaused => ManuallyPaused(totals: t),
      RecordingState.recording => Resumed(
        fromAutoPause: prev.state == RecordingState.autoPaused,
        totals: t,
      ),
      _ => null,
    };
  }
}
