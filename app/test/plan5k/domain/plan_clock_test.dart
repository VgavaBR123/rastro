// Relogio do plano (F06): anda pelo relogio monotonico enquanto a gravacao
// nao esta pausada, mesmo sem ponto de GPS entre um tick e outro.
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/plan5k/domain/plan_clock.dart';

void main() {
  test('anda com os ticks, sem precisar de ponto de GPS', () {
    final c = PlanClock();
    c.observe(1000, paused: false);
    expect(c.observe(2000, paused: false), 1000);
    expect(c.observe(31000, paused: false), 30000);
  });

  test('pausa (manual ou automatica) congela; retomar volta a contar', () {
    final c = PlanClock();
    c.observe(0, paused: false);
    c.observe(10000, paused: true); // pausou aos 10 s
    expect(c.observe(50000, paused: true), 10000);
    c.observe(60000, paused: false); // retomou aos 60 s
    expect(c.observe(65000, paused: false), 15000);
  });

  test('a primeira observacao so marca o inicio', () {
    final c = PlanClock();
    expect(c.observe(5000, paused: false), 0);
  });

  test('instante que volta nao desconta tempo', () {
    final c = PlanClock();
    c.observe(10000, paused: false);
    c.observe(20000, paused: false);
    expect(c.observe(15000, paused: false), 10000);
    expect(c.observe(21000, paused: false), 11000);
  });

  test('comeca de um tempo ja andado (retomada)', () {
    final c = PlanClock(startMs: 90000);
    c.observe(0, paused: false);
    expect(c.observe(1000, paused: false), 91000);
  });
}
