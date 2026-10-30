// Fechamento gentil (F04): esforco percebido (RPE 1-10), humor e carga do
// treino (sRPE = RPE x minutos de cronometro). Dart puro.
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/closing/domain/effort.dart';

void main() {
  group('RPE', () {
    test('rotulos curtos por faixa', () {
      expect(rpeLabel(1), 'Leve');
      expect(rpeLabel(2), 'Leve');
      expect(rpeLabel(3), 'Tranquilo');
      expect(rpeLabel(4), 'Tranquilo');
      expect(rpeLabel(5), 'Moderado');
      expect(rpeLabel(6), 'Moderado');
      expect(rpeLabel(7), 'Forte');
      expect(rpeLabel(8), 'Forte');
      expect(rpeLabel(9), 'Maximo');
      expect(rpeLabel(10), 'Maximo');
    });

    test('so 1 a 10 vale', () {
      expect(isValidRpe(0), isFalse);
      expect(isValidRpe(11), isFalse);
      expect(isValidRpe(null), isFalse);
      for (var i = 1; i <= 10; i++) {
        expect(isValidRpe(i), isTrue);
      }
      expect(() => rpeLabel(0), throwsArgumentError);
    });

    test('normalizeRpe descarta fora da faixa', () {
      expect(normalizeRpe(7), 7);
      expect(normalizeRpe(0), isNull);
      expect(normalizeRpe(12), isNull);
      expect(normalizeRpe(null), isNull);
    });
  });

  group('humor', () {
    test('cinco opcoes, do melhor para o pior, com texto', () {
      expect(Mood.values, hasLength(5));
      expect([for (final m in Mood.values) m.label], [
        'Otimo',
        'Bem',
        'Normal',
        'Cansado',
        'Pesado',
      ]);
    });

    test('valor do banco e do contrato ida e volta', () {
      for (final m in Mood.values) {
        expect(Mood.fromDb(m.dbValue), m);
      }
      expect(Mood.values.map((m) => m.dbValue).toList(), [
        'great',
        'good',
        'ok',
        'tired',
        'awful',
      ]);
      expect(Mood.fromDb(null), isNull);
      expect(Mood.fromDb('feliz'), isNull);
    });
  });

  group('carga do treino (sRPE)', () {
    test('RPE x minutos de cronometro, arredondado', () {
      expect(trainingLoad(rpe: 5, timerMs: 30 * 60000), 150);
      expect(trainingLoad(rpe: 7, timerMs: 45 * 60000 + 30000), 319); // 45,5 x 7
      expect(trainingLoad(rpe: 10, timerMs: 0), 0);
    });

    test('sem RPE valido nao ha carga', () {
      expect(trainingLoad(rpe: null, timerMs: 30 * 60000), isNull);
      expect(trainingLoad(rpe: 0, timerMs: 30 * 60000), isNull);
      expect(trainingLoad(rpe: 5, timerMs: -10), 0);
    });
  });
}
