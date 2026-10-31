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

    test(
      'INI-04: metrico igual ou acima de 1 km em km com 2 casas e virgula',
      () {
        expect(formatDistance(1000), '1,00 km');
        expect(formatDistance(1234.5), '1,23 km');
        expect(formatDistance(2500), '2,50 km');
      },
    );

    test('INI-04: imperial em milhas com 2 casas e virgula', () {
      expect(formatDistance(1609.344, metric: false), '1,00 mi');
      expect(formatDistance(804.672, metric: false), '0,50 mi');
    });

    test('EST-05: imperial abaixo de 0,1 mi em pes inteiros', () {
      expect(formatDistance(0, metric: false), '0 ft');
      expect(formatDistance(100, metric: false), '328 ft');
      // 0,1 mi = 160,9344 m: dai para cima volta para milhas.
      expect(formatDistance(160, metric: false), '525 ft');
      expect(formatDistance(160.9344, metric: false), '0,10 mi');
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
      expect(formatSpeed(10), '36,0 km/h');
      expect(formatSpeed(0), '0,0 km/h');
    });

    test('imperial em mph com 1 casa', () {
      // 10 m/s => 22.369... mph
      expect(formatSpeed(10, metric: false), '22,4 mph');
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

  group('formatDecimal', () {
    test('INI-04: virgula como separador decimal', () {
      expect(formatDecimal(12.345, 1), '12,3');
      expect(formatDecimal(0, 2), '0,00');
      expect(formatDecimal(7, 0), '7');
    });
  });

  group('formatTotalDuration (EST-04)', () {
    test('zero e negativos', () {
      expect(formatTotalDuration(0), '0 min');
      expect(formatTotalDuration(-5000), '0 min');
    });

    test('abaixo de 1 minuto em segundos', () {
      expect(formatTotalDuration(6000), '6 s');
      expect(formatTotalDuration(59999), '59 s');
    });

    test('abaixo de 1 hora em minutos inteiros', () {
      expect(formatTotalDuration(60000), '1 min');
      expect(formatTotalDuration(6 * 60000 + 59000), '6 min');
      expect(formatTotalDuration(59 * 60000), '59 min');
    });

    test('com horas em H:MM h', () {
      expect(formatTotalDuration(3600000), '1:00 h');
      expect(formatTotalDuration(3600000 + 5 * 60000 + 30000), '1:05 h');
      expect(formatTotalDuration(12 * 3600000 + 30 * 60000), '12:30 h');
    });
  });

  group('spokenMeasure (leitor de tela)', () {
    test('troca a abreviacao pela palavra', () {
      expect(spokenMeasure('12,4 km'), '12,4 quilometros');
      expect(spokenMeasure('500 m'), '500 metros');
      expect(spokenMeasure('1 m'), '1 metro');
      expect(spokenMeasure('0,50 mi'), '0,50 milhas');
      expect(spokenMeasure('328 ft'), '328 pes');
      expect(spokenMeasure('36,0 km/h'), '36,0 quilometros por hora');
      expect(spokenMeasure('22,4 mph'), '22,4 milhas por hora');
      expect(spokenMeasure('5:00 /km'), '5:00 por quilometro');
      expect(spokenMeasure('6 s'), '6 segundos');
      expect(spokenMeasure('1 min'), '1 minuto');
      expect(spokenMeasure('6 min'), '6 minutos');
    });

    test('horas viram "H horas e M minutos"', () {
      expect(spokenMeasure('1:05 h'), '1 hora e 5 minutos');
      expect(spokenMeasure('2:00 h'), '2 horas');
      expect(spokenMeasure('12:30 h'), '12 horas e 30 minutos');
    });

    test('sem unidade conhecida fica igual', () {
      expect(spokenMeasure('7'), '7');
      expect(spokenMeasure('1:02:03'), '1:02:03');
    });
  });
}
