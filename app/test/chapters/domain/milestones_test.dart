// Marcos de primeira vez (F05): cada marco pertence ao momento em que foi
// atingido pela primeira vez no historico inteiro do aparelho.
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/chapters/domain/chapter_activity.dart';
import 'package:strava_estudo_app/chapters/domain/milestones.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';

ChapterActivity act(
  DateTime start, {
  ActivityType type = ActivityType.run,
  double km = 3,
  int min = 20,
  bool finished = true,
}) => ChapterActivity(
  type: type,
  start: start,
  distanceMeters: km * 1000,
  timerMs: min * 60000,
  finished: finished,
);

List<String> ids(Iterable<Milestone> ms) => [for (final m in ms) m.id];

void main() {
  test('historico vazio: nenhum marco', () {
    expect(firstTimeMilestones(const []), isEmpty);
  });

  test('primeira atividade de cada esporte, so a primeira', () {
    final ms = firstTimeMilestones([
      act(DateTime(2026, 2, 3), type: ActivityType.walk),
      act(DateTime(2026, 1, 10)),
      act(DateTime(2026, 1, 12)),
      act(DateTime(2026, 3, 1), type: ActivityType.ride),
    ]);
    final firsts = ms.where((m) => m.kind == MilestoneKind.firstActivity).toList();
    expect(firsts.map((m) => m.sport), [ActivityType.run, ActivityType.walk, ActivityType.ride]);
    expect(firsts.first.achievedAt, DateTime(2026, 1, 10));
  });

  test('distancias da corrida e da caminhada, cada esporte o seu', () {
    final ms = firstTimeMilestones([
      act(DateTime(2026, 1, 1), km: 5.2),
      act(DateTime(2026, 1, 8), km: 10.4, min: 55),
      act(DateTime(2026, 2, 1), km: 21.2, min: 59),
      act(DateTime(2026, 3, 1), type: ActivityType.walk, km: 5.0, min: 50),
      act(DateTime(2026, 4, 1), km: 6),
    ]);
    expect(
      ids(ms.where((m) => m.kind == MilestoneKind.distance)),
      ['distance_run_5000', 'distance_run_10000', 'distance_run_21100', 'distance_walk_5000'],
    );
    expect(ms.firstWhere((m) => m.id == 'distance_run_21100').achievedAt, DateTime(2026, 2, 1));
  });

  test('uma atividade longa conquista todas as distancias menores de uma vez', () {
    final ms = firstTimeMilestones([act(DateTime(2026, 5, 3), km: 42.3, min: 50)]);
    expect(
      ids(ms.where((m) => m.kind == MilestoneKind.distance)),
      ['distance_run_5000', 'distance_run_10000', 'distance_run_21100', 'distance_run_42200'],
    );
  });

  test('GPS curto em ate 1% ainda conta (4.96 km vale o 5 km)', () {
    expect(ids(firstTimeMilestones([act(DateTime(2026, 1, 1), km: 4.96)])), contains('distance_run_5000'));
    expect(
      ids(firstTimeMilestones([act(DateTime(2026, 1, 1), km: 4.9)])),
      isNot(contains('distance_run_5000')),
    );
  });

  test('pedal: 20, 50 e 100 km; pedal nao conta para os 5 km da corrida', () {
    final ms = firstTimeMilestones([
      act(DateTime(2026, 1, 1), type: ActivityType.ride, km: 25, min: 59),
      act(DateTime(2026, 2, 1), type: ActivityType.ride, km: 101, min: 59),
    ]);
    expect(
      ids(ms.where((m) => m.kind == MilestoneKind.distance)),
      ['distance_ride_20000', 'distance_ride_50000', 'distance_ride_100000'],
    );
  });

  test('primeira atividade de 1 h e de 2 h, qualquer esporte', () {
    final ms = firstTimeMilestones([
      act(DateTime(2026, 1, 1), min: 59),
      act(DateTime(2026, 1, 2), type: ActivityType.walk, min: 60),
      act(DateTime(2026, 1, 9), type: ActivityType.ride, min: 130),
    ]);
    final d = ms.where((m) => m.kind == MilestoneKind.duration).toList();
    expect(ids(d), ['duration_3600000', 'duration_7200000']);
    expect(d.first.achievedAt, DateTime(2026, 1, 2));
  });

  test('primeira semana com 3 treinos: no 3o treino, semana de segunda a domingo', () {
    final ms = firstTimeMilestones([
      // Sab e dom de uma semana + seg da seguinte: nao fecha 3 na mesma.
      act(DateTime(2026, 10, 24)),
      act(DateTime(2026, 10, 25, 23)),
      act(DateTime(2026, 10, 26, 6)),
      act(DateTime(2026, 10, 28)),
      act(DateTime(2026, 11, 1, 20)), // domingo, 3o da semana de 26/10
      act(DateTime(2026, 11, 4)),
    ]);
    final w = ms.where((m) => m.kind == MilestoneKind.threeWorkoutWeek).toList();
    expect(w, hasLength(1));
    expect(w.single.achievedAt, DateTime(2026, 11, 1, 20));
  });

  test('acumulado na vida: 100, 500 e 1000 km somando os esportes', () {
    final list = [
      for (var i = 0; i < 40; i++)
        act(
          DateTime(2026, 1, 1).add(Duration(days: i * 3)),
          type: i.isEven ? ActivityType.ride : ActivityType.run,
          km: i.isEven ? 40 : 10,
        ),
    ];
    final ms = firstTimeMilestones(list)
        .where((m) => m.kind == MilestoneKind.lifetimeDistance)
        .toList();
    expect(ids(ms), ['lifetime_100000', 'lifetime_500000', 'lifetime_1000000']);
    // 40 + 10 + 40 + 10 = 100 na 4a; 20 x 40 + 20 x 10 = 1000 na ultima.
    expect(ms.first.achievedAt, list[3].start);
    expect(ms.last.achievedAt, list.last.start);
  });

  test('nao finalizada e ignorada; dados invalidos nao quebram', () {
    final ms = firstTimeMilestones([
      act(DateTime(2026, 1, 1), km: 50, min: 300, finished: false),
      ChapterActivity(
        type: ActivityType.run,
        start: DateTime(2026, 1, 2),
        distanceMeters: double.nan,
        timerMs: -5,
      ),
    ]);
    expect(ids(ms), ['first_run']);
  });

  test('ordem cronologica mesmo com entrada fora de ordem', () {
    final ms = firstTimeMilestones([
      act(DateTime(2026, 3, 1), type: ActivityType.walk),
      act(DateTime(2026, 1, 1)),
    ]);
    expect(ids(ms), ['first_run', 'first_walk']);
  });

  test('historico grande (5000 atividades) roda rapido', () {
    final list = [
      for (var i = 0; i < 5000; i++)
        act(
          DateTime(2010, 1, 1).add(Duration(hours: i * 19)),
          km: 3 + (i % 9).toDouble(),
          min: 20 + (i % 100),
        ),
    ];
    final sw = Stopwatch()..start();
    final ms = firstTimeMilestones(list);
    expect(sw.elapsedMilliseconds, lessThan(1000));
    expect(ids(ms), contains('lifetime_1000000'));
  });

  test('os 3 marcos da imagem: os de maior peso primeiro', () {
    final ms = firstTimeMilestones([act(DateTime(2026, 1, 1), km: 42.2, min: 130)]);
    expect(
      ids(topMilestones(ms, 3)),
      ['distance_run_42200', 'distance_run_21100', 'distance_run_10000'],
    );
    expect(topMilestones(const [], 3), isEmpty);
  });
}
