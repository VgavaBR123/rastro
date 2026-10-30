// Progresso do plano 5 km (F06). Dart puro: estado do plano (semana atual,
// repeticoes) + resultados das sessoes -> proxima sessao, marcas para a tela
// e a regra "pesada demais repete a semana".
//
// - Sessao concluida: o tempo em movimento cobriu >= 90% do planejado.
//   Parcial nao avanca: a proxima continua sendo a mesma.
// - Semana completa (3 concluidas na rodada atual): se alguma concluida dessa
//   rodada teve RPE >= 8, sugere repetir; sem RPE informado, segue.
// - Repetir abre uma rodada nova da mesma semana (as 3 sessoes de novo) e soma
//   uma repeticao; seguir vai para a semana seguinte (depois da 10, conclui).
library;

import 'dart:convert';

import 'plan_table.dart';

enum SessionStatus {
  inProgress,
  done,
  partial;

  String get dbValue => name;
  static SessionStatus fromDb(String v) =>
      SessionStatus.values.firstWhere((s) => s.name == v, orElse: () => partial);
}

/// Fracao do tempo planejado que conta como sessao concluida.
const double kDoneFraction = 0.9;

/// RPE a partir do qual a semana e "pesada demais".
const int kHeavyRpe = 8;

SessionStatus statusFor({required int movingMs, required int plannedMs}) =>
    movingMs >= plannedMs * kDoneFraction ? SessionStatus.done : SessionStatus.partial;

class SessionResult {
  final int week;
  final int number;

  /// Rodada da semana: 0 na primeira vez, 1 na primeira repeticao...
  final int round;
  final SessionStatus status;
  final int plannedMs;
  final int movingMs;

  /// Esforco (F04) da atividade ligada; null sem RPE ou atividade apagada.
  final int? rpe;
  final String? activityGuid;

  const SessionResult({
    required this.week,
    required this.number,
    required this.round,
    required this.status,
    required this.plannedMs,
    required this.movingMs,
    this.rpe,
    this.activityGuid,
  });
}

class PlanState {
  final bool started;
  final int startWeek;
  final int currentWeek;

  /// Semana -> quantas vezes foi repetida.
  final Map<int, int> repeats;
  final bool finished;

  const PlanState({
    this.started = false,
    this.startWeek = 1,
    this.currentWeek = 1,
    this.repeats = const {},
    this.finished = false,
  });

  int repeatsOf(int week) => repeats[week] ?? 0;

  /// Rodada atual da semana atual.
  int get round => repeatsOf(currentWeek);

  PlanState _copy({int? currentWeek, Map<int, int>? repeats, bool? finished}) => PlanState(
    started: started,
    startWeek: startWeek,
    currentWeek: currentWeek ?? this.currentWeek,
    repeats: repeats ?? this.repeats,
    finished: finished ?? this.finished,
  );

  PlanState repeatWeek() => _copy(
    repeats: {...repeats, currentWeek: repeatsOf(currentWeek) + 1},
  );

  PlanState advanceWeek() => currentWeek >= kPlanWeeks
      ? _copy(finished: true)
      : _copy(currentWeek: currentWeek + 1);

  /// JSON {"semana": repeticoes} para o banco.
  String encodeRepeats() =>
      jsonEncode({for (final e in repeats.entries) '${e.key}': e.value});

  static Map<int, int> decodeRepeats(String? raw) {
    if (raw == null || raw.isEmpty) return const {};
    try {
      final m = jsonDecode(raw);
      if (m is! Map) return const {};
      return {
        for (final e in m.entries)
          if (int.tryParse('${e.key}') != null && e.value is int)
            int.parse('${e.key}'): e.value as int,
      };
    } catch (_) {
      return const {};
    }
  }
}

enum SessionMark { done, partial, next, upcoming, skipped }

enum WeekResolution { advance, suggestRepeat }

class PlanProgress {
  final PlanState state;
  final List<SessionResult> results;

  const PlanProgress(this.state, this.results);

  int get round => state.round;

  Iterable<SessionResult> _currentRound() => results.where(
    (r) => r.week == state.currentWeek && r.round == round,
  );

  Set<int> get _doneNumbers => {
    for (final r in _currentRound())
      if (r.status == SessionStatus.done) r.number,
  };

  bool get weekComplete =>
      state.started && !state.finished && _doneNumbers.length >= kSessionsPerWeek;

  /// Proxima sessao a fazer; null sem plano, plano concluido ou semana
  /// completa esperando a decisao.
  PlanSession? get next {
    if (!state.started || state.finished || weekComplete) return null;
    final done = _doneNumbers;
    for (var n = 1; n <= kSessionsPerWeek; n++) {
      if (!done.contains(n)) return sessionAt(state.currentWeek, n);
    }
    return null;
  }

  /// Decisao do fim da semana (so faz sentido com [weekComplete]).
  WeekResolution get resolution {
    final heavy = _currentRound().any(
      (r) => r.status == SessionStatus.done && (r.rpe ?? 0) >= kHeavyRpe,
    );
    return heavy ? WeekResolution.suggestRepeat : WeekResolution.advance;
  }

  SessionMark markOf(int week, int number) {
    if (!state.started) return SessionMark.upcoming;
    if (week < state.startWeek) return SessionMark.skipped;
    if (week < state.currentWeek || state.finished) return SessionMark.done;
    if (week > state.currentWeek) return SessionMark.upcoming;
    final mine = _currentRound().where((r) => r.number == number);
    if (mine.any((r) => r.status == SessionStatus.done)) return SessionMark.done;
    if (next?.number == number) {
      return mine.any((r) => r.status == SessionStatus.partial)
          ? SessionMark.partial
          : SessionMark.next;
    }
    if (mine.any((r) => r.status == SessionStatus.partial)) return SessionMark.partial;
    return SessionMark.upcoming;
  }
}
