// Marcos de primeira vez (F05). Varre o historico inteiro do aparelho em
// ordem de inicio e registra o instante em que cada marco foi atingido pela
// primeira vez; o capitulo de um mes mostra os que cairam nele. Dart puro.
library;

import '../../recording/domain/recording_models.dart';
import 'chapter_activity.dart';
import 'period.dart';

enum MilestoneKind {
  /// Primeira atividade de um esporte.
  firstActivity,

  /// Primeira atividade de um esporte com pelo menos X metros.
  distance,

  /// Primeira atividade (qualquer esporte) com pelo menos X de tempo em
  /// movimento.
  duration,

  /// Primeira semana (segunda a domingo) com 3 treinos.
  threeWorkoutWeek,

  /// Distancia acumulada na vida (todos os esportes).
  lifetimeDistance,
}

/// Distancias da corrida e da caminhada (5 km, 10 km, meia e maratona).
const List<double> kFootDistanceMilestones = [5000, 10000, 21100, 42200];

/// Distancias do pedal.
const List<double> kRideDistanceMilestones = [20000, 50000, 100000];

/// Tempos em movimento (1 h e 2 h).
const List<int> kDurationMilestonesMs = [3600000, 7200000];

/// Acumulado na vida (100, 500 e 1000 km).
const List<double> kLifetimeMilestones = [100000, 500000, 1000000];

/// Treinos numa semana para o marco da semana.
const int kWeekWorkoutsMilestone = 3;

/// O GPS costuma medir um pouco a menos que a distancia oficial de uma prova:
/// ate 1% abaixo ainda conta para os marcos de distancia de uma atividade.
const double kDistanceTolerance = 0.99;

class Milestone {
  final MilestoneKind kind;

  /// Esporte (primeira atividade e distancia); null nos demais.
  final ActivityType? sport;

  /// Limite em metros (distancia e acumulado) ou ms (tempo); 0 nos demais.
  final num threshold;

  /// Inicio (hora local) da atividade que conquistou o marco. Serve so para
  /// achar o mes e o ano; nunca e mostrado.
  final DateTime achievedAt;

  const Milestone({
    required this.kind,
    required this.achievedAt,
    this.sport,
    this.threshold = 0,
  });

  /// Identificador estavel (ex.: `distance_run_5000`, `first_ride`).
  String get id => switch (kind) {
    MilestoneKind.firstActivity => 'first_${sport!.name}',
    MilestoneKind.distance => 'distance_${sport!.name}_${threshold.round()}',
    MilestoneKind.duration => 'duration_${threshold.round()}',
    MilestoneKind.threeWorkoutWeek => 'week_$kWeekWorkoutsMilestone',
    MilestoneKind.lifetimeDistance => 'lifetime_${threshold.round()}',
  };

  @override
  String toString() => 'Milestone($id)';
}

List<double> _distancesFor(ActivityType t) =>
    t == ActivityType.ride ? kRideDistanceMilestones : kFootDistanceMilestones;

/// Todos os marcos de primeira vez do historico, em ordem cronologica (na
/// mesma atividade: esporte, distancia, tempo, semana, acumulado). So as
/// atividades finalizadas contam.
List<Milestone> firstTimeMilestones(Iterable<ChapterActivity> all) {
  final out = <Milestone>[];
  final seen = <String>{};
  void add(Milestone m) {
    if (seen.add(m.id)) out.add(m);
  }

  final weekCounts = <DateTime, int>{};
  var weekDone = false;
  var lifetime = 0.0;
  var nextLifetime = 0;

  for (final a in finishedInOrder(all)) {
    final at = a.start;
    add(Milestone(kind: MilestoneKind.firstActivity, sport: a.type, achievedAt: at));
    final meters = a.safeMeters;
    for (final d in _distancesFor(a.type)) {
      if (meters >= d * kDistanceTolerance) {
        add(Milestone(kind: MilestoneKind.distance, sport: a.type, threshold: d, achievedAt: at));
      }
    }
    for (final ms in kDurationMilestonesMs) {
      if (a.safeTimerMs >= ms) {
        add(Milestone(kind: MilestoneKind.duration, threshold: ms, achievedAt: at));
      }
    }
    if (!weekDone) {
      final w = mondayOf(at);
      final n = (weekCounts[w] ?? 0) + 1;
      weekCounts[w] = n;
      if (n >= kWeekWorkoutsMilestone) {
        weekDone = true;
        add(Milestone(kind: MilestoneKind.threeWorkoutWeek, achievedAt: at));
      }
    }
    lifetime += meters;
    while (nextLifetime < kLifetimeMilestones.length &&
        lifetime >= kLifetimeMilestones[nextLifetime]) {
      add(Milestone(
        kind: MilestoneKind.lifetimeDistance,
        threshold: kLifetimeMilestones[nextLifetime],
        achievedAt: at,
      ));
      nextLifetime++;
    }
  }
  return out;
}

int _tier(MilestoneKind k) => switch (k) {
  MilestoneKind.lifetimeDistance => 4,
  MilestoneKind.distance => 3,
  MilestoneKind.duration => 2,
  MilestoneKind.threeWorkoutWeek => 1,
  MilestoneKind.firstActivity => 0,
};

/// Os [n] marcos mais marcantes (para a imagem): acumulado, depois distancia,
/// tempo, semana e primeira atividade; no mesmo tipo, o maior limite.
List<Milestone> topMilestones(List<Milestone> ms, int n) {
  final sorted = [...ms]
    ..sort((a, b) {
      final t = _tier(b.kind).compareTo(_tier(a.kind));
      if (t != 0) return t;
      final v = b.threshold.compareTo(a.threshold);
      return v != 0 ? v : a.achievedAt.compareTo(b.achievedAt);
    });
  return sorted.take(n).toList();
}
