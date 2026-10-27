// Testes da logica pura do resumo da semana (Inicio).
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/activity/week_summary.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';

WeekEntry e(DateTime start, ActivityType t, {double m = 1000, int ms = 600000, double? gain}) => WeekEntry(
      type: t,
      startTimestampMs: start.millisecondsSinceEpoch,
      distanceMeters: m,
      timerTimeMs: ms,
      elevationGainMeters: gain,
    );

void main() {
  // Quarta-feira, 28/10/2026.
  final now = DateTime(2026, 10, 28, 15, 30);

  test('semana comeca na segunda 00:00', () {
    expect(startOfWeek(now), DateTime(2026, 10, 26));
    expect(startOfWeek(DateTime(2026, 10, 26, 0, 0)), DateTime(2026, 10, 26));
    expect(startOfWeek(DateTime(2026, 11, 1, 23, 59)), DateTime(2026, 10, 26));
  });

  test('sem atividades: zeros e sete dias vazios', () {
    final s = buildWeekSummary(const [], now: now);
    expect(s.count, 0);
    expect(s.distanceMeters, 0);
    expect(s.timerTimeMs, 0);
    expect(s.elevationGainMeters, 0);
    expect(s.days, hasLength(7));
    expect(s.days.every((d) => d.isEmpty), isTrue);
    expect(s.maxDayTimerMs, 0);
  });

  test('so soma as atividades da semana atual', () {
    final s = buildWeekSummary([
      e(DateTime(2026, 10, 25, 23, 59), ActivityType.run), // domingo anterior
      e(DateTime(2026, 10, 26, 7), ActivityType.run, m: 5000, ms: 1800000, gain: 40),
      e(DateTime(2026, 10, 28, 6), ActivityType.ride, m: 20000, ms: 3600000, gain: 120.5),
      e(DateTime(2026, 11, 2, 7), ActivityType.walk), // proxima segunda
    ], now: now);
    expect(s.count, 2);
    expect(s.distanceMeters, 25000);
    expect(s.timerTimeMs, 5400000);
    expect(s.elevationGainMeters, closeTo(160.5, 1e-9));
    expect(s.workouts, [ActivityType.run, ActivityType.ride]);
  });

  test('cada dia soma o tempo e fica com a cor do esporte de mais tempo', () {
    final s = buildWeekSummary([
      e(DateTime(2026, 10, 27, 18), ActivityType.run, ms: 1200000),
      e(DateTime(2026, 10, 27, 7), ActivityType.walk, ms: 600000),
      e(DateTime(2026, 11, 1, 9), ActivityType.ride, ms: 300000),
    ], now: now);
    expect(s.days[0].isEmpty, isTrue);
    expect(s.days[1].timerTimeMs, 1800000);
    expect(s.days[1].distanceMeters, 2000);
    expect(s.days[1].mainType, ActivityType.run);
    expect(s.days[6].mainType, ActivityType.ride);
    expect(s.maxDayTimerMs, 1800000);
    // Ordem cronologica dos treinos.
    expect(s.workouts, [ActivityType.walk, ActivityType.run, ActivityType.ride]);
  });

  test('ganho ausente conta como zero', () {
    final s = buildWeekSummary([e(DateTime(2026, 10, 28, 7), ActivityType.run)], now: now);
    expect(s.elevationGainMeters, 0);
  });
}
