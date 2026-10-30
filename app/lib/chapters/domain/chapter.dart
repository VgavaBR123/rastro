// Capitulos mensais e anuais (F05): o conteudo do capitulo, calculado no
// aparelho a partir das atividades finalizadas. Dart puro, sem relogio global
// (recebe o "agora"). So numeros agregados e marcos: nada de titulo, trajeto
// ou horario (ver ChapterActivity).
library;

import '../../recording/domain/recording_models.dart';
import 'chapter_activity.dart';
import 'milestones.dart';
import 'period.dart';
import 'weekly_streak.dart';

/// Totais de um periodo.
class ChapterTotals {
  final int count;
  final double distanceMeters;

  /// Tempo em movimento (ms).
  final int timerMs;

  /// Dias de calendario com pelo menos um treino.
  final int activeDays;

  const ChapterTotals({
    this.count = 0,
    this.distanceMeters = 0,
    this.timerMs = 0,
    this.activeDays = 0,
  });

  bool get isEmpty => count == 0;

  static ChapterTotals of(List<ChapterActivity> acts) {
    final days = {
      for (final a in acts) DateTime(a.start.year, a.start.month, a.start.day),
    };
    return ChapterTotals(
      count: acts.length,
      distanceMeters: acts.fold(0.0, (s, a) => s + a.safeMeters),
      timerMs: acts.fold(0, (s, a) => s + a.safeTimerMs),
      activeDays: days.length,
    );
  }
}

/// Totais de um esporte.
class SportTotals {
  final ActivityType type;
  final int count;
  final double distanceMeters;
  final int timerMs;

  const SportTotals({
    required this.type,
    required this.count,
    required this.distanceMeters,
    required this.timerMs,
  });
}

/// A atividade mais longa, so com o que pode aparecer: esporte, distancia e
/// tempo (sem titulo, mapa nem horario).
class LongestEffort {
  final ActivityType type;
  final double distanceMeters;
  final int timerMs;

  const LongestEffort({
    required this.type,
    required this.distanceMeters,
    required this.timerMs,
  });
}

class MonthChapter {
  final MonthKey month;
  final ChapterTotals totals;

  /// Do maior tempo para o menor.
  final List<SportTotals> sports;
  final LongestEffort? longest;

  /// Pace medio das corridas do mes (s/m); null sem corrida com distancia.
  /// Nao aparece no Modo Gentil.
  final double? runPaceSecondsPerMeter;

  /// Marcos atingidos pela primeira vez neste mes.
  final List<Milestone> milestones;

  /// Sequencia vista no fim do mes.
  final WeeklyStreak streak;

  /// Semanas cobertas por coringa cuja segunda-feira cai neste mes.
  final List<DateTime> jokersUsed;

  const MonthChapter({
    required this.month,
    required this.totals,
    required this.sports,
    required this.longest,
    required this.runPaceSecondsPerMeter,
    required this.milestones,
    required this.streak,
    required this.jokersUsed,
  });

  bool get isEmpty => totals.isEmpty;
}

class YearChapter {
  final int year;
  final ChapterTotals totals;
  final List<SportTotals> sports;

  /// Mes com mais tempo em movimento (empate: mais treinos, depois o
  /// primeiro); null em ano vazio.
  final MonthKey? bestMonth;
  final ChapterTotals? bestMonthTotals;
  final List<Milestone> milestones;

  /// Maior sequencia em semanas que comecam no ano.
  final int longestStreak;

  /// Sequencia vista no fim do ano (ou agora, no ano corrente).
  final WeeklyStreak streak;

  /// Ano corrente, aberto "ate agora".
  final bool partial;

  const YearChapter({
    required this.year,
    required this.totals,
    required this.sports,
    required this.bestMonth,
    required this.bestMonthTotals,
    required this.milestones,
    required this.longestStreak,
    required this.streak,
    required this.partial,
  });

  bool get isEmpty => totals.isEmpty;
}

List<SportTotals> _sports(List<ChapterActivity> acts) {
  final out = <SportTotals>[];
  for (final t in ActivityType.values) {
    final mine = [
      for (final a in acts)
        if (a.type == t) a,
    ];
    if (mine.isEmpty) continue;
    out.add(SportTotals(
      type: t,
      count: mine.length,
      distanceMeters: mine.fold(0.0, (s, a) => s + a.safeMeters),
      timerMs: mine.fold(0, (s, a) => s + a.safeTimerMs),
    ));
  }
  // Estavel: empate de tempo fica na ordem do enum.
  final order = {for (var i = 0; i < out.length; i++) out[i].type: i};
  out.sort((a, b) {
    final c = b.timerMs.compareTo(a.timerMs);
    return c != 0 ? c : order[a.type]!.compareTo(order[b.type]!);
  });
  return out;
}

LongestEffort? _longest(List<ChapterActivity> acts) {
  if (acts.isEmpty) return null;
  final best = acts.reduce((a, b) {
    if (b.safeMeters != a.safeMeters) return b.safeMeters > a.safeMeters ? b : a;
    return b.safeTimerMs > a.safeTimerMs ? b : a;
  });
  return LongestEffort(
    type: best.type,
    distanceMeters: best.safeMeters,
    timerMs: best.safeTimerMs,
  );
}

double? _runPace(List<ChapterActivity> acts) {
  var m = 0.0;
  var ms = 0;
  for (final a in acts) {
    if (a.type != ActivityType.run || a.safeMeters <= 0 || a.safeTimerMs <= 0) {
      continue;
    }
    m += a.safeMeters;
    ms += a.safeTimerMs;
  }
  return m > 0 ? ms / 1000 / m : null;
}

/// Ultimo instante antes de [end] (o fim exclusivo de um periodo).
DateTime _lastMoment(DateTime end) => end.subtract(const Duration(milliseconds: 1));

DateTime _min(DateTime a, DateTime b) => a.isBefore(b) ? a : b;

/// Capitulo de [month] visto em [now].
MonthChapter buildMonthChapter(
  Iterable<ChapterActivity> all,
  MonthKey month, {
  required DateTime now,
}) {
  final history = finishedInOrder(all, now: now);
  final inMonth = [
    for (final a in history)
      if (month.contains(a.start)) a,
  ];
  final cutoff = _min(now, _lastMoment(month.end));
  return MonthChapter(
    month: month,
    totals: ChapterTotals.of(inMonth),
    sports: _sports(inMonth),
    longest: _longest(inMonth),
    runPaceSecondsPerMeter: _runPace(inMonth),
    milestones: [
      for (final m in firstTimeMilestones(history))
        if (month.contains(m.achievedAt)) m,
    ],
    streak: weeklyStreak(history, now: cutoff),
    // Os coringas vem da linha do tempo ate agora: a semana que comeca no fim
    // do mes so fecha depois dele.
    jokersUsed: [
      for (final m in weeklyStreak(history, now: now).coveredMondays)
        if (month.contains(m)) m,
    ],
  );
}

/// Capitulo do ano [year] visto em [now]. O ano corrente sai "ate agora".
YearChapter buildYearChapter(
  Iterable<ChapterActivity> all,
  int year, {
  required DateTime now,
}) {
  final history = finishedInOrder(all, now: now);
  final inYear = [
    for (final a in history)
      if (a.start.year == year) a,
  ];
  MonthKey? best;
  ChapterTotals? bestTotals;
  for (var m = 1; m <= 12; m++) {
    final key = MonthKey(year, m);
    final t = ChapterTotals.of([
      for (final a in inYear)
        if (key.contains(a.start)) a,
    ]);
    if (t.isEmpty) continue;
    final better = bestTotals == null ||
        t.timerMs > bestTotals.timerMs ||
        (t.timerMs == bestTotals.timerMs && t.count > bestTotals.count);
    if (better) {
      best = key;
      bestTotals = t;
    }
  }
  final streak = weeklyStreak(
    history,
    now: _min(now, _lastMoment(DateTime(year + 1))),
  );
  return YearChapter(
    year: year,
    totals: ChapterTotals.of(inYear),
    sports: _sports(inYear),
    bestMonth: best,
    bestMonthTotals: bestTotals,
    milestones: [
      for (final m in firstTimeMilestones(history))
        if (m.achievedAt.year == year) m,
    ],
    longestStreak: streak.longestInYear(year),
    streak: streak,
    partial: now.year == year,
  );
}

/// Meses fechados (anteriores ao de [now]) com pelo menos uma atividade
/// finalizada, do mais recente para o mais antigo.
List<MonthKey> chapterMonths(Iterable<ChapterActivity> all, {required DateTime now}) {
  final current = MonthKey.of(now);
  final set = <MonthKey>{
    for (final a in all)
      if (a.finished && MonthKey.of(a.start).compareTo(current) < 0)
        MonthKey.of(a.start),
  };
  return set.toList()..sort((a, b) => b.compareTo(a));
}

/// Anos com atividade finalizada e sempre o corrente ("ate agora"), do mais
/// recente para o mais antigo. O ano anterior aparece desde 1 de janeiro.
List<int> chapterYears(Iterable<ChapterActivity> all, {required DateTime now}) {
  final set = <int>{
    now.year,
    for (final a in all)
      if (a.finished && a.start.year <= now.year) a.start.year,
  };
  return set.toList()..sort((a, b) => b.compareTo(a));
}

/// Mes cujo capitulo o cartao do Inicio oferece em [now]: o mes anterior, a
/// partir do dia 1, ate a pessoa abrir ou dispensar ([seenCode], `yyyymm` do
/// ultimo mes visto ou dispensado). Null quando ja foi visto ou quando nao
/// ha nenhuma atividade antes deste mes (app novo).
MonthKey? pendingHomeChapter(
  Iterable<ChapterActivity> all, {
  required DateTime now,
  int? seenCode,
}) {
  final month = MonthKey.of(now).previous;
  if (seenCode != null && seenCode >= month.code) return null;
  final start = MonthKey.of(now).start;
  final hasHistory = all.any((a) => a.finished && a.start.isBefore(start));
  return hasHistory ? month : null;
}
