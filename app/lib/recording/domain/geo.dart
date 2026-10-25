/// Geometria basica da gravacao: ponto geografico e distancia de grande circulo.
///
/// Clean room a partir de relatorios/03-gravacao-gps.md e 04-metricas.md.
/// Nada aqui depende do Flutter; e Dart puro e testavel isoladamente.
library;

import 'dart:math' as math;

/// Raio medio da Terra em metros (esfera WGS84 aproximada).
const double kEarthRadiusMeters = 6371008.8;

/// Um ponto geografico simples (graus decimais) com altitude opcional.
class GeoPoint {
  final double latitude;
  final double longitude;

  /// Altitude em metros acima do nivel medio do mar (geoide), quando conhecida.
  /// Ver etapa 04: a altitude do GPS (elipsoidal) e corrigida para o geoide antes
  /// de chegar aqui; este modelo ja assume MSL.
  final double? altitudeMeters;

  const GeoPoint({
    required this.latitude,
    required this.longitude,
    this.altitudeMeters,
  });

  @override
  String toString() =>
      'GeoPoint($latitude, $longitude${altitudeMeters != null ? ', ${altitudeMeters}m' : ''})';
}

/// Distancia de grande circulo (haversine) entre dois pontos, em metros.
///
/// Usada para o incremento de distancia entre amostras aceitas (etapa 04:
/// "fonte unica de distancia", acumulada a partir de pontos nao filtrados).
double haversineMeters(GeoPoint a, GeoPoint b) {
  final lat1 = _toRad(a.latitude);
  final lat2 = _toRad(b.latitude);
  final dLat = _toRad(b.latitude - a.latitude);
  final dLon = _toRad(b.longitude - a.longitude);

  final sinLat = math.sin(dLat / 2);
  final sinLon = math.sin(dLon / 2);
  final h = sinLat * sinLat + math.cos(lat1) * math.cos(lat2) * sinLon * sinLon;
  final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  return kEarthRadiusMeters * c;
}

double _toRad(double degrees) => degrees * math.pi / 180.0;
