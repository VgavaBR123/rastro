// Carga do treino (F04) nas Estatisticas: sRPE (RPE x minutos) somado por
// semana; atividade sem RPE nao entra na carga.
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/activity/stats_summary.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';

// Quinta-feira, 22/10/2026 15:00 (hora local).
final now = DateTime(2026, 10, 22, 15);

StatEntry e(DateTime start, {int min = 30, int? rpe}) => StatEntry(
  type: ActivityType.run,
  startTimestampMs: start.millisecondsSinceEpoch,
  distanceMeters: 5000,
  timerTimeMs: min * 60000,
  rpe: rpe,
);

void main() {
  test('carga por semana: 8 semanas, da mais antiga para a atual', () {
    final s = buildStatsSummary([
      e(DateTime(2026, 10, 20, 7), min: 30, rpe: 5), // atual: 150
      e(DateTime(2026, 10, 21, 7), min: 40, rpe: 7), // atual: 280
      e(DateTime(2026, 10, 14, 7), min: 60, rpe: 4), // anterior: 240
      e(DateTime(2026, 10, 13, 7), min: 60), // sem RPE: fora da carga
    ], now: now);
    expect(s.weeks.map((w) => w.load).toList(), [0, 0, 0, 0, 0, 0, 240, 430]);
    expect(s.weeks.last.ratedCount, 2);
    expect(s.weeks[6].ratedCount, 1);
    expect(s.maxWeekLoad, 430);
  });

  test('carga do periodo e se ha algum treino com esforco', () {
    final s = buildStatsSummary([
      e(DateTime(2026, 10, 20, 7), min: 30, rpe: 5),
      e(DateTime(2026, 9, 29, 7), min: 30, rpe: 10), // 4 semanas: entra
      e(DateTime(2026, 9, 1, 7), min: 30, rpe: 10), // 8 semanas so
    ], now: now);
    expect(s.loadTotal(StatsPeriod.week), 150);
    expect(s.loadTotal(StatsPeriod.month), 450);
    expect(s.loadTotal(StatsPeriod.eightWeeks), 750);
    expect(s.hasLoad, isTrue);
    expect(buildStatsSummary([e(now)], now: now).hasLoad, isFalse);
  });
}
