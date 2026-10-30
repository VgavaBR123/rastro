// Capitulo do mes e do ano (F05): totais, esportes, a mais longa, marcos,
// sequencia, quais meses e anos aparecem e quando o cartao do Inicio aparece.
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/chapters/domain/chapter.dart';
import 'package:strava_estudo_app/chapters/domain/chapter_activity.dart';
import 'package:strava_estudo_app/chapters/domain/milestones.dart';
import 'package:strava_estudo_app/chapters/domain/period.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';

ChapterActivity act(
  DateTime start, {
  ActivityType type = ActivityType.run,
  double km = 5,
  int min = 30,
  bool finished = true,
}) => ChapterActivity(
  type: type,
  start: start,
  distanceMeters: km * 1000,
  timerMs: min * 60000,
  finished: finished,
);

void main() {
  const oct = MonthKey(2026, 10);
  final now = DateTime(2026, 11, 2, 9);

  group('mes', () {
    test('totais, dias ativos e divisao por esporte', () {
      final c = buildMonthChapter([
        act(DateTime(2026, 9, 30, 23, 59)), // fora (setembro)
        act(DateTime(2026, 10, 1, 0, 1)),
        act(DateTime(2026, 10, 1, 18), type: ActivityType.walk, km: 2, min: 25),
        act(DateTime(2026, 10, 15), type: ActivityType.ride, km: 30, min: 70),
        act(DateTime(2026, 10, 31, 23, 59)),
        act(DateTime(2026, 10, 20), finished: false, km: 99),
        act(DateTime(2026, 11, 1, 0, 0)), // fora (novembro)
      ], oct, now: now);
      expect(c.isEmpty, isFalse);
      expect(c.totals.count, 4);
      expect(c.totals.distanceMeters, 42000);
      expect(c.totals.timerMs, (30 + 25 + 70 + 30) * 60000);
      expect(c.totals.activeDays, 3);
      // Do maior tempo para o menor.
      expect(c.sports.map((s) => s.type), [ActivityType.ride, ActivityType.run, ActivityType.walk]);
      expect(c.sports[1].count, 2);
      expect(c.longest!.type, ActivityType.ride);
      expect(c.longest!.distanceMeters, 30000);
    });

    test('pace medio so das corridas; null sem corrida', () {
      final c = buildMonthChapter([
        act(DateTime(2026, 10, 3), km: 5, min: 30),
        act(DateTime(2026, 10, 5), km: 10, min: 60),
        act(DateTime(2026, 10, 6), type: ActivityType.ride, km: 30, min: 60),
      ], oct, now: now);
      expect(c.runPaceSecondsPerMeter, closeTo(5400 / 15000, 1e-9));
      final noRun = buildMonthChapter([
        act(DateTime(2026, 10, 6), type: ActivityType.ride),
      ], oct, now: now);
      expect(noRun.runPaceSecondsPerMeter, isNull);
    });

    test('a mais longa e por distancia; sem distancia, pelo tempo', () {
      final c = buildMonthChapter([
        act(DateTime(2026, 10, 3), km: 0, min: 50, type: ActivityType.walk),
        act(DateTime(2026, 10, 4), km: 0, min: 80),
      ], oct, now: now);
      expect(c.longest!.timerMs, 80 * 60000);
    });

    test('marcos sao os atingidos pela primeira vez neste mes', () {
      final c = buildMonthChapter([
        act(DateTime(2026, 9, 2), km: 5.5), // primeira corrida e 5 km em setembro
        act(DateTime(2026, 10, 4), km: 10.2, min: 62),
        act(DateTime(2026, 10, 8), km: 5.5),
      ], oct, now: now);
      expect(c.milestones.map((m) => m.id), ['distance_run_10000', 'duration_3600000']);
    });

    test('mes vazio: capitulo curto, com sequencia', () {
      final c = buildMonthChapter([act(DateTime(2026, 9, 2))], oct, now: now);
      expect(c.isEmpty, isTrue);
      expect(c.totals.count, 0);
      expect(c.longest, isNull);
      expect(c.milestones, isEmpty);
      expect(c.streak.current, 0);
    });

    test('sequencia no fim do mes e coringas cuja segunda cai no mes', () {
      final c = buildMonthChapter([
        act(DateTime(2026, 10, 7)),
        act(DateTime(2026, 10, 14)),
        // 19/10 vazia: coringa de outubro.
        act(DateTime(2026, 10, 28)),
        // Atividade de novembro nao entra na sequencia do capitulo de outubro.
        act(DateTime(2026, 11, 2)),
      ], oct, now: now);
      expect(c.streak.current, 3);
      expect(c.jokersUsed, [DateTime(2026, 10, 19)]);
    });
  });

  group('ano', () {
    final list = [
      act(DateTime(2025, 12, 31, 23)),
      act(DateTime(2026, 1, 10), km: 5, min: 30),
      act(DateTime(2026, 3, 1), km: 10, min: 60),
      act(DateTime(2026, 3, 8), km: 10, min: 60),
      act(DateTime(2026, 7, 3), type: ActivityType.ride, km: 60, min: 100),
    ];

    test('totais do ano, melhor mes por tempo e marcos do ano', () {
      final y = buildYearChapter(list, 2026, now: now);
      expect(y.totals.count, 4);
      expect(y.bestMonth, const MonthKey(2026, 3));
      expect(y.bestMonthTotals!.timerMs, 120 * 60000);
      // A primeira corrida foi em 2025: nao e marco de 2026.
      expect(y.milestones.map((m) => m.id), isNot(contains('first_run')));
      expect(y.milestones.map((m) => m.id), contains('first_ride'));
      expect(y.partial, isTrue);
    });

    test('ano anterior fechado; maior sequencia do ano', () {
      final y = buildYearChapter(list, 2025, now: now);
      expect(y.partial, isFalse);
      expect(y.totals.count, 1);
      expect(y.longestStreak, 1);
    });

    test('ano sem atividade: vazio, sem melhor mes', () {
      final y = buildYearChapter(list, 2024, now: now);
      expect(y.isEmpty, isTrue);
      expect(y.bestMonth, isNull);
    });
  });

  group('indice', () {
    test('meses com dados, so os fechados, do mais recente', () {
      final months = chapterMonths([
        act(DateTime(2026, 8, 3)),
        act(DateTime(2026, 10, 3)),
        act(DateTime(2026, 11, 1)), // mes corrente: ainda nao fechado
        act(DateTime(2026, 9, 3), finished: false),
      ], now: now);
      expect(months, [const MonthKey(2026, 10), const MonthKey(2026, 8)]);
    });

    test('anos: os com dados e sempre o corrente (ate agora)', () {
      expect(chapterYears([act(DateTime(2024, 5, 1))], now: now), [2026, 2024]);
      expect(chapterYears(const [], now: now), [2026]);
    });
  });

  group('cartao do Inicio', () {
    test('a partir do dia 1 mostra o mes anterior, ate abrir ou dispensar', () {
      final acts = [act(DateTime(2026, 10, 3))];
      expect(pendingHomeChapter(acts, now: DateTime(2026, 11, 1, 0, 1)), oct);
      expect(pendingHomeChapter(acts, now: now, seenCode: 202609), oct);
      expect(pendingHomeChapter(acts, now: now, seenCode: 202610), isNull);
      // Antes do fim do mes: ainda nao.
      expect(pendingHomeChapter(acts, now: DateTime(2026, 10, 31, 23)), isNull);
    });

    test('mes sem atividade com historico anterior: mostra (capitulo gentil)', () {
      expect(pendingHomeChapter([act(DateTime(2026, 8, 3))], now: now), oct);
    });

    test('app novo: sem nenhuma atividade antes deste mes, nao mostra', () {
      expect(pendingHomeChapter(const [], now: now), isNull);
      expect(pendingHomeChapter([act(DateTime(2026, 11, 1, 8))], now: now), isNull);
      expect(
        pendingHomeChapter([act(DateTime(2026, 10, 3), finished: false)], now: now),
        isNull,
      );
    });

    test('virada do ano: em janeiro o cartao e de dezembro', () {
      expect(
        pendingHomeChapter([act(DateTime(2026, 12, 3))], now: DateTime(2027, 1, 1, 8)),
        const MonthKey(2026, 12),
      );
    });
  });

  test('marcos do capitulo vem do historico inteiro', () {
    final big = [
      for (var i = 0; i < 300; i++) act(DateTime(2020, 1, 1).add(Duration(days: i * 5)), km: 4),
      act(DateTime(2026, 10, 5), km: 5.1),
    ];
    final c = buildMonthChapter(big, oct, now: now);
    expect(c.milestones.map((m) => m.id), ['distance_run_5000']);
    expect(c.milestones.single.kind, MilestoneKind.distance);
  });
}
