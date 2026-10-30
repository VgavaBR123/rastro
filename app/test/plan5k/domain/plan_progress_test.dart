// Progresso do plano (F06): proxima sessao, parcial que nao avanca, fim de
// semana e a regra "pesada demais repete a semana".
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/plan5k/domain/plan_progress.dart';
import 'package:strava_estudo_app/plan5k/domain/plan_table.dart';

SessionResult r(int week, int number, SessionStatus status, {int round = 0, int? rpe}) =>
    SessionResult(
      week: week,
      number: number,
      round: round,
      status: status,
      plannedMs: 1,
      movingMs: 1,
      rpe: rpe,
    );

void main() {
  const started = PlanState(started: true, startWeek: 1, currentWeek: 1);

  test('sem comecar: sem proxima sessao, tudo pela frente', () {
    final p = PlanProgress(const PlanState(), const []);
    expect(p.next, isNull);
    expect(p.markOf(1, 1), SessionMark.upcoming);
  });

  test('recem-comecado: proxima e a sessao 1 da semana inicial', () {
    final p = PlanProgress(started, const []);
    expect(p.next, same(sessionAt(1, 1)));
    expect(p.markOf(1, 1), SessionMark.next);
    expect(p.markOf(1, 2), SessionMark.upcoming);
  });

  test('semana inicial escolhida: as anteriores ficam puladas', () {
    final p = PlanProgress(const PlanState(started: true, startWeek: 4, currentWeek: 4), const []);
    expect(p.next, same(sessionAt(4, 1)));
    expect(p.markOf(3, 3), SessionMark.skipped);
  });

  test('sessao parcial nao avanca: a proxima continua sendo a mesma', () {
    final p = PlanProgress(started, [r(1, 1, SessionStatus.partial)]);
    expect(p.next, same(sessionAt(1, 1)));
    expect(p.markOf(1, 1), SessionMark.partial);
  });

  test('sessao em andamento (gravacao aberta) tambem nao conta', () {
    final p = PlanProgress(started, [r(1, 1, SessionStatus.inProgress)]);
    expect(p.next, same(sessionAt(1, 1)));
  });

  test('concluida avanca para a sessao seguinte; parcial depois de concluida nao apaga', () {
    final p = PlanProgress(started, [
      r(1, 1, SessionStatus.done),
      r(1, 2, SessionStatus.partial),
    ]);
    expect(p.markOf(1, 1), SessionMark.done);
    expect(p.markOf(1, 2), SessionMark.partial);
    expect(p.next, same(sessionAt(1, 2)));
  });

  test('3 sessoes concluidas: semana completa, sem proxima ate decidir', () {
    final p = PlanProgress(started, [
      r(1, 1, SessionStatus.done),
      r(1, 2, SessionStatus.done),
      r(1, 3, SessionStatus.done),
    ]);
    expect(p.weekComplete, isTrue);
    expect(p.next, isNull);
    expect(p.resolution, WeekResolution.advance);
  });

  test('RPE >= 8 em alguma concluida da semana sugere repetir', () {
    final p = PlanProgress(started, [
      r(1, 1, SessionStatus.done, rpe: 5),
      r(1, 2, SessionStatus.done, rpe: 8),
      r(1, 3, SessionStatus.done),
    ]);
    expect(p.resolution, WeekResolution.suggestRepeat);
  });

  test('RPE alto so numa parcial nao conta; sem RPE segue', () {
    final p = PlanProgress(started, [
      r(1, 1, SessionStatus.partial, rpe: 10),
      r(1, 1, SessionStatus.done),
      r(1, 2, SessionStatus.done, rpe: 7),
      r(1, 3, SessionStatus.done),
    ]);
    expect(p.resolution, WeekResolution.advance);
  });

  test('repetir a semana conta as 3 sessoes de novo e guarda a repeticao', () {
    final s = started.repeatWeek();
    expect(s.currentWeek, 1);
    expect(s.repeatsOf(1), 1);
    final p = PlanProgress(s, [
      r(1, 1, SessionStatus.done, rpe: 9),
      r(1, 2, SessionStatus.done),
      r(1, 3, SessionStatus.done),
    ]);
    expect(p.round, 1);
    expect(p.weekComplete, isFalse);
    expect(p.next, same(sessionAt(1, 1)));
    expect(p.markOf(1, 1), SessionMark.next);
    // A rodada nova tem o proprio RPE.
    final again = PlanProgress(s, [
      r(1, 1, SessionStatus.done, rpe: 9),
      r(1, 1, SessionStatus.done, round: 1, rpe: 6),
      r(1, 2, SessionStatus.done, round: 1),
      r(1, 3, SessionStatus.done, round: 1),
    ]);
    expect(again.weekComplete, isTrue);
    expect(again.resolution, WeekResolution.advance);
  });

  test('seguir para a semana seguinte; as anteriores ficam concluidas', () {
    final s = started.advanceWeek();
    expect(s.currentWeek, 2);
    final p = PlanProgress(s, const []);
    expect(p.next, same(sessionAt(2, 1)));
    expect(p.markOf(1, 3), SessionMark.done);
    expect(p.markOf(3, 1), SessionMark.upcoming);
  });

  test('seguir depois da semana 10 conclui o plano', () {
    final s = const PlanState(started: true, startWeek: 1, currentWeek: 10).advanceWeek();
    expect(s.finished, isTrue);
    expect(s.currentWeek, 10);
    final p = PlanProgress(s, const []);
    expect(p.next, isNull);
    expect(p.weekComplete, isFalse);
    expect(p.markOf(10, 3), SessionMark.done);
  });

  test('resultado: concluida com >= 90% do tempo planejado', () {
    expect(statusFor(movingMs: 900, plannedMs: 1000), SessionStatus.done);
    expect(statusFor(movingMs: 899, plannedMs: 1000), SessionStatus.partial);
    expect(statusFor(movingMs: 5000, plannedMs: 1000), SessionStatus.done);
  });

  test('repeticoes por semana em texto (persistencia) e de volta', () {
    final s = started.repeatWeek().repeatWeek().advanceWeek().repeatWeek();
    expect(s.repeatsOf(1), 2);
    expect(s.repeatsOf(2), 1);
    expect(PlanState.decodeRepeats(s.encodeRepeats()), s.repeats);
    expect(PlanState.decodeRepeats(null), isEmpty);
    expect(PlanState.decodeRepeats('lixo'), isEmpty);
  });
}
