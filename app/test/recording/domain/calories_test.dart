// Testes da estimativa de calorias por MET (Compendium 2011).
//
// Valores de referencia calculados a mao: kcal = MET x kg x horas, com o MET
// lido (ou interpolado linearmente) da tabela em mph.
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/recording/domain/calories.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';

const double milha = 1609.344;
const int umaHora = 3600000;

double? kcal(ActivityType t, int ms, double m, double? kg) =>
    estimateCaloriesKcal(
      type: t,
      timerTimeMs: ms,
      distanceMeters: m,
      weightKg: kg,
    );

void main() {
  group('entradas invalidas', () {
    test('sem peso -> null', () {
      expect(kcal(ActivityType.run, umaHora, 10000, null), isNull);
    });
    test('peso fora de 20..400 -> null', () {
      expect(kcal(ActivityType.run, umaHora, 10000, 19.9), isNull);
      expect(kcal(ActivityType.run, umaHora, 10000, 400.1), isNull);
      expect(kcal(ActivityType.run, umaHora, 10000, 20), isNotNull);
      expect(kcal(ActivityType.run, umaHora, 10000, 400), isNotNull);
    });
    test('tempo <= 0 -> null', () {
      expect(kcal(ActivityType.run, 0, 10000, 70), isNull);
      expect(kcal(ActivityType.run, -5, 10000, 70), isNull);
    });
  });

  group('pontos exatos da tabela', () {
    test('corrida 6 mph, 1 h, 70 kg: 9.8 x 70 x 1 = 686', () {
      expect(
        kcal(ActivityType.run, umaHora, 6 * milha, 70),
        closeTo(686, 1e-6),
      );
    });
    test('pedal 15 mph, 2 h, 80 kg: 10.0 x 80 x 2 = 1600', () {
      expect(
        kcal(ActivityType.ride, 2 * umaHora, 30 * milha, 80),
        closeTo(1600, 1e-6),
      );
    });
    test('caminhada 3 mph, 30 min, 60 kg: 3.5 x 60 x 0.5 = 105', () {
      expect(
        kcal(ActivityType.walk, umaHora ~/ 2, 1.5 * milha, 60),
        closeTo(105, 1e-6),
      );
    });
  });

  group('interpolacao', () {
    test('caminhada 3.25 mph: MET (3.5+4.3)/2 = 3.9; 1 h, 50 kg = 195', () {
      expect(
        kcal(ActivityType.walk, umaHora, 3.25 * milha, 50),
        closeTo(195, 1e-6),
      );
    });
    test('corrida 10 km em 1 h (6.2137 mph), 70 kg', () {
      // mph = 10000/1609.344 = 6.21371; f = (6.21371-6)/0.7 = 0.305300
      // MET = 9.8 + 0.7*0.305300 = 10.01371; kcal = 70 x 10.01371 = 700.96
      expect(kcal(ActivityType.run, umaHora, 10000, 70), closeTo(700.96, 0.01));
    });
    test('pedal 12 mph: MET (6.8+8.0)/2 = 7.4; 1 h, 100 kg = 740', () {
      expect(
        kcal(ActivityType.ride, umaHora, 12 * milha, 100),
        closeTo(740, 1e-6),
      );
    });
  });

  group('extremos', () {
    test('acima da tabela trava no maior MET (corrida 20 mph -> 23.0)', () {
      expect(
        kcal(ActivityType.run, umaHora, 20 * milha, 70),
        closeTo(23.0 * 70, 1e-6),
      );
    });
    test('abaixo da tabela trava no menor MET (corrida 2 mph -> 6.0)', () {
      expect(
        kcal(ActivityType.run, umaHora, 2 * milha, 70),
        closeTo(420, 1e-6),
      );
    });
    test('distância 0 com tempo usa o menor MET do esporte', () {
      expect(kcal(ActivityType.run, umaHora, 0, 70), closeTo(6.0 * 70, 1e-6));
      expect(kcal(ActivityType.walk, umaHora, 0, 70), closeTo(2.0 * 70, 1e-6));
      expect(kcal(ActivityType.ride, umaHora, 0, 70), closeTo(3.5 * 70, 1e-6));
    });
    test('cresce com a velocidade (monotonia)', () {
      double? anterior;
      for (double mph = 1; mph <= 25; mph += 0.5) {
        final double v = kcal(ActivityType.ride, umaHora, mph * milha, 70)!;
        if (anterior != null) expect(v, greaterThanOrEqualTo(anterior));
        anterior = v;
      }
    });
  });
}
