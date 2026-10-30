// Eventos da gravacao que o Narrador sabe contar (F03). Dart puro.
library;

import '../../recording/domain/recording_models.dart';

/// Totais da atividade no instante do evento.
class NarrationTotals {
  final ActivityType type;
  final double distanceMeters;
  final int timerMs;

  /// Unidade das Configuracoes (km ou milha).
  final bool metric;

  const NarrationTotals({
    required this.type,
    required this.distanceMeters,
    required this.timerMs,
    required this.metric,
  });
}

/// Volta fechada, como o Narrador precisa dela.
class LapMark {
  final int number;
  final int durationMs;
  final double distanceMeters;

  const LapMark({
    required this.number,
    required this.durationMs,
    required this.distanceMeters,
  });

  @override
  bool operator ==(Object other) =>
      other is LapMark &&
      other.number == number &&
      other.durationMs == durationMs &&
      other.distanceMeters == distanceMeters;

  @override
  int get hashCode => Object.hash(number, durationMs, distanceMeters);
}

sealed class NarrationEvent {
  final NarrationTotals totals;
  const NarrationEvent(this.totals);
}

/// Comecou a gravar. [resumed] = continuacao de uma atividade interrompida.
class RecordingStarted extends NarrationEvent {
  final bool resumed;
  const RecordingStarted({required this.resumed, required NarrationTotals totals})
    : super(totals);
}

/// Fechou o split [number] (1-based) na unidade de [totals].
class SplitClosed extends NarrationEvent {
  final int number;
  final int durationMs;

  /// Duracao dos splits anteriores, em ordem.
  final List<int> previousDurationsMs;

  const SplitClosed({
    required this.number,
    required this.durationMs,
    required this.previousDurationsMs,
    required NarrationTotals totals,
  }) : super(totals);
}

class LapClosed extends NarrationEvent {
  final LapMark lap;
  final List<LapMark> previous;
  const LapClosed({required this.lap, required this.previous, required NarrationTotals totals})
    : super(totals);
}

/// Passou de mais uma marca de "a cada N minutos" ([markMs] de cronometro).
class TimeMark extends NarrationEvent {
  final int markMs;
  const TimeMark({required this.markMs, required NarrationTotals totals}) : super(totals);
}

class AutoPaused extends NarrationEvent {
  const AutoPaused({required NarrationTotals totals}) : super(totals);
}

class ManuallyPaused extends NarrationEvent {
  const ManuallyPaused({required NarrationTotals totals}) : super(totals);
}

class Resumed extends NarrationEvent {
  final bool fromAutoPause;
  const Resumed({required this.fromAutoPause, required NarrationTotals totals})
    : super(totals);
}

class RecordingFinished extends NarrationEvent {
  const RecordingFinished({required NarrationTotals totals}) : super(totals);
}
