// Sanidade da tabela fixa do plano Do Zero aos 5 km (F06).
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/plan5k/domain/plan_table.dart';

void main() {
  final plan = kPlan5k;

  test('10 semanas x 3 sessoes = 30 sessoes, em ordem', () {
    expect(plan, hasLength(30));
    for (var i = 0; i < 30; i++) {
      expect(plan[i].week, i ~/ 3 + 1);
      expect(plan[i].number, i % 3 + 1);
    }
    expect(sessionAt(4, 2), same(plan[10]));
  });

  test('toda sessao comeca com 5 min de aquecimento e termina com 5 min caminhando', () {
    for (final s in plan) {
      expect(s.blocks.first.kind, BlockKind.warmup, reason: s.label);
      expect(s.blocks.first.durationMs, 5 * 60000, reason: s.label);
      expect(s.blocks.last.kind, BlockKind.cooldown, reason: s.label);
      expect(s.blocks.last.durationMs, 5 * 60000, reason: s.label);
      // No meio so corrida e caminhada, alternadas, abrindo e fechando com corrida.
      final middle = s.blocks.sublist(1, s.blocks.length - 1);
      expect(middle.first.kind, BlockKind.run, reason: s.label);
      expect(middle.last.kind, BlockKind.run, reason: s.label);
      for (var i = 0; i < middle.length; i++) {
        expect(middle[i].kind, i.isEven ? BlockKind.run : BlockKind.walk, reason: s.label);
        expect(middle[i].durationMs, greaterThan(0));
      }
    }
  });

  test('duracao de cada sessao entre 20 e 40 minutos', () {
    for (final s in plan) {
      expect(s.totalMs, inInclusiveRange(20 * 60000, 40 * 60000), reason: s.label);
    }
  });

  test('tempo necessario para concluir: tudo menos o desaquecimento', () {
    expect(plan.first.requiredMs, plan.first.totalMs - 5 * 60000);
    expect(plan.first.requiredMs, 1410 * 1000);
    for (final s in plan) {
      expect(s.requiredMs, s.totalMs - s.blocks.last.durationMs);
    }
  });

  test('comeca leve: 60 s correndo e 90 s caminhando', () {
    final first = plan.first.blocks;
    expect(first[1].durationMs, 60000);
    expect(first[2].durationMs, 90000);
  });

  test('tempo de corrida nunca cai mais que 10% de uma sessao para a seguinte', () {
    for (var i = 1; i < plan.length; i++) {
      final prev = plan[i - 1].runMs;
      expect(plan[i].runMs, greaterThanOrEqualTo(prev * 0.9), reason: plan[i].label);
    }
    // E termina bem acima de onde comecou.
    expect(plan.last.runMs, greaterThan(plan.first.runMs * 3));
  });

  test('ultima sessao: 30 min de corrida continua', () {
    final runs = plan.last.blocks.where((b) => b.kind == BlockKind.run).toList();
    expect(runs, hasLength(1));
    expect(runs.single.durationMs, 30 * 60000);
  });

  test('resumo legivel dos blocos', () {
    expect(plan.first.summary, '8 x (1 min correndo + 1 min 30 s caminhando)');
    expect(plan.last.summary, '30 min correndo sem parar');
    expect(sessionAt(7, 1).summary, '10 min + 10 min + 6 min correndo, com 1 min 30 s caminhando entre elas');
    expect(plan.first.label, 'Semana 1, sessao 1');
    expect(formatPlanDuration(90000), '1 min 30 s');
    expect(formatPlanDuration(5 * 60000), '5 min');
    expect(formatPlanDuration(45000), '45 s');
  });
}
