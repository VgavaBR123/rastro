// Testes das estatisticas: semanas (segunda a domingo), janela de 8 semanas,
// totais por periodo, distribuicao por esporte, recordes e ganho de elevacao.
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/activity/stats_summary.dart';
import 'package:strava_estudo_app/activity/week_summary.dart' show startOfWeek;
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/domain/waypoint.dart' as dom;

// Quarta-feira, 22/10/2026 15:00 (hora local).
final now = DateTime(2026, 10, 22, 15);

StatEntry e(
  ActivityType type,
  DateTime start, {
  double km = 5,
  int min = 30,
  double? gain,
}) => StatEntry(
  type: type,
  startTimestampMs: start.millisecondsSinceEpoch,
  distanceMeters: km * 1000,
  timerTimeMs: min * 60 * 1000,
  elevationGainMeters: gain,
);

Waypoint wp(
  int seq,
  double? alt, {
  dom.WaypointClassification cls = dom.WaypointClassification.accept,
}) => Waypoint(
  id: seq,
  activityGuid: 'a',
  seq: seq,
  latitude: 0,
  longitude: 0,
  altitudeMeters: alt,
  elapsedTimeMs: seq * 1000,
  timerTimeMs: seq * 1000,
  cumulativeDistanceMeters: seq * 10.0,
  classification: cls.index,
);

void main() {
  test('semana comeca na segunda 00:00', () {
    expect(startOfWeek(now), DateTime(2026, 10, 19));
    expect(startOfWeek(DateTime(2026, 10, 19)), DateTime(2026, 10, 19));
    expect(
      startOfWeek(DateTime(2026, 10, 25, 23, 59)),
      DateTime(2026, 10, 19),
    );
    expect(
      startOfWeek(DateTime(2026, 10, 26, 0, 1)),
      DateTime(2026, 10, 26),
    );
  });

  test('8 semanas da mais antiga para a atual, empilhadas por esporte', () {
    final s = buildStatsSummary([
      e(ActivityType.run, DateTime(2026, 10, 20, 7), min: 40),
      e(ActivityType.ride, DateTime(2026, 10, 21, 18), min: 60),
      e(
        ActivityType.run,
        DateTime(2026, 10, 19, 0, 0),
        min: 20,
      ), // segunda 00:00
      e(
        ActivityType.walk,
        DateTime(2026, 10, 18, 23, 59),
        min: 15,
      ), // domingo anterior
      e(
        ActivityType.run,
        DateTime(2026, 8, 31, 10),
        min: 30,
      ), // primeira semana
      e(ActivityType.run, DateTime(2026, 8, 30, 10)), // antes da janela
      e(ActivityType.run, DateTime(2026, 10, 26, 8)), // semana que vem
    ], now: now);

    expect(s.weeks, hasLength(kStatsWeeks));
    expect(s.weeks.first.start, DateTime(2026, 8, 31));
    expect(s.weeks.last.start, DateTime(2026, 10, 19));
    expect(s.weeks.last.timerMsBySport, {
      ActivityType.run: 60 * 60000,
      ActivityType.ride: 60 * 60000,
    });
    expect(s.weeks[6].timerMsBySport, {ActivityType.walk: 15 * 60000});
    expect(s.weeks.first.timerMsBySport, {ActivityType.run: 30 * 60000});
    expect(s.entries, hasLength(5));
    expect(s.maxWeekTimerMs, 120 * 60000);
  });

  test('totais por periodo: semana, 4 semanas e 8 semanas', () {
    final s = buildStatsSummary([
      e(ActivityType.run, DateTime(2026, 10, 20), km: 10, min: 50, gain: 80),
      e(ActivityType.ride, DateTime(2026, 10, 1), km: 40, min: 90, gain: 300),
      e(ActivityType.walk, DateTime(2026, 9, 2), km: 3, min: 40),
    ], now: now);

    final week = s.totals(StatsPeriod.week);
    expect(week.count, 1);
    expect(week.distanceMeters, 10000);
    expect(week.timerTimeMs, 50 * 60000);
    expect(week.elevationGainMeters, 80);

    final month = s.totals(StatsPeriod.month);
    expect(month.count, 2);
    expect(month.distanceMeters, 50000);
    expect(month.elevationGainMeters, 380);

    expect(s.totals(StatsPeriod.eightWeeks).count, 3);
    expect(s.periodStart(StatsPeriod.month), DateTime(2026, 9, 28));
  });

  test('valores invalidos nao contaminam os totais', () {
    final t = StatTotals.of([
      const StatEntry(
        type: ActivityType.run,
        startTimestampMs: 0,
        distanceMeters: double.nan,
        timerTimeMs: -5,
        elevationGainMeters: double.infinity,
      ),
      e(ActivityType.run, now, km: 2, min: 10),
    ]);
    expect(t.count, 2);
    expect(t.distanceMeters, 2000);
    expect(t.timerTimeMs, 10 * 60000);
    expect(t.elevationGainMeters, 0);
  });

  test('distribuicao ordena pelo tempo e soma 1', () {
    final shares = sportDistribution([
      e(ActivityType.run, now, min: 30),
      e(ActivityType.walk, now, min: 90),
      e(ActivityType.run, now, min: 30),
    ]);
    expect(shares.map((s) => s.type), [ActivityType.walk, ActivityType.run]);
    expect(shares.first.fraction, closeTo(0.6, 1e-9));
    expect(shares.last.totals.count, 2);
    expect(shares.fold(0.0, (a, s) => a + s.fraction), closeTo(1, 1e-9));
    expect(sportDistribution(const []), isEmpty);
  });

  test('sem tempo registrado a distribuicao usa a contagem', () {
    final shares = sportDistribution([
      e(ActivityType.run, now, min: 0),
      e(ActivityType.ride, now, min: 0),
    ]);
    expect(shares.map((s) => s.fraction), [0.5, 0.5]);
  });

  group('recordes', () {
    test('maior distancia por esporte, melhor pace e maior pedal', () {
      final r = personalRecords([
        e(ActivityType.run, DateTime(2026, 1, 1), km: 10, min: 60), // 6:00/km
        e(ActivityType.run, DateTime(2026, 2, 1), km: 5, min: 25), // 5:00/km
        e(
          ActivityType.run,
          DateTime(2026, 3, 1),
          km: 0.5,
          min: 1,
        ), // curta demais
        e(ActivityType.ride, DateTime(2026, 4, 1), km: 60, min: 120),
        e(ActivityType.ride, DateTime(2026, 5, 1), km: 40, min: 150),
      ]);
      final byKind = {for (final x in r) (x.type, x.kind): x};
      expect(byKind.keys, {
        (ActivityType.run, RecordKind.longestDistance),
        (ActivityType.run, RecordKind.bestPace),
        (ActivityType.ride, RecordKind.longestDistance),
        (ActivityType.ride, RecordKind.longestTime),
      });
      expect(
        byKind[(ActivityType.run, RecordKind.longestDistance)]!.value,
        10000,
      );
      expect(
        byKind[(ActivityType.run, RecordKind.bestPace)]!.value,
        closeTo(0.3, 1e-9),
      );
      expect(
        byKind[(ActivityType.ride, RecordKind.longestDistance)]!.value,
        60000,
      );
      expect(
        byKind[(ActivityType.ride, RecordKind.longestTime)]!.value,
        150 * 60000,
      );
    });

    test('sem atividades com distancia nao ha recorde', () {
      expect(personalRecords([e(ActivityType.walk, now, km: 0)]), isEmpty);
      expect(personalRecords(const []), isEmpty);
    });
  });
}
