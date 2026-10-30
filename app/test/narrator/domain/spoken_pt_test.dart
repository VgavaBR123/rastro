// Numeros, duracoes, distancias e pace falados em portugues (F03).
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/narrator/domain/spoken_pt.dart';

void main() {
  group('numberWords', () {
    test('unidades, dezenas e especiais', () {
      expect(numberWords(0), 'zero');
      expect(numberWords(1), 'um');
      expect(numberWords(2), 'dois');
      expect(numberWords(10), 'dez');
      expect(numberWords(11), 'onze');
      expect(numberWords(16), 'dezesseis');
      expect(numberWords(19), 'dezenove');
      expect(numberWords(20), 'vinte');
      expect(numberWords(32), 'trinta e dois');
      expect(numberWords(99), 'noventa e nove');
    });

    test('centenas: cem, cento e, duzentos', () {
      expect(numberWords(100), 'cem');
      expect(numberWords(101), 'cento e um');
      expect(numberWords(200), 'duzentos');
      expect(numberWords(345), 'trezentos e quarenta e cinco');
      expect(numberWords(999), 'novecentos e noventa e nove');
    });

    test('milhares', () {
      expect(numberWords(1000), 'mil');
      expect(numberWords(1001), 'mil e um');
      expect(numberWords(1100), 'mil e cem');
      expect(numberWords(1234), 'mil duzentos e trinta e quatro');
      expect(numberWords(2000), 'dois mil');
      expect(numberWords(21500), 'vinte e um mil e quinhentos');
    });

    test('feminino em um e dois (e nas centenas)', () {
      expect(numberWords(1, feminine: true), 'uma');
      expect(numberWords(2, feminine: true), 'duas');
      expect(numberWords(22, feminine: true), 'vinte e duas');
      expect(numberWords(12, feminine: true), 'doze');
      expect(numberWords(200, feminine: true), 'duzentas');
    });

    test('negativo vira zero', () {
      expect(numberWords(-3), 'zero');
    });
  });

  group('spokenDuration', () {
    test('minutos e segundos', () {
      expect(spokenDuration(332000), 'cinco minutos e trinta e dois segundos');
      expect(spokenDuration(61000), 'um minuto e um segundo');
    });

    test('sem a parte zerada', () {
      expect(spokenDuration(300000), 'cinco minutos');
      expect(spokenDuration(45000), 'quarenta e cinco segundos');
      expect(spokenDuration(3600000), 'uma hora');
    });

    test('horas no feminino', () {
      expect(spokenDuration(3600000 + 2 * 60000 + 5000),
          'uma hora, dois minutos e cinco segundos');
      expect(spokenDuration(2 * 3600000 + 60000), 'duas horas e um minuto');
    });

    test('zero ou negativo', () {
      expect(spokenDuration(0), 'zero segundos');
      expect(spokenDuration(-10), 'zero segundos');
    });
  });

  group('spokenPace', () {
    test('minutos e segundos por unidade (5:32 /km)', () {
      expect(spokenPace(332 / 1000, metric: true), 'cinco e trinta e dois');
    });

    test('segundos zerados', () {
      expect(spokenPace(0.3, metric: true), 'cinco minutos');
      expect(spokenPace(0.06, metric: true), 'um minuto');
    });

    test('milha', () {
      expect(spokenPace(480 / 1609.344, metric: false), 'oito minutos');
    });

    test('invalido ou absurdo vira null', () {
      expect(spokenPace(null, metric: true), isNull);
      expect(spokenPace(0, metric: true), isNull);
      expect(spokenPace(double.nan, metric: true), isNull);
      expect(spokenPace(3.6, metric: true), isNull); // 60 min/km
    });
  });

  group('spokenDistance', () {
    test('quilometros inteiros e com decimais', () {
      expect(spokenDistance(1000, metric: true), 'um quilômetro');
      expect(spokenDistance(3000, metric: true), 'três quilômetros');
      expect(spokenDistance(3250, metric: true), 'três vírgula vinte e cinco quilômetros');
      expect(spokenDistance(5200, metric: true), 'cinco vírgula dois quilômetros');
      expect(spokenDistance(5004, metric: true), 'cinco quilômetros');
    });

    test('abaixo de 1 km fala metros', () {
      expect(spokenDistance(450, metric: true), 'quatrocentos e cinquenta metros');
      expect(spokenDistance(1, metric: true), 'um metro');
    });

    test('milhas no feminino', () {
      expect(spokenDistance(1609.344, metric: false), 'uma milha');
      expect(spokenDistance(2 * 1609.344, metric: false), 'duas milhas');
      expect(spokenDistance(0.5 * 1609.344, metric: false), 'zero vírgula cinco milhas');
    });

    test('invalido vira zero', () {
      expect(spokenDistance(double.nan, metric: true), 'zero metros');
    });
  });

  group('spokenSplitMark', () {
    test('marca do split na unidade', () {
      expect(spokenSplitMark(1, metric: true), 'Um quilômetro');
      expect(spokenSplitMark(2, metric: true), 'Dois quilômetros');
      expect(spokenSplitMark(1, metric: false), 'Uma milha');
      expect(spokenSplitMark(21, metric: false), 'Vinte e uma milhas');
    });
  });

  group('spokenSpeed', () {
    test('uma casa decimal, sem ",0"', () {
      expect(spokenSpeed(25.3 / 3.6, metric: true), 'vinte e cinco vírgula três quilômetros por hora');
      expect(spokenSpeed(20 / 3.6, metric: true), 'vinte quilômetros por hora');
      expect(spokenSpeed(1609.344 / 3600 * 12, metric: false), 'doze milhas por hora');
    });

    test('invalido vira null', () {
      expect(spokenSpeed(0, metric: true), isNull);
      expect(spokenSpeed(double.infinity, metric: true), isNull);
    });
  });
}
