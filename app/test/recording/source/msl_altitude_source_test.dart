// Altitude MSL na fonte de GPS: usa o valor convertido quando o conversor
// devolve, e a altitude crua quando nao.
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/platform/msl_altitude.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/location_sample.dart';
import 'package:strava_estudo_app/recording/source/geolocator_location_source.dart';

import '../fakes.dart';

LocationSample sample({double? alt}) => LocationSample(
  position: GeoPoint(latitude: -23.5, longitude: -46.6, altitudeMeters: alt),
  wallClockMs: 123,
  monotonicMs: 45,
  horizontalAccuracyMeters: 4,
  verticalAccuracyMeters: 3,
  speedMetersPerSecond: 2.5,
  bearingDegrees: 90,
);

void main() {
  test('usa a altitude MSL quando o conversor devolve valor', () async {
    final conv = FakeMslConverter(5); // geoide 5 m acima do elipsoide
    final out = await withMslAltitude(sample(alt: 800), conv);
    expect(out.position.altitudeMeters, 795);
    // O resto da amostra fica igual.
    expect(out.position.latitude, -23.5);
    expect(out.monotonicMs, 45);
    expect(out.wallClockMs, 123);
    expect(out.horizontalAccuracyMeters, 4);
    expect(out.verticalAccuracyMeters, 3);
    expect(out.speedMetersPerSecond, 2.5);
    expect(out.bearingDegrees, 90);
  });

  test('sem conversao mantem a altitude crua', () async {
    final out = await withMslAltitude(sample(alt: 800), FakeMslConverter(null));
    expect(out.position.altitudeMeters, 800);
    final out2 = await withMslAltitude(
      sample(alt: 800),
      const NoMslAltitudeConverter(),
    );
    expect(out2.position.altitudeMeters, 800);
  });

  test('sem altitude não chama o conversor', () async {
    final conv = FakeMslConverter(5);
    final out = await withMslAltitude(sample(), conv);
    expect(out.position.altitudeMeters, isNull);
    expect(conv.calls, 0);
  });
}
