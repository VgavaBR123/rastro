// Testes da reconstrucao de splits a partir dos pontos persistidos.
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/recording/domain/splits_from_waypoints.dart';

List<SplitSourcePoint> pontos(List<List<num>> pares) => [
      for (final p in pares)
        SplitSourcePoint(
          cumulativeDistanceMeters: p[0].toDouble(),
          timerTimeMs: p[1].toInt(),
        ),
    ];

void main() {
  test('atividade sem pontos nao tem splits', () {
    expect(splitsFromPoints(const [], metric: true), isEmpty);
  });

  test('atividade curta so tem o trecho parcial', () {
    // 400 m em 2 min: nenhuma marca de 1 km fechada.
    final s = splitsFromPoints(pontos([
      [0, 0],
      [400, 120000],
    ]), metric: true);

    expect(s, hasLength(1));
    expect(s.first.complete, isFalse);
    expect(s.first.number, 1);
    expect(s.first.endDistanceMeters, 400);
    expect(s.first.durationMs, 120000);
  });

  test('atividade curta sem parcial quando includePartial e false', () {
    final s = splitsFromPoints(pontos([
      [0, 0],
      [400, 120000],
    ]), metric: true, includePartial: false);
    expect(s, isEmpty);
  });

  test('tres km fechados mais um trecho parcial', () {
    // Ritmo constante de 5 min/km (300 s/km) ate 3500 m.
    final s = splitsFromPoints(pontos([
      [0, 0],
      [1000, 300000],
      [2000, 600000],
      [3000, 900000],
      [3500, 1050000],
    ]), metric: true);

    expect(s, hasLength(4));
    for (var i = 0; i < 3; i++) {
      expect(s[i].complete, isTrue);
      expect(s[i].number, i + 1);
      expect(s[i].endDistanceMeters, (i + 1) * 1000.0);
      expect(s[i].durationMs, 300000);
      expect(splitPaceSecondsPerMeter(s[i]), closeTo(0.3, 1e-9));
    }
    expect(s.last.complete, isFalse);
    expect(s.last.endDistanceMeters, 3500);
    expect(s.last.durationMs, 150000);
  });

  test('fecha a marca com tempo interpolado quando o ponto passa longe', () {
    // Salto de 0 para 2000 m em 600 s: 1 km fecha na metade (300 s).
    final s = splitsFromPoints(pontos([
      [0, 0],
      [2000, 600000],
    ]), metric: true);

    expect(s, hasLength(2));
    expect(s[0].endTimerMs, 300000);
    expect(s[1].durationMs, 300000);
  });

  test('unidade imperial fecha na milha', () {
    final s = splitsFromPoints(pontos([
      [0, 0],
      [1609.344, 480000],
    ]), metric: false);

    expect(s, hasLength(1));
    expect(s.first.complete, isTrue);
    expect(s.first.endDistanceMeters, closeTo(1609.344, 1e-6));
    expect(s.first.durationMs, 480000);
  });

  test('ignora retrocesso de distancia acumulada', () {
    final s = splitsFromPoints(pontos([
      [0, 0],
      [1200, 300000],
      [900, 310000], // lixo: distancia acumulada nao retrocede
      [2000, 500000],
    ]), metric: true);

    expect(s, hasLength(2));
    expect(s[0].complete, isTrue);
    expect(s[0].endDistanceMeters, 1000);
    expect(s[1].endDistanceMeters, 2000);
    // 2000 m cai exatamente na marca: nao sobra trecho parcial.
    expect(s[1].complete, isTrue);
  });

  test('pace do trecho e null quando nao da para calcular', () {
    final s = splitsFromPoints(pontos([
      [0, 0],
      [500, 0], // sem duracao
    ]), metric: true);
    expect(s, hasLength(1));
    expect(splitPaceSecondsPerMeter(s.first), isNull);
  });

  group('fim da atividade (finalTimerMs)', () {
    test('trecho parcial vai ate o cronometro final da atividade', () {
      // Ultimo ponto aceito aos 41 s, mas o cronometro seguiu ate 53 s
      // (parado sem auto-pausa ate tocar em Encerrar).
      final s = splitsFromPoints(pontos([
        [0, 0],
        [668, 41000],
      ]), metric: true, finalTimerMs: 53000);

      expect(s.single.complete, isFalse);
      expect(s.single.endTimerMs, 53000);
      expect(s.single.durationMs, 53000);
      expect(s.single.distanceMeters, 668);
    });

    test('soma das duracoes bate com o tempo total', () {
      final s = splitsFromPoints(pontos([
        [0, 0],
        [1000, 300000],
        [1500, 450000],
      ]), metric: true, finalTimerMs: 480000);

      expect(s, hasLength(2));
      expect(s.first.durationMs, 300000, reason: 'split fechado nao muda');
      expect(s.fold<int>(0, (t, x) => t + x.durationMs), 480000);
    });

    test('final menor que o ultimo ponto nao encurta o trecho', () {
      final s = splitsFromPoints(pontos([
        [0, 0],
        [400, 120000],
      ]), metric: true, finalTimerMs: 100000);
      expect(s.single.endTimerMs, 120000);
    });
  });
}
