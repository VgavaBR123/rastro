// Plano 5 km (F06): casos de uso sobre o repositorio (comecar, reiniciar,
// progresso, decisao do fim da semana).
library;

import 'domain/plan_progress.dart';
import 'domain/plan_table.dart';
import 'plan_repository.dart';

class PlanService {
  final PlanRepository _repo;
  final List<PlanSession> table;
  final int Function() _now;

  PlanService(this._repo, {required this.table, int Function()? now})
    : _now = now ?? (() => DateTime.now().millisecondsSinceEpoch);

  /// Progresso atual. Antes fecha as sessoes que ficaram em andamento sem
  /// gravacao aberta (ex.: recuperacao com "Salvar e encerrar").
  Future<PlanProgress> progress({String? activeGuid}) async {
    await _repo.reconcile(activeGuid: activeGuid, nowMs: _now());
    return PlanProgress(await _repo.loadState(), await _repo.results(), table: table);
  }

  /// Comeca o plano na semana [startWeek] (1..10).
  Future<void> startPlan(int startWeek) {
    final w = startWeek.clamp(1, kPlanWeeks);
    return _repo.saveState(PlanState(started: true, startWeek: w, currentWeek: w));
  }

  /// Volta a "nao comecado" (as atividades continuam no historico).
  Future<void> reset() => _repo.reset();

  /// Fim de semana: sem RPE alto, segue sozinho e devolve
  /// [WeekResolution.advance]; com RPE alto devolve
  /// [WeekResolution.suggestRepeat] e espera a escolha ([repeatWeek] ou
  /// [advanceWeek]). Null = a semana ainda nao terminou.
  Future<WeekResolution?> resolveWeek({String? activeGuid}) async {
    final p = await progress(activeGuid: activeGuid);
    if (!p.weekComplete) return null;
    final r = p.resolution;
    if (r == WeekResolution.advance) await _repo.saveState(p.state.advanceWeek());
    return r;
  }

  Future<void> repeatWeek() async {
    final p = await progress();
    if (!p.weekComplete) return;
    await _repo.saveState(p.state.repeatWeek());
  }

  Future<void> advanceWeek() async {
    final p = await progress();
    if (!p.weekComplete) return;
    await _repo.saveState(p.state.advanceWeek());
  }
}
