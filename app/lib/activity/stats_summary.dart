// Estatisticas (aba Estatisticas e totais do perfil): totais por periodo,
// evolucao de 8 semanas empilhada por esporte, distribuicao por esporte e
// recordes pessoais. As contas sao puras (testaveis); o provider so le os
// cabecalhos do banco e o ganho de elevacao das atividades da janela.
library;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../closing/domain/effort.dart';
import '../persistence/database.dart';
import '../recording/domain/recording_models.dart';
import 'elevation_profile.dart';
import 'week_summary.dart' show startOfWeek;

/// Semanas do grafico (a atual e as 7 anteriores).
const int kStatsWeeks = 8;

/// Distancia minima para uma corrida valer para o recorde de pace.
const double kPaceRecordMinMeters = 1000;

/// Uma atividade como as estatisticas enxergam.
class StatEntry {
  final String guid;
  final ActivityType type;
  final int startTimestampMs;
  final double distanceMeters;
  final int timerTimeMs;

  /// Ganho de elevacao (m); null quando nao foi calculado ou nao ha altitude.
  final double? elevationGainMeters;

  /// Esforco percebido (F04); null = nao informado (fica fora da carga).
  final int? rpe;

  const StatEntry({
    this.guid = '',
    required this.type,
    required this.startTimestampMs,
    required this.distanceMeters,
    required this.timerTimeMs,
    this.elevationGainMeters,
    this.rpe,
  });

  /// Carga do treino (sRPE); null sem RPE.
  int? get load => trainingLoad(rpe: rpe, timerMs: timerTimeMs);

  factory StatEntry.fromActivity(Activity a, {double? elevationGainMeters}) =>
      StatEntry(
        guid: a.guid,
        type: a.activityType,
        startTimestampMs: a.startTimestampMs,
        distanceMeters: a.distanceMeters,
        timerTimeMs: a.timerTimeMs,
        elevationGainMeters: elevationGainMeters,
        rpe: a.rpe,
      );
}

/// Soma de um conjunto de atividades.
class StatTotals {
  final int count;
  final double distanceMeters;
  final int timerTimeMs;
  final double elevationGainMeters;

  const StatTotals({
    this.count = 0,
    this.distanceMeters = 0,
    this.timerTimeMs = 0,
    this.elevationGainMeters = 0,
  });

  bool get isEmpty => count == 0;

  StatTotals operator +(StatEntry e) => StatTotals(
    count: count + 1,
    distanceMeters: distanceMeters + _finite(e.distanceMeters),
    timerTimeMs: timerTimeMs + (e.timerTimeMs > 0 ? e.timerTimeMs : 0),
    elevationGainMeters:
        elevationGainMeters + _finite(e.elevationGainMeters ?? 0),
  );

  static StatTotals of(Iterable<StatEntry> entries) =>
      entries.fold(const StatTotals(), (t, e) => t + e);
}

double _finite(double v) => v.isFinite && v > 0 ? v : 0;

/// Uma semana do grafico, com o tempo de cada esporte.
class WeekBar {
  /// Segunda-feira 00:00 (hora local).
  final DateTime start;
  final Map<ActivityType, int> timerMsBySport;

  /// Carga do treino da semana (soma do sRPE, F04).
  final int load;

  /// Treinos da semana com esforco informado (os que entram na carga).
  final int ratedCount;

  const WeekBar({
    required this.start,
    required this.timerMsBySport,
    this.load = 0,
    this.ratedCount = 0,
  });

  int get totalTimerMs => timerMsBySport.values.fold(0, (a, b) => a + b);
}

/// Fatia de um esporte num periodo.
class SportShare {
  final ActivityType type;
  final StatTotals totals;

  /// Fracao do tempo total do periodo (0 a 1).
  final double fraction;

  const SportShare({
    required this.type,
    required this.totals,
    required this.fraction,
  });
}

/// Janela de tempo das estatisticas.
enum StatsPeriod {
  week(1),
  month(4),
  eightWeeks(kStatsWeeks);

  /// Semanas incluidas, contando a atual.
  final int weeks;
  const StatsPeriod(this.weeks);
}

class StatsSummary {
  /// Sempre [kStatsWeeks] semanas, da mais antiga para a atual.
  final List<WeekBar> weeks;
  final List<StatEntry> entries;
  final DateTime now;

  const StatsSummary({
    required this.weeks,
    required this.entries,
    required this.now,
  });

  /// Inicio do periodo (segunda-feira 00:00 da semana mais antiga dele).
  DateTime periodStart(StatsPeriod p) {
    final w = startOfWeek(now);
    return DateTime(w.year, w.month, w.day - 7 * (p.weeks - 1));
  }

  List<StatEntry> inPeriod(StatsPeriod p) {
    final startMs = periodStart(p).millisecondsSinceEpoch;
    return [
      for (final e in entries)
        if (e.startTimestampMs >= startMs) e,
    ];
  }

  StatTotals totals(StatsPeriod p) => StatTotals.of(inPeriod(p));

  /// Esportes com treino no periodo, do maior tempo para o menor.
  List<SportShare> distribution(StatsPeriod p) =>
      sportDistribution(inPeriod(p));

  /// Maior tempo de uma semana (escala das barras).
  int get maxWeekTimerMs =>
      weeks.fold(0, (m, w) => w.totalTimerMs > m ? w.totalTimerMs : m);

  /// Maior carga de uma semana (escala das barras de carga, F04).
  int get maxWeekLoad => weeks.fold(0, (m, w) => w.load > m ? w.load : m);

  /// Algum treino da janela tem esforco informado.
  bool get hasLoad => weeks.any((w) => w.ratedCount > 0);

  /// Soma do sRPE no periodo.
  int loadTotal(StatsPeriod p) =>
      inPeriod(p).fold(0, (sum, e) => sum + (e.load ?? 0));
}

/// Monta o resumo das [kStatsWeeks] semanas ate a de [now]. Atividades fora
/// da janela (antes dela ou no futuro) ficam de fora.
StatsSummary buildStatsSummary(List<StatEntry> all, {required DateTime now}) {
  final current = startOfWeek(now);
  final starts = [
    for (var i = kStatsWeeks - 1; i >= 0; i--)
      DateTime(current.year, current.month, current.day - 7 * i),
  ];
  final windowStart = starts.first.millisecondsSinceEpoch;
  final windowEnd = DateTime(
    current.year,
    current.month,
    current.day + 7,
  ).millisecondsSinceEpoch;
  final inWindow = [
    for (final e in all)
      if (e.startTimestampMs >= windowStart && e.startTimestampMs < windowEnd)
        e,
  ]..sort((a, b) => a.startTimestampMs.compareTo(b.startTimestampMs));

  final bySport = List.generate(kStatsWeeks, (_) => <ActivityType, int>{});
  final load = List<int>.filled(kStatsWeeks, 0);
  final rated = List<int>.filled(kStatsWeeks, 0);
  for (final e in inWindow) {
    // Indice pela ultima semana que comecou antes da atividade (mudanca de
    // horario de verao nao desloca: comparamos datas, nao 7 x 24 h).
    var i = kStatsWeeks - 1;
    while (i > 0 && e.startTimestampMs < starts[i].millisecondsSinceEpoch) {
      i--;
    }
    final ms = e.timerTimeMs > 0 ? e.timerTimeMs : 0;
    bySport[i][e.type] = (bySport[i][e.type] ?? 0) + ms;
    final l = e.load;
    if (l != null) {
      load[i] += l;
      rated[i]++;
    }
  }

  return StatsSummary(
    weeks: [
      for (var i = 0; i < kStatsWeeks; i++)
        WeekBar(
          start: starts[i],
          timerMsBySport: Map.unmodifiable(bySport[i]),
          load: load[i],
          ratedCount: rated[i],
        ),
    ],
    entries: List.unmodifiable(inWindow),
    now: now,
  );
}

/// Totais por esporte, do maior tempo para o menor (empate: ordem do enum).
List<SportShare> sportDistribution(List<StatEntry> entries) {
  final totals = <ActivityType, StatTotals>{};
  for (final e in entries) {
    totals[e.type] = (totals[e.type] ?? const StatTotals()) + e;
  }
  final allMs = totals.values.fold(0, (a, t) => a + t.timerTimeMs);
  final allCount = entries.length;
  final shares = [
    for (final t in ActivityType.values)
      if (totals[t] != null)
        SportShare(
          type: t,
          totals: totals[t]!,
          // Sem tempo registrado, a fatia sai pela contagem de treinos.
          fraction: allMs > 0
              ? totals[t]!.timerTimeMs / allMs
              : totals[t]!.count / allCount,
        ),
  ];
  shares.sort((a, b) {
    final c = b.totals.timerTimeMs.compareTo(a.totals.timerTimeMs);
    return c != 0 ? c : a.type.index.compareTo(b.type.index);
  });
  return shares;
}

enum RecordKind {
  /// Maior distancia numa atividade do esporte.
  longestDistance,

  /// Melhor pace medio numa corrida de pelo menos [kPaceRecordMinMeters].
  bestPace,

  /// Maior tempo em movimento numa atividade do esporte.
  longestTime,
}

class PersonalRecord {
  final ActivityType type;
  final RecordKind kind;

  /// Metros (distancia), segundos por metro (pace) ou ms (tempo).
  final double value;
  final StatEntry entry;

  const PersonalRecord({
    required this.type,
    required this.kind,
    required this.value,
    required this.entry,
  });
}

/// Recordes calculaveis so com os cabecalhos locais: a maior distancia de cada
/// esporte, o melhor pace medio da corrida e o maior tempo do pedal. Esportes
/// sem treino ficam de fora. Recordes por trecho (melhor 5 km dentro de uma
/// corrida) exigiriam varrer os pontos de todas as atividades e ficam para depois.
List<PersonalRecord> personalRecords(List<StatEntry> entries) {
  final out = <PersonalRecord>[];
  for (final type in ActivityType.values) {
    final mine = [
      for (final e in entries)
        if (e.type == type && _finite(e.distanceMeters) > 0) e,
    ];
    if (mine.isEmpty) continue;
    final longest = mine.reduce(
      (a, b) => b.distanceMeters > a.distanceMeters ? b : a,
    );
    out.add(
      PersonalRecord(
        type: type,
        kind: RecordKind.longestDistance,
        value: longest.distanceMeters,
        entry: longest,
      ),
    );
    if (type == ActivityType.run) {
      final paced = [
        for (final e in mine)
          if (e.distanceMeters >= kPaceRecordMinMeters && e.timerTimeMs > 0) e,
      ];
      if (paced.isNotEmpty) {
        double pace(StatEntry e) => e.timerTimeMs / 1000 / e.distanceMeters;
        final best = paced.reduce((a, b) => pace(b) < pace(a) ? b : a);
        out.add(
          PersonalRecord(
            type: type,
            kind: RecordKind.bestPace,
            value: pace(best),
            entry: best,
          ),
        );
      }
    } else if (type == ActivityType.ride) {
      final timed = [
        for (final e in mine)
          if (e.timerTimeMs > 0) e,
      ];
      if (timed.isNotEmpty) {
        final best = timed.reduce(
          (a, b) => b.timerTimeMs > a.timerTimeMs ? b : a,
        );
        out.add(
          PersonalRecord(
            type: type,
            kind: RecordKind.longestTime,
            value: best.timerTimeMs.toDouble(),
            entry: best,
          ),
        );
      }
    }
  }
  return out;
}

/// Tudo o que as telas Estatisticas e Voce precisam.
class StatsData {
  final StatsSummary summary;
  final List<PersonalRecord> records;
  const StatsData({required this.summary, required this.records});
}

/// Relogio das estatisticas (sobrescrito nos testes).
final statsClockProvider = Provider<DateTime Function()>((_) => DateTime.now);

/// Estatisticas de todas as atividades finalizadas do aparelho (as mesmas do
/// historico). Recalcula quando a lista de recentes e invalidada (salvar,
/// apagar, recuperar). O ganho de elevacao so e calculado dentro da janela de
/// [kStatsWeeks] semanas, que e onde ele aparece.
final statsProvider = FutureProvider.autoDispose<StatsData>((ref) async {
  await ref.watch(recentActivitiesProvider.future);
  final now = ref.watch(statsClockProvider)();
  final db = ref.watch(recordingDatabaseProvider);
  final repo = ref.watch(recordingRepositoryProvider);
  final rows =
      await (db.select(db.activities)
            ..where((t) => t.isFinished.equals(true))
            ..orderBy([(t) => OrderingTerm.desc(t.startTimestampMs)]))
          .get();

  final current = startOfWeek(now);
  final windowStartMs = DateTime(
    current.year,
    current.month,
    current.day - 7 * (kStatsWeeks - 1),
  ).millisecondsSinceEpoch;
  final entries = <StatEntry>[];
  for (final a in rows) {
    double? gain;
    if (a.startTimestampMs >= windowStartMs) {
      gain = buildElevationProfile(await repo.waypoints(a.guid))?.gainMeters;
    }
    entries.add(StatEntry.fromActivity(a, elevationGainMeters: gain));
  }
  return StatsData(
    summary: buildStatsSummary(entries, now: now),
    records: personalRecords(entries),
  );
});
