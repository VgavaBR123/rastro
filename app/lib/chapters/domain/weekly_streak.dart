// Sequencia semanal com coringa (F05). Dart puro, sem relogio global: recebe
// o "agora".
//
// Regras:
// - Semana = segunda 00:00 a domingo 23:59 (hora local). Ativa com >= 1
//   atividade finalizada.
// - A sequencia conta as semanas ativas seguidas ate a ultima semana fechada;
//   a semana corrente so soma se ja tiver atividade (nunca quebra).
// - Cada mes de calendario da 1 coringa, que cobre sozinho 1 semana vazia
//   cuja segunda-feira cai nesse mes. Nao acumula. A semana coberta mantem a
//   sequencia, mas nao soma. O coringa so e gasto se ha sequencia a proteger.
// - Sem coringa, a sequencia recomeca (do zero, sem culpa).
library;

import 'chapter_activity.dart';
import 'period.dart';

enum WeekStatus {
  /// Teve atividade.
  active,

  /// Vazia, coberta pelo coringa do mes da segunda-feira.
  covered,

  /// Vazia, sem coringa: a sequencia recomecou aqui.
  broken,

  /// Vazia sem sequencia a proteger (nada a fazer).
  idle,

  /// Semana corrente ainda sem atividade (nao quebra).
  open,
}

class StreakWeek {
  final DateTime monday;
  final WeekStatus status;

  /// Sequencia ao fim desta semana.
  final int streakAfter;

  const StreakWeek(this.monday, this.status, this.streakAfter);
}

class WeeklyStreak {
  /// Da semana da primeira atividade ate a corrente.
  final List<StreakWeek> weeks;

  /// Sequencia atual.
  final int current;

  /// Maior sequencia ja feita.
  final int longest;

  const WeeklyStreak({
    required this.weeks,
    required this.current,
    required this.longest,
  });

  static const WeeklyStreak empty = WeeklyStreak(weeks: [], current: 0, longest: 0);

  /// Segundas das semanas cobertas por coringa, em ordem.
  List<DateTime> get coveredMondays => [
    for (final w in weeks)
      if (w.status == WeekStatus.covered) w.monday,
  ];

  /// A sequencia acabou de recomecar (a ultima semana fechada a quebrou) ou
  /// esta parada com historico: hora da mensagem gentil.
  bool get restarted {
    if (weeks.isEmpty) return false;
    // A ultima da lista e sempre a semana corrente; a anterior, a ultima
    // fechada.
    final closed = weeks.length - 2;
    if (closed >= 0 && weeks[closed].status == WeekStatus.broken) return true;
    return current == 0;
  }

  /// O coringa de [month] ainda nao foi usado.
  bool jokerAvailable(MonthKey month) =>
      !coveredMondays.any((m) => month.contains(m));

  /// Maior sequencia ao fim de semanas cuja segunda cai em [year].
  int longestInYear(int year) => weeks
      .where((w) => w.monday.year == year)
      .fold(0, (m, w) => w.streakAfter > m ? w.streakAfter : m);
}

/// Sequencia de [all] vista em [now].
WeeklyStreak weeklyStreak(Iterable<ChapterActivity> all, {required DateTime now}) {
  final acts = finishedInOrder(all, now: now);
  if (acts.isEmpty) return WeeklyStreak.empty;

  final activeWeeks = {for (final a in acts) mondayOf(a.start)};
  final currentMonday = mondayOf(now);
  final usedJoker = <MonthKey>{};
  final weeks = <StreakWeek>[];
  var count = 0;
  var longest = 0;

  for (var m = mondayOf(acts.first.start);
      !m.isAfter(currentMonday);
      m = nextMonday(m)) {
    final active = activeWeeks.contains(m);
    final WeekStatus status;
    if (active) {
      count++;
      status = WeekStatus.active;
    } else if (m == currentMonday) {
      status = WeekStatus.open;
    } else if (count == 0) {
      status = WeekStatus.idle;
    } else if (usedJoker.add(MonthKey.of(m))) {
      status = WeekStatus.covered;
    } else {
      count = 0;
      status = WeekStatus.broken;
    }
    if (count > longest) longest = count;
    weeks.add(StreakWeek(m, status, count));
  }
  return WeeklyStreak(weeks: weeks, current: count, longest: longest);
}
