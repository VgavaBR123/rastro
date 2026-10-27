// Perfil de elevacao de uma atividade gravada (distancia x altitude).
//
// Clean room a partir de relatorios/04-metricas.md: o perfil usa so pontos
// ACEITOS pelo pipeline; pontos filtrados nao entram. Pontos sem altitude sao
// ignorados. Para o grafico, a serie e reduzida a no maximo [maxPoints] pontos
// por baldes de min/max, que preservam picos e vales.
library;

import 'dart:math' as math;

import '../persistence/database.dart';
import '../recording/domain/elevation.dart';
import '../recording/domain/waypoint.dart' as dom;

/// Limite padrao de pontos do grafico.
const int kElevationProfileMaxPoints = 300;

/// Um ponto da serie: distancia acumulada (m) e altitude (m).
class ElevationSample {
  final double distanceMeters;
  final double altitudeMeters;

  /// Precisao vertical (m), usada so no calculo do ganho.
  final double? verticalAccuracyMeters;

  const ElevationSample(
    this.distanceMeters,
    this.altitudeMeters, {
    this.verticalAccuracyMeters,
  });

  @override
  String toString() => 'ElevationSample($distanceMeters, $altitudeMeters)';
}

/// Serie pronta para desenhar, com os resumos da serie completa.
class ElevationProfile {
  /// Serie reduzida (no maximo o limite pedido), em ordem de distancia.
  final List<ElevationSample> points;
  final double minAltitudeMeters;
  final double maxAltitudeMeters;
  final double startDistanceMeters;
  final double endDistanceMeters;

  /// Ganho total calculado sobre a serie completa (nao a reduzida).
  final double gainMeters;

  const ElevationProfile({
    required this.points,
    required this.minAltitudeMeters,
    required this.maxAltitudeMeters,
    required this.startDistanceMeters,
    required this.endDistanceMeters,
    required this.gainMeters,
  });
}

/// Extrai a serie dos waypoints persistidos: so aceitos, so com altitude.
List<ElevationSample> elevationSamplesFromWaypoints(List<Waypoint> rows) {
  final accept = dom.WaypointClassification.accept.index;
  return [
    for (final w in rows)
      if (w.classification == accept &&
          w.altitudeMeters != null &&
          w.altitudeMeters!.isFinite &&
          w.cumulativeDistanceMeters.isFinite)
        ElevationSample(
          w.cumulativeDistanceMeters,
          w.altitudeMeters!,
          verticalAccuracyMeters: w.verticalAccuracyMeters,
        ),
  ];
}

/// Monta o perfil a partir dos waypoints. Menos de 2 pontos com altitude ->
/// null (nao ha perfil para mostrar).
ElevationProfile? buildElevationProfile(
  List<Waypoint> rows, {
  int maxPoints = kElevationProfileMaxPoints,
}) => buildElevationProfileFromSamples(
  elevationSamplesFromWaypoints(rows),
  maxPoints: maxPoints,
);

/// Mesmo que [buildElevationProfile], partindo de uma serie ja extraida.
ElevationProfile? buildElevationProfileFromSamples(
  List<ElevationSample> samples, {
  int maxPoints = kElevationProfileMaxPoints,
}) {
  if (samples.length < 2) return null;
  var minAlt = double.infinity;
  var maxAlt = double.negativeInfinity;
  final acc = ElevationAccumulator();
  for (final s in samples) {
    minAlt = math.min(minAlt, s.altitudeMeters);
    maxAlt = math.max(maxAlt, s.altitudeMeters);
    acc.process(
      s.altitudeMeters,
      verticalAccuracyMeters: s.verticalAccuracyMeters,
    );
  }
  return ElevationProfile(
    points: reduceElevationSamples(samples, maxPoints),
    minAltitudeMeters: minAlt,
    maxAltitudeMeters: maxAlt,
    startDistanceMeters: samples.first.distanceMeters,
    endDistanceMeters: samples.last.distanceMeters,
    gainMeters: acc.stats.ascentMeters,
  );
}

/// Reduz a serie para no maximo [maxPoints] pontos.
///
/// Mantem o primeiro e o ultimo ponto. O miolo e dividido em baldes contiguos
/// de tamanho parecido; de cada balde saem o ponto de menor e o de maior
/// altitude, na ordem em que aparecem (a ordem por distancia se mantem). Assim
/// o minimo e o maximo globais sempre sobrevivem, e picos estreitos nao somem
/// como sumiriam numa amostragem simples de 1 a cada N.
List<ElevationSample> reduceElevationSamples(
  List<ElevationSample> samples,
  int maxPoints,
) {
  if (samples.length <= maxPoints) return List.of(samples);
  if (maxPoints < 2) {
    return maxPoints <= 0 ? const [] : [samples.first];
  }
  final interior = samples.length - 2;
  final buckets = (maxPoints - 2) ~/ 2;
  final out = <ElevationSample>[samples.first];
  if (buckets > 0) {
    for (var b = 0; b < buckets; b++) {
      // Indices [start, end) dentro do miolo (deslocados de 1).
      final start = 1 + (b * interior) ~/ buckets;
      final end = 1 + ((b + 1) * interior) ~/ buckets;
      if (start >= end) continue;
      var iMin = start;
      var iMax = start;
      for (var i = start + 1; i < end; i++) {
        if (samples[i].altitudeMeters < samples[iMin].altitudeMeters) iMin = i;
        if (samples[i].altitudeMeters > samples[iMax].altitudeMeters) iMax = i;
      }
      if (iMin == iMax) {
        out.add(samples[iMin]);
      } else if (iMin < iMax) {
        out
          ..add(samples[iMin])
          ..add(samples[iMax]);
      } else {
        out
          ..add(samples[iMax])
          ..add(samples[iMin]);
      }
    }
  }
  out.add(samples.last);
  return out;
}
