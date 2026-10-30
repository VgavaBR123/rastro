// Sequencia semanal com coringa (F05): semana de segunda a domingo conta com
// pelo menos 1 atividade finalizada; cada mes da 1 coringa que cobre 1 semana
// vazia cuja segunda cai nele; sem coringa a sequencia recomeca.
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/chapters/domain/chapter_activity.dart';
import 'package:strava_estudo_app/chapters/domain/period.dart';
import 'package:strava_estudo_app/chapters/domain/weekly_streak.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';

ChapterActivity act(DateTime start, {bool finished = true}) => ChapterActivity(
  type: ActivityType.run,
  start: start,
  distanceMeters: 3000,
  timerMs: 1200000,
  finished: finished,
);

/// Uma atividade na quarta-feira de cada semana que comeca nas [mondays].
List<ChapterActivity> onWeeks(List<DateTime> mondays) => [
  for (final m in mondays) act(DateTime(m.year, m.month, m.day + 2, 7)),
];

/// Segundas a partir de [first], [n] semanas seguidas.
List<DateTime> mondays(DateTime first, int n) {
  final out = <DateTime>[];
  var m = first;
  for (var i = 0; i < n; i++) {
    out.add(m);
    m = nextMonday(m);
  }
  return out;
}

void main() {
  test('sem atividade: sequencia zero e sem recomeco', () {
    final s = weeklyStreak(const [], now: DateTime(2026, 10, 30));
    expect(s.current, 0);
    expect(s.longest, 0);
    expect(s.restarted, isFalse);
    expect(s.coveredMondays, isEmpty);
  });

  test('semanas ativas seguidas somam; a semana corrente vazia nao quebra', () {
    // Seg 5/10, 12/10, 19/10 ativas; hoje sexta 30/10 (semana de 26/10) vazia.
    final s = weeklyStreak(
      onWeeks(mondays(DateTime(2026, 10, 5), 3)),
      now: DateTime(2026, 10, 30, 12),
    );
    expect(s.current, 3);
    expect(s.restarted, isFalse);
  });

  test('a semana corrente soma quando ja tem atividade', () {
    final s = weeklyStreak(
      onWeeks(mondays(DateTime(2026, 10, 5), 4)),
      now: DateTime(2026, 10, 30, 12),
    );
    expect(s.current, 4);
    expect(s.longest, 4);
  });

  test('coringa cobre 1 semana vazia: mantem a sequencia, nao soma', () {
    // 5/10 e 12/10 ativas, 19/10 vazia (coringa de outubro), 26/10 ativa.
    final s = weeklyStreak(
      onWeeks([DateTime(2026, 10, 5), DateTime(2026, 10, 12), DateTime(2026, 10, 26)]),
      now: DateTime(2026, 11, 3),
    );
    expect(s.current, 3);
    expect(s.coveredMondays, [DateTime(2026, 10, 19)]);
    expect(s.jokerAvailable(const MonthKey(2026, 10)), isFalse);
    expect(s.jokerAvailable(const MonthKey(2026, 11)), isTrue);
  });

  test('coringa nao acumula: 2 semanas vazias no mesmo mes quebram', () {
    // Setembro sem uso nao vale para outubro.
    final s = weeklyStreak(
      onWeeks([...mondays(DateTime(2026, 9, 7), 4), DateTime(2026, 10, 26)]),
      now: DateTime(2026, 10, 30),
    );
    // 5/10 coberta pelo coringa de outubro; 12/10 sem coringa: recomeca; 19/10 vazia.
    expect(s.coveredMondays, [DateTime(2026, 10, 5)]);
    expect(s.current, 1);
    expect(s.longest, 4);
  });

  test('coringa no limite: semana que cruza o mes usa o coringa do mes da segunda', () {
    // Semana de seg 28/9 a dom 4/10 vazia: e de setembro (segunda em setembro).
    // Semana de 5/10 vazia: usa o de outubro. Sequencia sobrevive.
    final s = weeklyStreak(
      onWeeks([DateTime(2026, 9, 14), DateTime(2026, 9, 21), DateTime(2026, 10, 12)]),
      now: DateTime(2026, 10, 15, 12),
    );
    expect(s.coveredMondays, [DateTime(2026, 9, 28), DateTime(2026, 10, 5)]);
    expect(s.current, 3);
  });

  test('coringa so e gasto quando ha sequencia para proteger', () {
    // Primeira atividade em 19/10; antes disso nada a proteger.
    final s = weeklyStreak(onWeeks([DateTime(2026, 10, 19)]), now: DateTime(2026, 10, 21));
    expect(s.coveredMondays, isEmpty);
    expect(s.jokerAvailable(const MonthKey(2026, 10)), isTrue);
  });

  test('sem coringa a sequencia recomeca, com aviso de recomeco', () {
    // 5/10 ativa, 12/10 coberta, 19/10 vazia sem coringa; hoje 28/10.
    final s = weeklyStreak(onWeeks([DateTime(2026, 10, 5)]), now: DateTime(2026, 10, 28));
    expect(s.current, 0);
    expect(s.restarted, isTrue);
    expect(s.longest, 1);
  });

  test('recomecou e voltou a treinar na semana corrente: 1, ainda recomeco', () {
    final s = weeklyStreak(
      onWeeks([DateTime(2026, 10, 5), DateTime(2026, 10, 26)]),
      now: DateTime(2026, 10, 30),
    );
    expect(s.current, 1);
    expect(s.restarted, isTrue);
  });

  test('virada do ano: semana de 28/12 a 3/1 e uma so', () {
    final s = weeklyStreak(
      [
        act(DateTime(2026, 12, 21, 7)),
        act(DateTime(2027, 1, 2, 9)), // sabado da semana de 28/12
        act(DateTime(2027, 1, 5, 7)),
      ],
      now: DateTime(2027, 1, 8),
    );
    expect(s.current, 3);
    expect(s.coveredMondays, isEmpty);
  });

  test('horario de verao: atividade logo apos a meia-noite de segunda cai na semana certa', () {
    // Percorre um ano inteiro: qualquer mudanca de horario local no caminho.
    final ms = mondays(DateTime(2026, 1, 5), 52);
    final acts = [for (final m in ms) act(DateTime(m.year, m.month, m.day, 0, 30))];
    final s = weeklyStreak(acts, now: DateTime(2026, 12, 31, 23));
    expect(s.current, 52);
    expect(s.coveredMondays, isEmpty);
    expect(s.weeks.where((w) => w.status == WeekStatus.active), hasLength(52));
  });

  test('nao finalizada e futura sao ignoradas', () {
    final s = weeklyStreak(
      [
        act(DateTime(2026, 10, 7), finished: false),
        act(DateTime(2026, 12, 1)),
      ],
      now: DateTime(2026, 10, 30),
    );
    expect(s.current, 0);
    expect(s.restarted, isFalse);
  });

  test('historico grande: 10 anos de semanas em pouco tempo', () {
    final acts = onWeeks(mondays(DateTime(2016, 1, 4), 520));
    final sw = Stopwatch()..start();
    final s = weeklyStreak(acts, now: DateTime(2026, 1, 1));
    expect(sw.elapsedMilliseconds, lessThan(1000));
    expect(s.longest, greaterThan(500));
  });
}
