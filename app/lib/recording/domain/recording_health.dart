/// Saude da gravacao (F01): resumo para o cartao do detalhe da atividade.
/// Dart puro.
library;

import 'gap_monitor.dart';

class RecordingHealth {
  final int gapCount;
  final int gapTotalMs;

  /// Media da precisao horizontal dos pontos aceitos (m); null sem leitura.
  final double? avgHorizontalAccuracyMeters;

  /// Pontos que o filtro de ruido descartou (nao conta os de pausa).
  final int discardedPoints;

  /// Pontos percentuais de bateria gastos; null sem leitura nas duas pontas.
  final int? batteryUsedPercent;

  /// A gravacao teve batimento (F01): lacunas e descartes sao confiaveis.
  /// False em atividades antigas ou baixadas do servidor, que nao tem esses
  /// dados; a UI mostra "Sem dados" em vez de "Nenhuma"/0.
  final bool monitored;

  const RecordingHealth({
    required this.gapCount,
    required this.gapTotalMs,
    required this.avgHorizontalAccuracyMeters,
    required this.discardedPoints,
    required this.batteryUsedPercent,
    this.monitored = true,
  });

  bool get hasGaps => gapCount > 0;

  factory RecordingHealth.from({
    required List<RecordingGap> gaps,
    required List<double?> horizontalAccuracies,
    required int discardedPoints,
    int? startBatteryLevel,
    int? endBatteryLevel,
    bool monitored = true,
  }) {
    var sum = 0.0;
    var n = 0;
    for (final a in horizontalAccuracies) {
      if (a == null || !a.isFinite || a < 0) continue;
      sum += a;
      n++;
    }
    int? battery;
    if (startBatteryLevel != null && endBatteryLevel != null) {
      final used = startBatteryLevel - endBatteryLevel;
      battery = used < 0 ? 0 : used;
    }
    return RecordingHealth(
      gapCount: gaps.length,
      gapTotalMs: gaps.fold(0, (t, g) => t + g.durationMs),
      avgHorizontalAccuracyMeters: n == 0 ? null : sum / n,
      discardedPoints: discardedPoints,
      batteryUsedPercent: battery,
      monitored: monitored,
    );
  }
}

/// Duracao de lacuna legivel: "45 s", "1 min 05 s", "2 min", "1 h 02 min".
String formatGapDuration(int ms) {
  final total = (ms < 0 ? 0 : ms) ~/ 1000;
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  if (h > 0) return '$h h ${m.toString().padLeft(2, '0')} min';
  if (m > 0) {
    return s == 0 ? '$m min' : '$m min ${s.toString().padLeft(2, '0')} s';
  }
  return '$s s';
}
