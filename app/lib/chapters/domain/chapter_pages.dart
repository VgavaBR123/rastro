// Paginas do capitulo (F05): os textos de cada pagina estilo story e o
// resumo da imagem compartilhada. Dart puro: a UI so desenha o que sai daqui,
// e o teste de privacidade e o do Modo Gentil olham estes textos.
//
// Regras de texto: nunca culpa (mes vazio e "descanso"); no Modo Gentil nada
// de pace, velocidade ou rapidez; unidades conforme `metric`; nada de titulo,
// trajeto ou horario (o capitulo nem recebe esses dados).
library;

import '../../core/format/activity_labels.dart';
import '../../core/format/measures.dart';
import '../../recording/domain/recording_models.dart';
import 'chapter.dart';
import 'milestones.dart';
import 'period.dart';

enum ChapterPageKind {
  opening,
  totals,
  sports,
  highlight,
  bestMonth,
  milestones,
  closing,
}

/// Funcao do numero, para a UI escolher a cor do tema.
enum ChapterStatRole { distance, time, count, days, pace, sport, streak, joker, month }

class ChapterStat {
  final String label;
  final String value;

  /// Linha menor embaixo do valor (ex.: "2 treinos · 1:02:00").
  final String? detail;
  final ChapterStatRole role;

  /// Esporte, quando role == sport.
  final ActivityType? sport;

  const ChapterStat({
    required this.label,
    required this.value,
    required this.role,
    this.detail,
    this.sport,
  });

  String get spoken => detail == null ? '$label: $value' : '$label: $value, $detail';
}

class ChapterPage {
  final ChapterPageKind kind;
  final String title;
  final List<String> lines;
  final List<ChapterStat> stats;

  const ChapterPage({
    required this.kind,
    required this.title,
    this.lines = const [],
    this.stats = const [],
  });

  /// Tudo o que a pagina escreve (testes de privacidade e Modo Gentil).
  String get allText => [
    title,
    ...lines,
    for (final s in stats) ...[s.label, s.value, ?s.detail],
  ].join('\n');

  /// O que o leitor de tela le ao chegar na pagina.
  String get semanticsLabel =>
      [title, ...lines, for (final s in stats) s.spoken].join('. ');
}

/// O que a imagem compartilhada mostra: titulo, totais e ate 3 marcos.
class ChapterShareData {
  final String heading;
  final String subheading;
  final List<ChapterStat> stats;
  final List<String> milestones;

  /// Texto que vai junto da imagem.
  final String text;

  const ChapterShareData({
    required this.heading,
    required this.subheading,
    required this.stats,
    required this.milestones,
    required this.text,
  });
}

/// Maximo de marcos listados numa pagina (o resto vira "e mais N").
const int kMilestonesPerPage = 6;

/// Marcos na imagem compartilhada.
const int kShareMilestones = 3;

String _plural(int n, String one, String many) => n == 1 ? '1 $one' : '$n $many';

String _weeks(int n) => _plural(n, 'semana', 'semanas');
String _workouts(int n) => _plural(n, 'treino', 'treinos');

/// "5 km", "21.1 km" ou "3.1 mi": limites de marco, sem casas a toa.
String _thresholdDistance(num meters, {required bool metric}) {
  if (metric) {
    final km = meters / 1000;
    final text = km == km.roundToDouble() ? km.round().toString() : km.toStringAsFixed(1);
    return '$text km';
  }
  return '${(meters / 1609.344).toStringAsFixed(1)} mi';
}

String _firstOf(ActivityType t) => switch (t) {
  ActivityType.run => 'Primeira corrida',
  ActivityType.walk => 'Primeira caminhada',
  ActivityType.ride => 'Primeiro pedal',
};

String _articleSport(ActivityType t) => switch (t) {
  ActivityType.run => 'uma corrida',
  ActivityType.walk => 'uma caminhada',
  ActivityType.ride => 'um pedal',
};

/// Nome do marco para a pessoa.
String milestoneLabel(Milestone m, {required bool metric}) {
  switch (m.kind) {
    case MilestoneKind.firstActivity:
      return _firstOf(m.sport!);
    case MilestoneKind.distance:
      if (m.sport == ActivityType.run && m.threshold == 21100) {
        return 'Primeira meia maratona';
      }
      if (m.sport == ActivityType.run && m.threshold == 42200) {
        return 'Primeira maratona';
      }
      return '${_firstOf(m.sport!)} de ${_thresholdDistance(m.threshold, metric: metric)}';
    case MilestoneKind.duration:
      final h = m.threshold ~/ 3600000;
      return 'Primeiro treino de ${_plural(h, 'hora', 'horas')}';
    case MilestoneKind.threeWorkoutWeek:
      return 'Primeira semana com $kWeekWorkoutsMilestone treinos';
    case MilestoneKind.lifetimeDistance:
      return '${_thresholdDistance(m.threshold, metric: metric)} na vida';
  }
}

List<ChapterStat> _totalStats(ChapterTotals t, {required bool metric}) => [
  ChapterStat(
    label: 'Distancia',
    value: formatDistance(t.distanceMeters, metric: metric),
    role: ChapterStatRole.distance,
  ),
  ChapterStat(
    label: 'Tempo em movimento',
    value: formatDuration(t.timerMs),
    role: ChapterStatRole.time,
  ),
  ChapterStat(label: 'Treinos', value: '${t.count}', role: ChapterStatRole.count),
  ChapterStat(label: 'Dias ativos', value: '${t.activeDays}', role: ChapterStatRole.days),
];

ChapterPage _sportsPage(List<SportTotals> sports, {required bool metric}) => ChapterPage(
  kind: ChapterPageKind.sports,
  title: 'Por esporte',
  stats: [
    for (final s in sports)
      ChapterStat(
        label: activityTypeLabel(s.type),
        value: s.distanceMeters > 0
            ? formatDistance(s.distanceMeters, metric: metric)
            : formatDuration(s.timerMs),
        detail: '${_workouts(s.count)} · ${formatDuration(s.timerMs)}',
        role: ChapterStatRole.sport,
        sport: s.type,
      ),
  ],
);

ChapterPage _milestonesPage(String title, List<Milestone> ms, {required bool metric}) {
  final shown = ms.take(kMilestonesPerPage).toList();
  final rest = ms.length - shown.length;
  return ChapterPage(
    kind: ChapterPageKind.milestones,
    title: title,
    lines: [
      for (final m in shown) milestoneLabel(m, metric: metric),
      if (rest > 0) 'E mais ${_plural(rest, 'marco', 'marcos')}.',
    ],
  );
}

const String kRestartMessage = 'Sua sequencia recomeca agora. Uma semana de cada vez.';

String _streakLine(int current, bool restarted) {
  if (restarted || current == 0) return kRestartMessage;
  return current == 1
      ? 'Primeira semana da sua sequencia. Uma semana de cada vez.'
      : 'Voce esta ha ${_weeks(current)} seguidas em movimento.';
}

/// Paginas do capitulo do mes: de 4 a 6 (abertura, totais, esportes se houver
/// mais de um, a mais longa, marcos se houver, fechamento). Mes vazio: 2
/// paginas curtas e gentis.
List<ChapterPage> monthChapterPages(
  MonthChapter c, {
  required bool gentle,
  required bool metric,
}) {
  final name = monthName(c.month.month);
  final nextName = monthName(c.month.next.month);
  final streak = c.streak.current;
  final restarted = c.streak.restarted;

  if (c.isEmpty) {
    return [
      ChapterPage(
        kind: ChapterPageKind.opening,
        title: name,
        lines: ['$name foi de descanso. $nextName comeca agora.'],
      ),
      ChapterPage(
        kind: ChapterPageKind.closing,
        title: 'Ate o proximo capitulo',
        stats: [
          if (streak > 0)
            ChapterStat(label: 'Sequencia semanal', value: _weeks(streak), role: ChapterStatRole.streak),
        ],
        lines: [_streakLine(streak, restarted), 'Descansar tambem faz parte.'],
      ),
    ];
  }

  final pace = c.runPaceSecondsPerMeter;
  final longest = c.longest!;
  return [
    ChapterPage(
      kind: ChapterPageKind.opening,
      title: name,
      lines: ['Seu capitulo de ${c.month.year}.', 'Numeros e primeiras vezes do mes.'],
    ),
    ChapterPage(
      kind: ChapterPageKind.totals,
      title: 'Seu mes em numeros',
      stats: [
        ..._totalStats(c.totals, metric: metric),
        if (!gentle && pace != null)
          ChapterStat(
            label: 'Pace medio da corrida',
            value: formatPace(pace, metric: metric),
            role: ChapterStatRole.pace,
          ),
      ],
    ),
    if (c.sports.length > 1) _sportsPage(c.sports, metric: metric),
    ChapterPage(
      kind: ChapterPageKind.highlight,
      title: 'O treino mais longo',
      lines: ['Foi ${_articleSport(longest.type)}.'],
      stats: [
        ChapterStat(
          label: 'Distancia',
          value: formatDistance(longest.distanceMeters, metric: metric),
          role: ChapterStatRole.distance,
        ),
        ChapterStat(label: 'Tempo', value: formatDuration(longest.timerMs), role: ChapterStatRole.time),
      ],
    ),
    if (c.milestones.isNotEmpty) _milestonesPage('Primeiras vezes', c.milestones, metric: metric),
    ChapterPage(
      kind: ChapterPageKind.closing,
      title: 'Ate o proximo capitulo',
      stats: [
        if (streak > 0) ...[
          ChapterStat(label: 'Sequencia semanal', value: _weeks(streak), role: ChapterStatRole.streak),
          ChapterStat(label: 'Coringas usados', value: '${c.jokersUsed.length}', role: ChapterStatRole.joker),
        ],
      ],
      lines: [_streakLine(streak, restarted), 'Que venha ${nextName.toLowerCase()}.'],
    ),
  ];
}

/// Paginas do capitulo do ano: abertura, totais, esportes se houver mais de
/// um, melhor mes, marcos se houver, fechamento com a maior sequencia.
List<ChapterPage> yearChapterPages(
  YearChapter c, {
  required bool gentle,
  required bool metric,
}) {
  final title = '${c.year}';
  final streak = c.streak.current;
  final closingStats = [
    ChapterStat(label: 'Maior sequencia', value: _weeks(c.longestStreak), role: ChapterStatRole.streak),
    if (c.partial)
      ChapterStat(label: 'Sequencia atual', value: _weeks(streak), role: ChapterStatRole.streak),
  ];
  if (c.isEmpty) {
    return [
      ChapterPage(
        kind: ChapterPageKind.opening,
        title: title,
        lines: [
          c.partial ? '$title ate agora foi de descanso.' : '$title foi de descanso.',
          'O proximo treino comeca quando voce quiser.',
        ],
      ),
      ChapterPage(
        kind: ChapterPageKind.closing,
        title: 'Ate o proximo capitulo',
        lines: const ['Descansar tambem faz parte.'],
      ),
    ];
  }
  final best = c.bestMonth!;
  final bestTotals = c.bestMonthTotals!;
  return [
    ChapterPage(
      kind: ChapterPageKind.opening,
      title: title,
      lines: [c.partial ? 'Seu ano ate agora.' : 'Seu ano no Rastro.'],
    ),
    ChapterPage(
      kind: ChapterPageKind.totals,
      title: 'Seu ano em numeros',
      stats: _totalStats(c.totals, metric: metric),
    ),
    if (c.sports.length > 1) _sportsPage(c.sports, metric: metric),
    ChapterPage(
      kind: ChapterPageKind.bestMonth,
      title: 'Seu melhor mes',
      lines: const ['O mes com mais tempo em movimento.'],
      stats: [
        ChapterStat(label: 'Mes', value: monthName(best.month), role: ChapterStatRole.month),
        ChapterStat(
          label: 'Tempo em movimento',
          value: formatDuration(bestTotals.timerMs),
          role: ChapterStatRole.time,
        ),
        ChapterStat(label: 'Treinos', value: '${bestTotals.count}', role: ChapterStatRole.count),
        ChapterStat(
          label: 'Distancia',
          value: formatDistance(bestTotals.distanceMeters, metric: metric),
          role: ChapterStatRole.distance,
        ),
      ],
    ),
    if (c.milestones.isNotEmpty)
      _milestonesPage('Primeiras vezes do ano', c.milestones, metric: metric),
    ChapterPage(
      kind: ChapterPageKind.closing,
      title: 'Ate o proximo capitulo',
      stats: closingStats,
      lines: [
        if (c.partial) _streakLine(streak, c.streak.restarted) else 'Que venha ${c.year + 1}.',
      ],
    ),
  ];
}

List<ChapterStat> _shareStats(ChapterTotals t, {required bool metric}) => [
  ChapterStat(
    label: 'Distancia',
    value: formatDistance(t.distanceMeters, metric: metric),
    role: ChapterStatRole.distance,
  ),
  ChapterStat(label: 'Tempo', value: formatDuration(t.timerMs), role: ChapterStatRole.time),
  ChapterStat(label: 'Treinos', value: '${t.count}', role: ChapterStatRole.count),
  ChapterStat(label: 'Dias ativos', value: '${t.activeDays}', role: ChapterStatRole.days),
];

String _shareText(String heading, ChapterTotals t, {required bool metric}) => t.isEmpty
    ? 'Meu capitulo de $heading no Rastro: um tempo de descanso.'
    : 'Meu capitulo de $heading no Rastro: '
          '${formatDistance(t.distanceMeters, metric: metric)}, '
          '${_workouts(t.count)}, ${formatDuration(t.timerMs)} em movimento.';

/// Imagem do capitulo do mes: totais e ate 3 marcos (nunca pace: a imagem
/// sai igual com e sem o Modo Gentil).
ChapterShareData monthShareData(MonthChapter c, {required bool metric}) {
  final heading = '${monthName(c.month.month)} de ${c.month.year}';
  return ChapterShareData(
    heading: heading,
    subheading: 'Meu capitulo',
    stats: _shareStats(c.totals, metric: metric),
    milestones: [
      for (final m in topMilestones(c.milestones, kShareMilestones)) milestoneLabel(m, metric: metric),
    ],
    text: _shareText(heading.toLowerCase(), c.totals, metric: metric),
  );
}

/// Imagem do capitulo do ano.
ChapterShareData yearShareData(YearChapter c, {required bool metric}) {
  final heading = c.partial ? '${c.year} ate agora' : '${c.year}';
  return ChapterShareData(
    heading: heading,
    subheading: 'Meu ano',
    stats: _shareStats(c.totals, metric: metric),
    milestones: [
      for (final m in topMilestones(c.milestones, kShareMilestones)) milestoneLabel(m, metric: metric),
    ],
    text: _shareText('${c.year}', c.totals, metric: metric),
  );
}
