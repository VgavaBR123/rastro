/// Splits por distancia com fechamento interpolado na marca exata.
///
/// Clean room a partir de relatorios/04-metricas.md ("Splits por quilometro e
/// milha"). Reimplementacao propria: cada split fecha na fronteira exata
/// (1 km, 2 km, ...) com o tempo de cruzamento interpolado linearmente entre o
/// ponto anterior e o atual, usando o tempo de cronometro. Um unico update pode
/// fechar varios splits (saltos de distancia apos recuperar sinal).
library;

import 'geo.dart';

const double kMetersPerKilometer = 1000.0;
const double kMetersPerMile = 1609.344;

/// Piso de tempo para expor pace "ao vivo" do split corrente, evitando pace
/// absurdo quando o split mal comecou (etapa 04: MIN_SPLIT_PACE_TIME_MS).
const int kMinSplitPaceTimeMs = 1000;

class ActiveSplit {
  final int number; // 1-based
  final double startDistanceMeters;
  final int startTimerMs;
  double endDistanceMeters;
  int endTimerMs;
  bool complete;

  ActiveSplit({
    required this.number,
    required this.startDistanceMeters,
    required this.startTimerMs,
    required this.endDistanceMeters,
    required this.endTimerMs,
    this.complete = false,
  });

  double get distanceMeters => endDistanceMeters - startDistanceMeters;
  int get durationMs => endTimerMs - startTimerMs;

  double get avgSpeedMetersPerSecond {
    final dt = durationMs / 1000.0;
    return dt > 0 ? distanceMeters / dt : 0.0;
  }
}

/// Lista de splits de uma unica unidade (km ou milha).
class SplitList {
  final double splitSizeMeters;
  final List<ActiveSplit> _completed = [];

  double _lastDistance = 0.0;
  int _lastTimerMs = 0;
  double _splitStartDistance = 0.0;
  int _splitStartTimerMs = 0;

  SplitList(this.splitSizeMeters);

  List<ActiveSplit> get completed => List.unmodifiable(_completed);
  int get completedCount => _completed.length;

  /// Distancia da proxima fronteira (1-based sobre os ja completos).
  double get _nextBoundary => (_completed.length + 1) * splitSizeMeters;

  void update(double distanceMeters, int timerMs) {
    // Fecha quantas fronteiras couberem entre o ultimo ponto e este.
    while (distanceMeters >= _nextBoundary) {
      final boundary = _nextBoundary;
      final crossingTimerMs = _interpolateTimer(boundary, distanceMeters, timerMs);
      _completed.add(ActiveSplit(
        number: _completed.length + 1,
        startDistanceMeters: _splitStartDistance,
        startTimerMs: _splitStartTimerMs,
        endDistanceMeters: boundary,
        endTimerMs: crossingTimerMs,
        complete: true,
      ));
      _splitStartDistance = boundary;
      _splitStartTimerMs = crossingTimerMs;
    }
    _lastDistance = distanceMeters;
    _lastTimerMs = timerMs;
  }

  /// Interpola o instante (cronometro) em que a distancia cruzou [boundary],
  /// entre o ultimo ponto e o atual.
  int _interpolateTimer(double boundary, double distanceMeters, int timerMs) {
    final dDist = distanceMeters - _lastDistance;
    if (dDist <= 0) return timerMs;
    final frac = (boundary - _lastDistance) / dDist;
    return (_lastTimerMs + frac * (timerMs - _lastTimerMs)).round();
  }

  /// Split corrente (parcial), se houver progresso desde a ultima fronteira.
  ActiveSplit? get currentSplit {
    if (_lastDistance <= _splitStartDistance) return null;
    return ActiveSplit(
      number: _completed.length + 1,
      startDistanceMeters: _splitStartDistance,
      startTimerMs: _splitStartTimerMs,
      endDistanceMeters: _lastDistance,
      endTimerMs: _lastTimerMs,
      complete: false,
    );
  }

  /// Pace do split corrente (s/m), ou null se ainda muito curto para exibir.
  double? get currentLivePaceSecondsPerMeter {
    final c = currentSplit;
    if (c == null || c.durationMs < kMinSplitPaceTimeMs || c.distanceMeters <= 0) {
      return null;
    }
    return (c.durationMs / 1000.0) / c.distanceMeters;
  }
}

/// Mantem splits de km e milha em paralelo (etapa 04). A UI escolhe a unidade.
class DualSplits {
  final SplitList kilometers = SplitList(kMetersPerKilometer);
  final SplitList miles = SplitList(kMetersPerMile);

  /// Alimentado a cada ponto ACEITO (ver point_pipeline / etapa 04).
  void onAcceptedPoint(double cumulativeDistanceMeters, int timerMs, GeoPoint _) {
    kilometers.update(cumulativeDistanceMeters, timerMs);
    miles.update(cumulativeDistanceMeters, timerMs);
  }
}
