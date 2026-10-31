// Motor da sessao guiada (F06): blocos por tempo do plano injetado, voltas a
// fechar, falas e as bordas (salto grande entre ticks, retomada, tempo que
// volta).
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/plan5k/domain/guided_engine.dart';
import 'package:strava_estudo_app/plan5k/domain/plan_table.dart';

const s = 1000;
const min = 60000;

/// Sessao curta de teste: 5 min aquece, 60 s corre, 90 s caminha, 60 s
/// corre, 5 min desacelera. Total 13,5 min.
const short = PlanSession(week: 1, number: 1, blocks: [
  PlanBlock(BlockKind.warmup, 5 * min),
  PlanBlock(BlockKind.run, 60 * s),
  PlanBlock(BlockKind.walk, 90 * s),
  PlanBlock(BlockKind.run, 60 * s),
  PlanBlock(BlockKind.cooldown, 5 * min),
]);

List<Type> types(GuidedStep st) => [for (final e in st.events) e.runtimeType];

void main() {
  late GuidedSessionEngine e;
  setUp(() => e = GuidedSessionEngine(short));

  test('comecar anuncia o aquecimento, sem volta', () {
    final st = e.start();
    expect(st.lapsToClose, 0);
    final ev = st.events.single as BlockStarted;
    expect(ev.index, 0);
    expect(ev.block.kind, BlockKind.warmup);
    expect(ev.remainingMs, 5 * min);
  });

  test('aviso de 10 s antes da troca e troca de bloco fecha uma volta', () {
    e.start();
    expect(e.advanceTo(280 * s).events, isEmpty);
    final warn = e.advanceTo(291 * s);
    expect(warn.lapsToClose, 0);
    expect((warn.events.single as TenSecondsLeft).next.kind, BlockKind.run);
    // O aviso sai uma vez so.
    expect(e.advanceTo(295 * s).events, isEmpty);
    final change = e.advanceTo(300 * s);
    expect(change.lapsToClose, 1);
    expect(change.skippedBlocks, 0);
    final b = change.events.single as BlockStarted;
    expect(b.index, 1);
    expect(b.block.kind, BlockKind.run);
    expect(b.lastRun, isFalse);
  });

  test('o mesmo instante (pausa) ou tempo que volta nao gera nada', () {
    e.start();
    e.advanceTo(100 * s);
    expect(e.advanceTo(100 * s).events, isEmpty);
    expect(e.advanceTo(50 * s).events, isEmpty);
    expect(e.view().elapsedMs, 100 * s);
  });

  test('salto grande entre ticks: fecha UMA volta com o trecho todo e fala so o atual', () {
    e.start();
    // Do aquecimento direto para o meio da caminhada: passou a 1a corrida e o
    // aviso de 10 s ficou para tras.
    final st = e.advanceTo(300 * s + 60 * s + 30 * s);
    expect(st.lapsToClose, 1);
    expect(st.skippedBlocks, 1);
    final b = st.events.single as BlockStarted;
    expect(b.index, 2);
    expect(b.block.kind, BlockKind.walk);
    expect(b.remainingMs, 60 * s);
  });

  test('metade da sessao e avisada uma vez', () {
    e.start();
    final half = short.totalMs ~/ 2; // 405 s, no meio da caminhada
    e.advanceTo(half - 5 * s);
    final st = e.advanceTo(half + s);
    expect(st.events.single, isA<Halfway>());
    expect(e.advanceTo(half + 2 * s).events, isEmpty);
  });

  test('salto de mais de um bloco que passa da metade nao fala a metade', () {
    e.start();
    final st = e.advanceTo(480 * s); // na 2a corrida: passou 3 trocas
    expect(st.lapsToClose, 1);
    expect(st.skippedBlocks, 2);
    expect(types(st), [BlockStarted]);
    expect(e.advanceTo(481 * s).events, isEmpty);
  });

  test('ultima corrida, fim das corridas e fim do plano', () {
    e.start();
    e.advanceTo(449 * s);
    final last = e.advanceTo(450 * s);
    expect((last.events.single as BlockStarted).lastRun, isTrue);
    e.advanceTo(505 * s);
    final cool = e.advanceTo(510 * s);
    expect(cool.lapsToClose, 1);
    expect(cool.events.single, isA<RunPhaseDone>());
    e.advanceTo(805 * s);
    final end = e.advanceTo(810 * s);
    expect(end.lapsToClose, 1);
    expect(end.events.single, isA<SessionCompleted>());
    expect(e.isCompleted, isTrue);
    // Depois do fim, nada mais.
    final after = e.advanceTo(900 * s);
    expect(after.events, isEmpty);
    expect(after.lapsToClose, 0);
  });

  test('sem aviso de 10 s antes do fim do desaquecimento', () {
    e.start();
    e.advanceTo(790 * s);
    expect(e.advanceTo(801 * s).events, isEmpty);
  });

  test('salto alem do fim: fecha todas as voltas que faltam e fala so o fim', () {
    e.start();
    final st = e.advanceTo(2 * 3600 * s);
    expect(st.lapsToClose, 1);
    expect(st.skippedBlocks, 4);
    expect(types(st), [SessionCompleted]);
  });

  test('salto que cai no desaquecimento fala o fim das corridas', () {
    e.start();
    final st = e.advanceTo(600 * s);
    expect(st.lapsToClose, 1);
    expect(st.skippedBlocks, 3);
    expect(types(st), [RunPhaseDone]);
  });

  test('troca que coincide com a metade fala o bloco e a metade', () {
    const even = PlanSession(week: 1, number: 1, blocks: [
      PlanBlock(BlockKind.warmup, 5 * min),
      PlanBlock(BlockKind.run, 5 * min),
      PlanBlock(BlockKind.walk, 5 * min),
      PlanBlock(BlockKind.run, 5 * min),
      PlanBlock(BlockKind.cooldown, 5 * min),
    ]);
    final g = GuidedSessionEngine(even)..start();
    g.advanceTo(12 * min + 29 * s);
    final st = g.advanceTo(12 * min + 30 * s);
    expect(st.lapsToClose, 0);
    expect(types(st), [Halfway]);
    final g2 = GuidedSessionEngine(const PlanSession(week: 1, number: 1, blocks: [
      PlanBlock(BlockKind.warmup, 5 * min),
      PlanBlock(BlockKind.run, 5 * min),
      PlanBlock(BlockKind.walk, 5 * min),
      PlanBlock(BlockKind.cooldown, 5 * min),
    ]))..start();
    g2.advanceTo(9 * min + 59 * s);
    final st2 = g2.advanceTo(10 * min);
    expect(st2.lapsToClose, 1);
    expect(types(st2), [BlockStarted, Halfway]);
  });

  test('sessao com uma corrida so nao diz ultimo bloco', () {
    final g = GuidedSessionEngine(kPlan5k.last)..start();
    final st = g.advanceTo(5 * min);
    expect((st.events.single as BlockStarted).lastRun, isFalse);
  });

  test('retomar no meio de um bloco: continua de la sem repetir o que passou', () {
    final st = e.restore(330 * s); // 30 s dentro da 1a corrida
    expect(st.lapsToClose, 0);
    final b = st.events.single as BlockStarted;
    expect(b.resumed, isTrue);
    expect(b.index, 1);
    expect(b.remainingMs, 30 * s);
    expect(e.advanceTo(351 * s).events.single, isA<TenSecondsLeft>());
    expect(e.advanceTo(360 * s).lapsToClose, 1);
  });

  test('retomar depois da metade nao avisa a metade de novo', () {
    e.restore(420 * s);
    expect(types(e.advanceTo(421 * s)), isEmpty);
  });

  test('retomar alem do fim: sessao ja concluida, sem falas', () {
    final st = e.restore(900 * s);
    expect(st.events, isEmpty);
    expect(e.isCompleted, isTrue);
  });

  test('visao do bloco: atual, restante, proximo e progresso', () {
    e.start();
    e.advanceTo(320 * s);
    final v = e.view();
    expect(v.index, 1);
    expect(v.block!.kind, BlockKind.run);
    expect(v.remainingMs, 40 * s);
    expect(v.next!.kind, BlockKind.walk);
    expect(v.progress, closeTo(320 / 810, 1e-9));
    expect(v.blockCount, 5);
    e.advanceTo(900 * s);
    final done = e.view();
    expect(done.completed, isTrue);
    expect(done.block, isNull);
    expect(done.progress, 1);
  });
}
