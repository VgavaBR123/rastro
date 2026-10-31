// Plano 5 km (F06): acesso ao banco local com os tipos do dominio. Tudo fica
// no aparelho (nao sobe para o backend).
library;

import 'package:drift/drift.dart' show Value;

import '../persistence/database.dart';
import 'domain/plan_progress.dart';

class PlanRepository {
  final RecordingDatabase _db;
  PlanRepository(this._db);

  Future<PlanState> loadState() async {
    final row = await _db.plan5kState();
    if (row == null) return const PlanState();
    return PlanState(
      started: row.started,
      startWeek: row.startWeek,
      currentWeek: row.currentWeek,
      repeats: PlanState.decodeRepeats(row.repeats),
      finished: row.finished,
    );
  }

  Future<void> saveState(PlanState s) => _db.savePlan5kState(
    Plan5kStatesCompanion(
      started: Value(s.started),
      startWeek: Value(s.startWeek),
      currentWeek: Value(s.currentWeek),
      repeats: Value(s.repeats.isEmpty ? null : s.encodeRepeats()),
      finished: Value(s.finished),
    ),
  );

  /// Reinicia: volta a "nao comecado" e apaga os resultados. As atividades
  /// gravadas continuam no historico.
  Future<void> reset() => _db.clearPlan5k();

  /// Sessao guiada comecou: liga a atividade [guid] a sessao, em andamento.
  Future<int> beginSession({
    required int week,
    required int number,
    required int round,
    required int plannedMs,
    required String guid,
    required int nowMs,
  }) => _db.insertPlan5kSession(
    Plan5kSessionsCompanion.insert(
      week: week,
      number: number,
      round: Value(round),
      status: SessionStatus.inProgress.dbValue,
      plannedMs: plannedMs,
      activityGuid: Value(guid),
      startedAtMs: nowMs,
    ),
  );

  /// Guarda o tempo de plano andado (para retomar apos um crash).
  Future<void> saveProgress(String guid, {required int movingMs}) =>
      _db.updatePlan5kSessionByGuid(
        guid,
        Plan5kSessionsCompanion(movingMs: Value(movingMs)),
      );

  Future<void> finishSession(
    String guid, {
    required int movingMs,
    required SessionStatus status,
    required int nowMs,
  }) => _db.updatePlan5kSessionByGuid(
    guid,
    Plan5kSessionsCompanion(
      movingMs: Value(movingMs),
      status: Value(status.dbValue),
      endedAtMs: Value(nowMs),
    ),
  );

  /// Gravacao descartada: a sessao nao conta (nem como parcial).
  Future<void> discardSession(String guid) => _db.deletePlan5kSessionByGuid(guid);

  /// Sessao ligada a atividade [guid], ou null.
  Future<SessionResult?> sessionForGuid(String guid) async {
    final row = await _db.plan5kSessionByGuid(guid);
    return row == null ? null : _result(row, null);
  }

  Future<List<SessionResult>> results() async => [
    for (final r in await _db.plan5kSessionsWithActivity()) _result(r.row, r.activity),
  ];

  /// Fecha as sessoes que ficaram "em andamento" sem gravacao aberta: app
  /// morto e a recuperacao escolheu "Salvar e encerrar" (vira concluida ou
  /// parcial pelo tempo) ou "Descartar" (a atividade sumiu: a sessao some
  /// tambem, como no descarte normal). A gravacao [activeGuid] e as
  /// interrompidas ainda nao finalizadas (recuperaveis) ficam como estao.
  Future<void> reconcile({required String? activeGuid, required int nowMs}) async {
    for (final r in await _db.plan5kSessionsWithActivity()) {
      final row = r.row;
      final guid = row.activityGuid;
      if (guid == null || guid == activeGuid) continue;
      if (row.status != SessionStatus.inProgress.dbValue) continue;
      final a = r.activity;
      if (a == null) {
        await discardSession(guid);
        continue;
      }
      if (!a.isFinished) continue;
      final moving = a.timerTimeMs > row.movingMs ? a.timerTimeMs : row.movingMs;
      await finishSession(
        guid,
        movingMs: moving,
        status: statusFor(movingMs: moving, plannedMs: row.plannedMs),
        nowMs: nowMs,
      );
    }
  }

  static SessionResult _result(Plan5kSessionRow r, Activity? a) => SessionResult(
    week: r.week,
    number: r.number,
    round: r.round,
    status: SessionStatus.fromDb(r.status),
    plannedMs: r.plannedMs,
    movingMs: r.movingMs,
    rpe: a?.rpe,
    activityGuid: r.activityGuid,
  );
}
