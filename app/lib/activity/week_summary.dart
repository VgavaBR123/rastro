// Resumo da semana do Inicio (relatorio 11, WeekSummaryCard): totais de
// distancia, tempo e subida e a carga de cada dia. A conta e pura (testavel);
// o provider so junta as atividades da semana e o ganho de elevacao de cada.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../persistence/database.dart';
import '../recording/domain/recording_models.dart';
import 'elevation_profile.dart';

/// Uma atividade como o resumo enxerga.
class WeekEntry {
  final ActivityType type;
  final int startTimestampMs;
  final double distanceMeters;
  final int timerTimeMs;

  /// Ganho de elevacao (m); null quando nao ha altitude.
  final double? elevationGainMeters;

  const WeekEntry({
    required this.type,
    required this.startTimestampMs,
    required this.distanceMeters,
    required this.timerTimeMs,
    this.elevationGainMeters,
  });

  factory WeekEntry.fromActivity(Activity a, {double? elevationGainMeters}) => WeekEntry(
        type: a.activityType,
        startTimestampMs: a.startTimestampMs,
        distanceMeters: a.distanceMeters,
        timerTimeMs: a.timerTimeMs,
        elevationGainMeters: elevationGainMeters,
      );
}

/// Um dia da semana (0 = segunda ... 6 = domingo).
class DayTotal {
  final int index;
  final double distanceMeters;
  final int timerTimeMs;

  /// Esporte com mais tempo no dia; null sem treino.
  final ActivityType? mainType;

  const DayTotal({
    required this.index,
    this.distanceMeters = 0,
    this.timerTimeMs = 0,
    this.mainType,
  });

  bool get isEmpty => mainType == null;
}

class WeekSummary {
  /// Segunda-feira 00:00 (hora local) da semana.
  final DateTime start;
  final double distanceMeters;
  final int timerTimeMs;
  final double elevationGainMeters;

  /// Esporte de cada treino, em ordem cronologica.
  final List<ActivityType> workouts;

  /// Sempre 7 dias, de segunda a domingo.
  final List<DayTotal> days;

  const WeekSummary({
    required this.start,
    required this.distanceMeters,
    required this.timerTimeMs,
    required this.elevationGainMeters,
    required this.workouts,
    required this.days,
  });

  int get count => workouts.length;

  /// Maior tempo de um dia (escala das barras).
  int get maxDayTimerMs =>
      days.fold(0, (m, d) => d.timerTimeMs > m ? d.timerTimeMs : m);
}

/// Segunda-feira 00:00 da semana de [now], na hora local.
DateTime startOfWeek(DateTime now) {
  final day = DateTime(now.year, now.month, now.day);
  return DateTime(day.year, day.month, day.day - (day.weekday - DateTime.monday));
}

/// Soma as atividades que comecaram na semana de [now]; as demais ficam de fora.
WeekSummary buildWeekSummary(List<WeekEntry> entries, {required DateTime now}) {
  final start = startOfWeek(now);
  final end = DateTime(start.year, start.month, start.day + 7);
  final inWeek = [
    for (final e in entries)
      if (!DateTime.fromMillisecondsSinceEpoch(e.startTimestampMs).isBefore(start) &&
          DateTime.fromMillisecondsSinceEpoch(e.startTimestampMs).isBefore(end))
        e,
  ]..sort((a, b) => a.startTimestampMs.compareTo(b.startTimestampMs));

  final dist = List<double>.filled(7, 0);
  final time = List<int>.filled(7, 0);
  // Tempo por esporte em cada dia, para escolher a cor da barra.
  final byType = List.generate(7, (_) => <ActivityType, int>{});
  var gain = 0.0;
  for (final e in inWeek) {
    final i = DateTime.fromMillisecondsSinceEpoch(e.startTimestampMs).weekday - 1;
    dist[i] += e.distanceMeters;
    time[i] += e.timerTimeMs;
    byType[i][e.type] = (byType[i][e.type] ?? 0) + e.timerTimeMs;
    gain += e.elevationGainMeters ?? 0;
  }

  ActivityType? main(Map<ActivityType, int> m) {
    ActivityType? best;
    var bestMs = -1;
    for (final t in ActivityType.values) {
      final ms = m[t];
      if (ms != null && ms > bestMs) {
        best = t;
        bestMs = ms;
      }
    }
    return best;
  }

  return WeekSummary(
    start: start,
    distanceMeters: dist.fold(0.0, (a, b) => a + b),
    timerTimeMs: time.fold(0, (a, b) => a + b),
    elevationGainMeters: gain,
    workouts: [for (final e in inWeek) e.type],
    days: [
      for (var i = 0; i < 7; i++)
        DayTotal(index: i, distanceMeters: dist[i], timerTimeMs: time[i], mainType: main(byType[i])),
    ],
  );
}

/// Relogio do resumo (sobrescrito nos testes).
final weekClockProvider = Provider<DateTime Function()>((_) => DateTime.now);

/// Resumo da semana atual. Recalcula quando a lista de recentes e invalidada.
final weekSummaryProvider = FutureProvider.autoDispose<WeekSummary>((ref) async {
  final now = ref.watch(weekClockProvider)();
  final list = await ref.watch(recentActivitiesProvider.future);
  final repo = ref.watch(recordingRepositoryProvider);
  final startMs = startOfWeek(now).millisecondsSinceEpoch;
  final entries = <WeekEntry>[];
  for (final a in list) {
    if (a.startTimestampMs < startMs) continue;
    final profile = buildElevationProfile(await repo.waypoints(a.guid));
    entries.add(WeekEntry.fromActivity(a, elevationGainMeters: profile?.gainMeters));
  }
  return buildWeekSummary(entries, now: now);
});
