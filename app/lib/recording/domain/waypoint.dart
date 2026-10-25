/// Ponto consolidado da gravacao (equivalente ao Waypoint do estudo) e sua
/// classificacao. Clean room a partir de relatorios/03 e 04.
library;

import 'geo.dart';

/// Por que um ponto foi aceito ou descartado (etapa 03, WaypointClassification).
enum WaypointClassification {
  accept,
  ignoreManualPause,
  ignoreDuplicateTimestamp,
  ignoreSampleUpdateFilter, // deslocamento abaixo do minimo
  ignoreAccelerationFilter, // salto implausivel de velocidade
  ignoreBadAccuracy, // precisao fora do portao de sanidade / corte de qualidade
  // Teleporte: velocidade implausivel ja contra o ponto anterior. Existe porque
  // o filtro de aceleracao precisa de DOIS pontos anteriores e nao cobre o
  // segundo ponto da gravacao. Valor no fim do enum de proposito: a
  // classificacao e persistida por indice (ver persistence/database.dart).
  ignoreImplausibleSpeed,
}

/// Ponto rico apos o pipeline. `isFiltered` marca pontos que nao entram em
/// distancia/splits/polyline (etapa 03/04), mas ainda podem contar para
/// estatisticas auxiliares.
class Waypoint {
  final GeoPoint position;

  /// Distancia acumulada em metros ate este ponto (fonte unica de distancia).
  final double cumulativeDistanceMeters;

  final double? horizontalAccuracyMeters;
  final double? verticalAccuracyMeters;
  final double? speedMetersPerSecond;

  /// Tempo total desde o inicio (ms).
  final int elapsedTimeMs;

  /// Tempo de cronometro (ms): exclui o tempo pausado. Pace e splits usam este.
  final int timerTimeMs;

  final WaypointClassification classification;

  const Waypoint({
    required this.position,
    required this.cumulativeDistanceMeters,
    required this.elapsedTimeMs,
    required this.timerTimeMs,
    required this.classification,
    this.horizontalAccuracyMeters,
    this.verticalAccuracyMeters,
    this.speedMetersPerSecond,
  });

  bool get isFiltered => classification != WaypointClassification.accept;
}
