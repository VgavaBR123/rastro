// Privacidade automatica (F02): aviso de rotina previsivel (>= 4 das ultimas
// 6 atividades no mesmo lugar e na mesma faixa de horario).
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/privacy/domain/routine.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';

const casa = GeoPoint(latitude: 0, longitude: 0);
const longe = GeoPoint(latitude: 0.1, longitude: 0.1);

GeoPoint perto(double metros) =>
    GeoPoint(latitude: metros / 111195, longitude: 0);

ActivityStartSample at(GeoPoint p, int h, int m) =>
    ActivityStartSample(start: p, minuteOfDay: h * 60 + m);

void main() {
  test('4 de 6 no mesmo lugar e horario: previsivel', () {
    expect(
      isRoutinePredictable([
        at(casa, 6, 0),
        at(perto(50), 6, 20),
        at(longe, 18, 0),
        at(perto(100), 5, 40),
        at(longe, 12, 0),
        at(casa, 6, 10),
      ]),
      isTrue,
    );
  });

  test('3 de 6: nao avisa', () {
    expect(
      isRoutinePredictable([
        at(casa, 6, 0),
        at(perto(50), 6, 20),
        at(longe, 18, 0),
        at(perto(100), 5, 40),
        at(longe, 12, 0),
        at(longe, 6, 10),
      ]),
      isFalse,
    );
  });

  test('mesmo lugar mas horarios espalhados: nao avisa', () {
    expect(
      isRoutinePredictable([
        at(casa, 6, 0),
        at(casa, 9, 0),
        at(casa, 12, 0),
        at(casa, 18, 0),
        at(casa, 21, 0),
      ]),
      isFalse,
    );
  });

  test('mesmo horario mas lugares a mais de 150 m: nao avisa', () {
    expect(
      isRoutinePredictable([
        at(casa, 6, 0),
        at(perto(300), 6, 0),
        at(perto(600), 6, 0),
        at(perto(900), 6, 0),
      ]),
      isFalse,
    );
  });

  test('faixa de horario passa pela meia-noite', () {
    expect(
      isRoutinePredictable([
        at(casa, 23, 50),
        at(casa, 0, 10),
        at(casa, 23, 40),
        at(casa, 0, 5),
      ]),
      isTrue,
    );
  });

  test('so as 6 mais recentes contam', () {
    expect(
      isRoutinePredictable([
        at(longe, 12, 0),
        at(longe, 13, 0),
        at(perto(5000), 14, 0),
        at(perto(9000), 15, 0),
        at(casa, 6, 0),
        at(casa, 6, 0),
        // fora da janela
        at(casa, 6, 0),
        at(casa, 6, 0),
      ]),
      isFalse,
    );
  });

  test('menos de 4 atividades: nao avisa', () {
    expect(isRoutinePredictable([at(casa, 6, 0), at(casa, 6, 0)]), isFalse);
    expect(isRoutinePredictable(const []), isFalse);
  });

  group('isRoutinePredictableFor (atividade compartilhada)', () {
    test('a atividade faz parte da rotina: avisa', () {
      expect(
        isRoutinePredictableFor(at(casa, 6, 0), [
          at(perto(50), 6, 20),
          at(longe, 18, 0),
          at(perto(100), 5, 40),
          at(casa, 6, 10),
          at(longe, 12, 0),
        ]),
        isTrue,
      );
    });

    test('rotina existe, mas a atividade nao tem relacao com ela: nao avisa', () {
      expect(
        isRoutinePredictableFor(at(longe, 18, 0), [
          at(casa, 6, 0),
          at(perto(50), 6, 20),
          at(perto(100), 5, 40),
          at(casa, 6, 10),
          at(casa, 6, 5),
        ]),
        isFalse,
      );
    });

    test('so as 5 anteriores mais recentes completam a janela', () {
      expect(
        isRoutinePredictableFor(at(casa, 6, 0), [
          at(longe, 18, 0),
          at(longe, 12, 0),
          at(casa, 6, 0),
          at(longe, 9, 0),
          at(longe, 10, 0),
          // Fora da janela de 6.
          at(casa, 6, 0),
          at(casa, 6, 0),
        ]),
        isFalse,
      );
    });
  });
}
