// Paginas do capitulo (F05): de 4 a 6 paginas, textos gentis, unidades da
// configuracao e, no Modo Gentil, nada de pace, velocidade ou "mais rapido".
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/chapters/domain/chapter.dart';
import 'package:strava_estudo_app/chapters/domain/chapter_activity.dart';
import 'package:strava_estudo_app/chapters/domain/chapter_pages.dart';
import 'package:strava_estudo_app/chapters/domain/milestones.dart';
import 'package:strava_estudo_app/chapters/domain/period.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';

ChapterActivity act(
  DateTime start, {
  ActivityType type = ActivityType.run,
  double km = 5,
  int min = 30,
}) => ChapterActivity(type: type, start: start, distanceMeters: km * 1000, timerMs: min * 60000);

String allText(List<ChapterPage> pages) => pages.map((p) => p.allText).join('\n');

void main() {
  const oct = MonthKey(2026, 10);
  final now = DateTime(2026, 11, 2, 9);
  final full = [
    act(DateTime(2026, 9, 3)),
    act(DateTime(2026, 10, 3), km: 10.5, min: 62),
    act(DateTime(2026, 10, 10), type: ActivityType.ride, km: 25, min: 70),
    act(DateTime(2026, 10, 17)),
  ];

  test('mes cheio: abertura, totais, esportes, a mais longa, marcos e fechamento', () {
    final pages = monthChapterPages(
      buildMonthChapter(full, oct, now: now),
      gentle: false,
      metric: true,
    );
    expect(pages.map((p) => p.kind), [
      ChapterPageKind.opening,
      ChapterPageKind.totals,
      ChapterPageKind.sports,
      ChapterPageKind.highlight,
      ChapterPageKind.milestones,
      ChapterPageKind.closing,
    ]);
    expect(pages.first.title, 'Outubro');
    final totals = pages[1].stats.map((s) => s.label).toList();
    expect(totals, ['Distancia', 'Tempo em movimento', 'Treinos', 'Dias ativos', 'Pace medio da corrida']);
    expect(pages[1].stats.first.value, '40.50 km');
    expect(pages[3].stats.map((s) => s.label), ['Distancia', 'Tempo']);
    expect(pages[4].lines, contains('Primeiro pedal'));
    expect(pages[4].lines, contains('Primeira corrida de 10 km'));
  });

  test('entre 4 e 6 paginas: um esporte e sem marcos tira as opcionais', () {
    final pages = monthChapterPages(
      buildMonthChapter([act(DateTime(2026, 9, 3)), act(DateTime(2026, 10, 3))], oct, now: now),
      gentle: false,
      metric: true,
    );
    expect(pages.map((p) => p.kind), [
      ChapterPageKind.opening,
      ChapterPageKind.totals,
      ChapterPageKind.highlight,
      ChapterPageKind.closing,
    ]);
  });

  test('Modo Gentil: nenhuma pagina fala de pace, velocidade ou rapidez', () {
    final text = allText(monthChapterPages(
      buildMonthChapter(full, oct, now: now),
      gentle: true,
      metric: true,
    )).toLowerCase();
    for (final banned in ['pace', 'ritmo', 'velocidade', 'rapid', '/km', 'km/h']) {
      expect(text, isNot(contains(banned)), reason: banned);
    }
  });

  test('milhas quando a configuracao e imperial', () {
    final pages = monthChapterPages(
      buildMonthChapter(full, oct, now: now),
      gentle: false,
      metric: false,
    );
    expect(pages[1].stats.first.value, endsWith('mi'));
    expect(pages[1].stats.last.value, endsWith('/mi'));
    expect(pages[4].lines, contains('Primeira corrida de 6.2 mi'));
  });

  test('mes vazio: curto e gentil, sem culpa', () {
    final pages = monthChapterPages(
      buildMonthChapter([act(DateTime(2026, 9, 3))], oct, now: now),
      gentle: false,
      metric: true,
    );
    expect(pages.length, 2);
    expect(pages.first.lines, contains('Outubro foi de descanso. Novembro comeca agora.'));
    final text = allText(pages).toLowerCase();
    for (final banned in ['perdeu', 'falhou', 'nao treinou', 'quebrou', 'zero']) {
      expect(text, isNot(contains(banned)), reason: banned);
    }
    expect(text, contains('sua sequencia recomeca agora. uma semana de cada vez.'));
  });

  test('dezembro vazio: janeiro comeca agora', () {
    final pages = monthChapterPages(
      buildMonthChapter([act(DateTime(2026, 9, 3))], const MonthKey(2026, 12), now: DateTime(2027, 1, 2)),
      gentle: true,
      metric: true,
    );
    expect(pages.first.lines, contains('Dezembro foi de descanso. Janeiro comeca agora.'));
  });

  test('fechamento mostra a sequencia e os coringas usados', () {
    final pages = monthChapterPages(
      buildMonthChapter([
        act(DateTime(2026, 10, 7)),
        act(DateTime(2026, 10, 14)),
        act(DateTime(2026, 10, 28)),
      ], oct, now: now),
      gentle: false,
      metric: true,
    );
    final closing = pages.last;
    expect(closing.kind, ChapterPageKind.closing);
    expect(closing.stats.map((s) => '${s.label}: ${s.value}'), [
      'Sequencia semanal: 3 semanas',
      'Coringas usados: 1',
    ]);
  });

  test('ano: abertura "ate agora", melhor mes e maior sequencia', () {
    final pages = yearChapterPages(
      buildYearChapter(full, 2026, now: now),
      gentle: false,
      metric: true,
    );
    expect(pages.first.title, '2026');
    expect(pages.first.lines, contains('Seu ano ate agora.'));
    expect(pages.map((p) => p.kind), contains(ChapterPageKind.bestMonth));
    expect(pages.length, inInclusiveRange(4, 6));
    final best = pages.firstWhere((p) => p.kind == ChapterPageKind.bestMonth);
    expect(best.stats.first.value, 'Outubro');
    expect(pages.last.stats.first.label, 'Maior sequencia');
  });

  test('ano fechado e ano vazio', () {
    final closed = yearChapterPages(
      buildYearChapter(full, 2026, now: DateTime(2027, 1, 1)),
      gentle: true,
      metric: true,
    );
    expect(closed.first.lines, contains('Seu ano no Rastro.'));
    final empty = yearChapterPages(
      buildYearChapter(const [], 2026, now: now),
      gentle: true,
      metric: true,
    );
    expect(empty.length, 2);
    expect(empty.first.lines.join(' '), contains('descanso'));
  });

  test('rotulo de cada marco', () {
    String l(Milestone m) => milestoneLabel(m, metric: true);
    final ms = firstTimeMilestones([
      act(DateTime(2026, 1, 1), km: 42.3, min: 130),
      act(DateTime(2026, 1, 2), type: ActivityType.walk, km: 21.2, min: 250),
      act(DateTime(2026, 1, 3), type: ActivityType.ride, km: 101, min: 200),
    ]);
    final labels = ms.map(l).toList();
    expect(labels, containsAll([
      'Primeira corrida',
      'Primeira caminhada',
      'Primeiro pedal',
      'Primeira meia maratona',
      'Primeira maratona',
      'Primeira caminhada de 21.1 km',
      'Primeiro pedal de 100 km',
      'Primeiro treino de 1 hora',
      'Primeiro treino de 2 horas',
      'Primeira semana com 3 treinos',
      '100 km na vida',
    ]));
  });

  test('cada pagina tem um rotulo para o leitor de tela', () {
    final pages = monthChapterPages(buildMonthChapter(full, oct, now: now), gentle: false, metric: true);
    for (final p in pages) {
      expect(p.semanticsLabel, isNotEmpty);
      expect(p.semanticsLabel, contains(p.title));
    }
    expect(pages[1].semanticsLabel, contains('Distancia: 40.50 km'));
  });
}
