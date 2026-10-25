/// Amostra crua de localizacao entregue pela borda nativa (geolocator) ao pipeline.
///
/// Clean room a partir de relatorios/03-gravacao-gps.md (secao "Montagem do
/// RecordingLocation"): o modelo distingue "o provedor nao informou" de "informou
/// zero" usando valores anulaveis, e carrega dois relogios capturados na chegada.
library;

import 'geo.dart';

class LocationSample {
  final GeoPoint position;

  /// Precisao horizontal em metros; null quando o provedor nao informou.
  final double? horizontalAccuracyMeters;

  /// Precisao vertical em metros; null quando nao informada.
  final double? verticalAccuracyMeters;

  /// Velocidade instantanea em m/s; null quando nao informada.
  final double? speedMetersPerSecond;

  /// Rumo em graus; null quando nao informado.
  final double? bearingDegrees;

  /// Tempo de parede (epoch ms) do momento da fixacao.
  final int wallClockMs;

  /// Tempo monotonico do aparelho (ms), imune a ajustes de relogio.
  /// Usado para deltas de tempo no filtro de aceleracao.
  final int monotonicMs;

  const LocationSample({
    required this.position,
    required this.wallClockMs,
    required this.monotonicMs,
    this.horizontalAccuracyMeters,
    this.verticalAccuracyMeters,
    this.speedMetersPerSecond,
    this.bearingDegrees,
  });

  bool get hasHorizontalAccuracy => horizontalAccuracyMeters != null;
}
