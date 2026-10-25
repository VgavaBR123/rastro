// Fixture de rota sintetica para testes (shift-left). Sequencia de LocationSample
// com casos dificeis: trechos normais, um ponto de precisao ruim (deve ser
// filtrado) e uma subida (para elevacao). Pura, sem I/O.
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/location_sample.dart';

/// Rota reta no equador indo para leste, 1 amostra/s, ~11,1 m entre pontos.
/// Inclui 1 ponto de precisao ruim (acc=300) que o pipeline deve descartar.
/// Altitude sobe 2 m por ponto (ganho de elevacao previsivel).
List<LocationSample> sampleRoute() {
  final samples = <LocationSample>[];
  const stepDeg = 0.0001; // ~11,1 m no equador
  var alt = 100.0;
  for (var i = 0; i < 11; i++) {
    final isBad = i == 5; // ponto ruim no meio
    samples.add(LocationSample(
      position: GeoPoint(
        latitude: 0,
        longitude: stepDeg * i,
        altitudeMeters: alt,
      ),
      wallClockMs: 1000 * i,
      monotonicMs: 1000 * i,
      horizontalAccuracyMeters: isBad ? 300.0 : 5.0,
      verticalAccuracyMeters: 3.0,
      speedMetersPerSecond: 11.0,
    ));
    alt += 2.0;
  }
  return samples;
}

/// Quantos pontos da fixture tem precisao boa (devem ser aceitos).
int get sampleRouteGoodCount => 10; // 11 total - 1 ruim
