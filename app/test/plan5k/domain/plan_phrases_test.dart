// Falas do plano (F06): curtas, sem pace, com a duracao do bloco.
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/plan5k/domain/guided_engine.dart';
import 'package:strava_estudo_app/plan5k/domain/plan_phrases.dart';
import 'package:strava_estudo_app/plan5k/domain/plan_table.dart';

BlockStarted started(BlockKind k, int ms, {bool last = false, bool resumed = false, int? remaining}) =>
    BlockStarted(
      index: 1,
      block: PlanBlock(k, ms),
      lastRun: last,
      remainingMs: remaining ?? ms,
      resumed: resumed,
    );

void main() {
  test('duracao falada com numeros', () {
    expect(spokenPlanDuration(90000), '1 minuto e 30 segundos');
    expect(spokenPlanDuration(120000), '2 minutos');
    expect(spokenPlanDuration(60000), '1 minuto');
    expect(spokenPlanDuration(45000), '45 segundos');
    expect(spokenPlanDuration(1000), '1 segundo');
    expect(spokenPlanDuration(61000), '1 minuto e 1 segundo');
  });

  test('trocas de bloco', () {
    expect(planPhrase(started(BlockKind.run, 90000)), 'Corra por 1 minuto e 30 segundos.');
    expect(planPhrase(started(BlockKind.walk, 120000)), 'Caminhe por 2 minutos.');
    expect(planPhrase(started(BlockKind.warmup, 300000)), 'Aquecimento. Caminhe por 5 minutos.');
    expect(
      planPhrase(started(BlockKind.run, 300000, last: true)),
      'Ultimo bloco de corrida. Corra por 5 minutos.',
    );
  });

  test('avisos e fim', () {
    expect(planPhrase(const TenSecondsLeft(PlanBlock(BlockKind.run, 1))), 'Faltam 10 segundos para correr.');
    expect(planPhrase(const TenSecondsLeft(PlanBlock(BlockKind.walk, 1))), 'Faltam 10 segundos para caminhar.');
    expect(planPhrase(const TenSecondsLeft(PlanBlock(BlockKind.cooldown, 1))), 'Faltam 10 segundos para caminhar.');
    expect(planPhrase(const Halfway()), 'Metade da sessao.');
    expect(planPhrase(const RunPhaseDone(remainingMs: 300000)), 'Corridas de hoje concluidas. Caminhe 5 minutos para desacelerar.');
    expect(planPhrase(const SessionCompleted()), 'Plano de hoje concluido.');
  });

  test('retomada fala o que falta do bloco atual', () {
    expect(
      planPhrase(started(BlockKind.run, 90000, resumed: true, remaining: 40000)),
      'Sessao retomada. Corra por mais 40 segundos.',
    );
    expect(
      planPhrase(const RunPhaseDone(remainingMs: 120000, resumed: true)),
      'Sessao retomada. Caminhe por mais 2 minutos para desacelerar.',
    );
  });

  test('nenhuma fala menciona ritmo', () {
    final all = [
      for (final k in BlockKind.values) planPhrase(started(k, 90000)),
      planPhrase(const Halfway()),
    ];
    for (final p in all) {
      expect(p!.toLowerCase(), isNot(contains('pace')));
      expect(p.toLowerCase(), isNot(contains('ritmo')));
    }
  });

  test('rotulos do bloco na tela', () {
    expect(blockLabel(BlockKind.run), 'Correr');
    expect(blockLabel(BlockKind.walk), 'Caminhar');
    expect(blockLabel(BlockKind.warmup), 'Aquecer caminhando');
    expect(blockLabel(BlockKind.cooldown), 'Desacelerar caminhando');
  });
}
