// Testa a funcao pura mapPosition (Position do geolocator -> LocationSample).
// Nao exercita o plugin em si, so o mapeamento de campos.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import 'package:strava_estudo_app/recording/source/geolocator_location_source.dart';

void main() {
  group('mapPosition', () {
    test('mapeia todos os campos quando o provedor informou cada um', () {
      final timestamp =
          DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true);

      final position = Position(
        longitude: -46.633308,
        latitude: -23.55052,
        timestamp: timestamp,
        accuracy: 5.0,
        altitude: 760.0,
        altitudeAccuracy: 3.0,
        heading: 90.0,
        headingAccuracy: 1.0,
        speed: 2.5,
        speedAccuracy: 0.5,
        // Flags: o provedor mediu cada grandeza (distinto de "informou zero").
        hasAccuracy: true,
        hasAltitude: true,
        hasAltitudeAccuracy: true,
        hasHeading: true,
        hasSpeed: true,
        hasSpeedAccuracy: true,
      );

      final sample = mapPosition(position, 1234);

      expect(sample.position.latitude, -23.55052);
      expect(sample.position.longitude, -46.633308);
      expect(sample.position.altitudeMeters, 760.0);
      expect(sample.horizontalAccuracyMeters, 5.0);
      expect(sample.verticalAccuracyMeters, 3.0);
      expect(sample.speedMetersPerSecond, 2.5);
      expect(sample.bearingDegrees, 90.0);
      expect(sample.wallClockMs, 1700000000000);
      expect(sample.monotonicMs, 1234);
    });

    test('campos nao informados viram null (flags has* false)', () {
      final position = Position(
        longitude: 10.0,
        latitude: 20.0,
        timestamp: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        accuracy: 0.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        // Todas as flags has* default false: nada foi medido.
      );

      final sample = mapPosition(position, 0);

      expect(sample.position.latitude, 20.0);
      expect(sample.position.longitude, 10.0);
      expect(sample.position.altitudeMeters, isNull);
      expect(sample.horizontalAccuracyMeters, isNull);
      expect(sample.verticalAccuracyMeters, isNull);
      expect(sample.speedMetersPerSecond, isNull);
      expect(sample.bearingDegrees, isNull);
      expect(sample.monotonicMs, 0);
    });

    test('precisao horizontal <= 0 e tratada como desconhecida', () {
      final position = Position(
        longitude: 0.0,
        latitude: 0.0,
        timestamp: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        accuracy: 0.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        // hasAccuracy true, mas valor 0.0 (sentinela): deve virar null.
        hasAccuracy: true,
      );

      final sample = mapPosition(position, 10);

      expect(sample.horizontalAccuracyMeters, isNull);
    });
  });
}
