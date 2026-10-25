/// Reconstroi os splits de uma atividade ja gravada, a partir dos pontos
/// persistidos.
///
/// Clean room a partir de relatorios/04-metricas.md ("Splits por quilometro e
/// milha"): durante a gravacao os splits sao fechados ao vivo por `SplitList`;
/// para uma atividade finalizada o mesmo resultado e obtido reproduzindo a
/// sequencia de distancia acumulada x tempo de cronometro dos pontos aceitos.
/// Aqui nao ha logica nova de split: so o replay sobre a `SplitList` existente.
///
/// Dart puro e sem dependencia do banco: a UI converte as linhas do Drift para
/// [SplitSourcePoint] antes de chamar.
library;

import 'splits.dart';

/// Par (distancia acumulada, tempo de cronometro) de um ponto ACEITO.
/// Tipo proprio para nao acoplar o dominio ao Drift.
class SplitSourcePoint {
  final double cumulativeDistanceMeters;
  final int timerTimeMs;

  const SplitSourcePoint({
    required this.cumulativeDistanceMeters,
    required this.timerTimeMs,
  });
}

/// Splits de uma atividade finalizada, na unidade pedida.
///
/// [points] deve vir em ordem de gravacao (seq crescente) e conter apenas
/// pontos aceitos. Pontos com distancia acumulada menor que a do anterior sao
/// ignorados, porque a distancia acumulada e monotonica por definicao e um
/// retrocesso so pode ser lixo.
///
/// Quando [includePartial] e true (padrao), o trecho final que nao chegou a
/// fechar a marca entra no fim da lista com `complete == false`; a UI o
/// identifica como parcial.
List<ActiveSplit> splitsFromPoints(
  Iterable<SplitSourcePoint> points, {
  required bool metric,
  bool includePartial = true,
}) {
  final list = SplitList(metric ? kMetersPerKilometer : kMetersPerMile);

  double lastDistance = 0.0;
  for (final p in points) {
    final d = p.cumulativeDistanceMeters;
    if (!d.isFinite || d < lastDistance) continue;
    list.update(d, p.timerTimeMs);
    lastDistance = d;
  }

  final result = <ActiveSplit>[...list.completed];
  if (includePartial) {
    final partial = list.currentSplit;
    if (partial != null) result.add(partial);
  }
  return result;
}

/// Pace medio do trecho em segundos por metro, ou null quando nao da para
/// calcular (trecho sem duracao ou sem distancia).
double? splitPaceSecondsPerMeter(ActiveSplit split) {
  if (split.durationMs <= 0 || split.distanceMeters <= 0) return null;
  return (split.durationMs / 1000.0) / split.distanceMeters;
}
