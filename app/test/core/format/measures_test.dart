// Testes dos formatadores de medidas. Valores conhecidos e deterministicos.
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/core/format/measures.dart';

void main() {
  group('formatDistance', () {
    test('metrico abaixo de 1 km em metros inteiros', () {
      expect(formatDistance(500), '500 m');
      expect(formatDistance(0), '0 m');
      expect(formatDistance(999.4), '999 m');
    });

    test('metrico igual ou acima de 1 km em km com 2 casas', () {
      expect(formatDistance(1000), '1.00 km');
      expect(formatDistance(1234.5), '1.23 km');
      expect(formatDistance(2500), '2.50 km');
    });

    test('imperial em milhas com 2 casas', () {
      expect(formatDistance(1609.344, metric: false), '1.00 mi');
      expect(formatDistance(804.672, metric: false), '0.50 mi');
    });

    test('negativo vira zero', () {
      expect(formatDistance(-100), '0 m');
    });

    test('nao finito retorna placeholder', () {
      expect(formatDistance(double.nan), '-- m');
      expect(formatDistance(double.infinity, metric: false), '-- mi');
    });
  });

  group('formatDuration', () {
    test('zero e negativos', () {
      expect(formatDuration(0), '0:00');
      expect(formatDuration(-5000), '0:00');
    });

    test('abaixo de uma hora no formato M:SS', () {
      expect(formatDuration(65000), '1:05');
      expect(formatDuration(5000), '0:05');
      expect(formatDuration(599000), '9:59');
    });

    test('com horas no formato H:MM:SS', () {
      expect(formatDuration(3661000), '1:01:01');
      expect(formatDuration(3600000), '1:00:00');
    });
  });

  group('formatPace', () {
    test('metrico por km', () {
      // 1 km em 5 min => 300 s / 1000 m = 0.3 s/m
      expect(formatPace(0.3), '5:00 /km');
      expect(formatPace(0.36), '6:00 /km');
    });

    test('imperial por milha', () {
      // 0.3 s/m * 1609.344 m = 482.8 s ~= 8:03
      expect(formatPace(0.3, metric: false), '8:03 /mi');
    });

    test('null, zero, negativo e nao finito retornam placeholder', () {
      expect(formatPace(null), '--:-- /km');
      expect(formatPace(0), '--:-- /km');
      expect(formatPace(-1), '--:-- /km');
      expect(formatPace(double.infinity), '--:-- /km');
      expect(formatPace(null, metric: false), '--:-- /mi');
    });
  });

  group('formatSpeed', () {
    test('metrico em km/h com 1 casa', () {
      expect(formatSpeed(10), '36.0 km/h');
      expect(formatSpeed(0), '0.0 km/h');
    });

    test('imperial em mph com 1 casa', () {
      // 10 m/s => 22.369... mph
      expect(formatSpeed(10, metric: false), '22.4 mph');
    });

    test('nao finito retorna placeholder', () {
      expect(formatSpeed(double.nan), '-- km/h');
    });
  });

  group('formatElevation', () {
    test('metrico inteiro', () {
      expect(formatElevation(123.4), '123 m');
      expect(formatElevation(123.6), '124 m');
    });

    test('imperial em pes', () {
      // 100 m * 3.280839895 = 328.08 ft => 328
      expect(formatElevation(100, metric: false), '328 ft');
    });

    test('nao finito retorna placeholder', () {
      expect(formatElevation(double.nan, metric: false), '-- ft');
    });
  });
}
