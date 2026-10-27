// Resumo de uma volta gravada: distancia, tempo e pace.
library;

import 'dart:math' as math;

import '../persistence/database.dart';

class LapSummary {
  final int number;
  final double distanceMeters;
  final int durationMs;

  const LapSummary({
    required this.number,
    required this.distanceMeters,
    required this.durationMs,
  });

  /// Pace em segundos por metro; null quando nao ha distancia.
  double? get paceSecondsPerMeter =>
      distanceMeters > 0 ? (durationMs / 1000.0) / distanceMeters : null;

  factory LapSummary.fromLap(Lap lap) => LapSummary(
    number: lap.number,
    distanceMeters: math.max(
      0.0,
      lap.endDistanceMeters - lap.startDistanceMeters,
    ),
    durationMs: math.max(0, lap.endTimerMs - lap.startTimerMs),
  );
}
