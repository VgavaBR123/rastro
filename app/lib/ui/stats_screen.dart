// Estatisticas (aba Estatisticas): totais do periodo em blocos tingidos,
// tempo por semana nas ultimas 8 semanas empilhado por esporte e a
// distribuicao do periodo por esporte.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../activity/stats_summary.dart';
import '../app/providers.dart';
import '../core/format/activity_labels.dart';
import '../core/format/measures.dart';
import '../recording/domain/recording_models.dart';
import 'components/app_nav_bar.dart';
import 'components/metric_tile.dart';
import 'components/segmented_selector.dart';
import 'section_card.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'theme/app_typography.dart';

/// Periodo escolhido na tela (sobrevive a troca de aba).
final statsPeriodProvider = StateProvider<StatsPeriod>(
  (_) => StatsPeriod.month,
);

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final stats = ref.watch(statsProvider);
    final period = ref.watch(statsPeriodProvider);
    final metric = ref.watch(settingsProvider).useMetric;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          key: const Key('stats_list'),
          padding: EdgeInsets.fromLTRB(
            AppShape.gutter,
            0,
            AppShape.gutter,
            AppNavBar.reservedHeight(context),
          ),
          children: [
            const ScreenTitle(
              'Estatísticas',
              subtitle: 'Seus treinos gravados neste aparelho',
            ),
            SegmentedSelector<StatsPeriod>(
              key: const Key('stats_period'),
              selected: period,
              onChanged: (p) =>
                  ref.read(statsPeriodProvider.notifier).state = p,
              options: [
                SegmentOption(
                  value: StatsPeriod.week,
                  label: 'Semana',
                  role: c.subida,
                  key: const Key('stats_period_week'),
                ),
                SegmentOption(
                  value: StatsPeriod.month,
                  label: '4 semanas',
                  role: c.subida,
                  key: const Key('stats_period_month'),
                ),
                SegmentOption(
                  value: StatsPeriod.eightWeeks,
                  label: '8 semanas',
                  role: c.subida,
                  key: const Key('stats_period_8w'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...switch (stats) {
              AsyncData(:final value) => _content(
                context,
                value.summary,
                period,
                metric,
              ),
              AsyncError() => [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Não foi possível ler as estatísticas',
                    key: const Key('stats_error'),
                    textAlign: TextAlign.center,
                    style: AppText.body.copyWith(color: c.danger),
                  ),
                ),
              ],
              _ => const [
                Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
            },
          ],
        ),
      ),
    );
  }

  List<Widget> _content(
    BuildContext context,
    StatsSummary s,
    StatsPeriod period,
    bool metric,
  ) {
    final totals = s.totals(period);
    return [
      StatsTotalsGrid(totals: totals, metric: metric, keyPrefix: 'stats_total'),
      const SizedBox(height: 20),
      SectionCard(
        title: 'Tempo por semana',
        padding: const EdgeInsets.all(16),
        child: WeeklyStackedChart(summary: s, highlightWeeks: period.weeks),
      ),
      SectionCard(
        title: 'Por esporte',
        padding: const EdgeInsets.all(16),
        child: _SportDistribution(
          shares: s.distribution(period),
          metric: metric,
        ),
      ),
    ];
  }
}

/// Quatro totais em blocos tingidos: distancia, tempo, subida e treinos.
class StatsTotalsGrid extends StatelessWidget {
  final StatTotals totals;
  final bool metric;

  /// Prefixo das Keys dos blocos (`<prefix>_distance`, `_time`, `_gain`, `_count`).
  final String keyPrefix;

  const StatsTotalsGrid({
    super.key,
    required this.totals,
    required this.metric,
    required this.keyPrefix,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final (dist, distUnit) = splitMeasure(
      formatDistance(totals.distanceMeters, metric: metric),
    );
    final (gain, gainUnit) = splitMeasure(
      formatElevation(totals.elevationGainMeters, metric: metric),
    );
    final (time, timeUnit) = splitMeasure(
      formatTotalDuration(totals.timerTimeMs),
    );
    Widget tile(
      String key,
      String label,
      String value,
      String? unit,
      RoleColors role,
    ) => Expanded(
      // Um elemento de acessibilidade por bloco, com rotulo e valor falado
      // (EST-07); sem isso a grade inteira virava um no so.
      child: Semantics(
        container: true,
        label: label,
        value: spokenMeasure([value, ?unit].join(' ')),
        excludeSemantics: true,
        child: MetricTile(
          key: Key('${keyPrefix}_$key'),
          label: label,
          value: value,
          unit: unit,
          role: role,
          block: true,
          valueStyle: AppText.metricM,
        ),
      ),
    );
    return Column(
      children: [
        Row(
          children: [
            tile('distance', 'Distância', dist, distUnit, c.dist),
            const SizedBox(width: 10),
            tile('time', 'Tempo', time, timeUnit, c.tempo),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            tile('gain', 'Subida', gain, gainUnit, c.subida),
            const SizedBox(width: 10),
            tile('count', 'Treinos', '${totals.count}', null, c.extra),
          ],
        ),
      ],
    );
  }
}

/// Barras de tempo por semana, empilhadas por esporte (corrida embaixo,
/// depois pedal e caminhada). As [highlightWeeks] mais recentes ficam cheias;
/// as de fora do periodo escolhido, apagadas.
class WeeklyStackedChart extends StatelessWidget {
  final StatsSummary summary;
  final int highlightWeeks;
  final double height;

  const WeeklyStackedChart({
    super.key,
    required this.summary,
    this.highlightWeeks = kStatsWeeks,
    this.height = 150,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final weeks = summary.weeks;
    final max = summary.maxWeekTimerMs;
    final muted = AppText.label.copyWith(color: c.textMuted);
    final used = [
      for (final t in ActivityType.values)
        if (weeks.any((w) => (w.timerMsBySport[t] ?? 0) > 0)) t,
    ];
    String two(int n) => n.toString().padLeft(2, '0');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          container: true,
          label: 'Maior semana',
          value: spokenMeasure(formatTotalDuration(max)),
          excludeSemantics: true,
          child: Row(
            children: [
              Text('Maior semana', style: muted),
              const Spacer(),
              Text(
                formatTotalDuration(max),
                key: const Key('stats_chart_max'),
                style: AppText.metricS.copyWith(color: c.tempo.fg),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Semantics(
          container: true,
          label: 'Tempo por semana nas últimas ${weeks.length} semanas',
          value: [
            for (final w in weeks)
              '${two(w.start.day)}/${two(w.start.month)}: ${spokenMeasure(formatTotalDuration(w.totalTimerMs))}',
          ].join(', '),
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: CustomPaint(
              key: const Key('stats_week_chart'),
              painter: WeekBarsPainter(
                weeks: weeks,
                maxTimerMs: max,
                colors: {
                  for (final t in ActivityType.values) t: c.sport(t).fill,
                },
                gridColor: c.line,
                emptyColor: c.surface2,
                highlightFrom: weeks.length - highlightWeeks,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final w in weeks)
              Expanded(
                child: Text(
                  '${two(w.start.day)}/${two(w.start.month)}',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: AppText.navLabel.copyWith(color: c.textMuted),
                ),
              ),
          ],
        ),
        if (used.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              for (final t in used)
                _LegendDot(color: c.sport(t).fill, label: activityTypeLabel(t)),
            ],
          ),
        ],
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppText.label.copyWith(color: c.textMuted)),
      ],
    );
  }
}

/// Desenha as barras empilhadas. Publico para os testes conferirem as
/// alturas sem depender de pixels.
class WeekBarsPainter extends CustomPainter {
  final List<WeekBar> weeks;
  final int maxTimerMs;
  final Map<ActivityType, Color> colors;
  final Color gridColor;
  final Color emptyColor;

  /// Indice da primeira semana dentro do periodo escolhido.
  final int highlightFrom;

  WeekBarsPainter({
    required this.weeks,
    required this.maxTimerMs,
    required this.colors,
    required this.gridColor,
    required this.emptyColor,
    this.highlightFrom = 0,
  });

  /// Altura de cada fatia (corrida, pedal, caminhada) de uma semana, para
  /// uma area de [chartHeight].
  static List<(ActivityType, double)> segments(
    WeekBar w,
    int maxTimerMs,
    double chartHeight,
  ) {
    if (maxTimerMs <= 0) return const [];
    return [
      for (final t in ActivityType.values)
        if ((w.timerMsBySport[t] ?? 0) > 0)
          (t, w.timerMsBySport[t]! / maxTimerMs * chartHeight),
    ];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    if (weeks.isEmpty) return;
    final slot = size.width / weeks.length;
    final barWidth = slot * 0.56;
    const radius = Radius.circular(6);
    for (var i = 0; i < weeks.length; i++) {
      final left = slot * i + (slot - barWidth) / 2;
      final segs = segments(weeks[i], maxTimerMs, size.height);
      if (segs.isEmpty) {
        // Semana sem treino: um traco baixo para manter o ritmo do eixo.
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(left, size.height - 4, barWidth, 4),
            radius,
          ),
          Paint()..color = emptyColor,
        );
        continue;
      }
      final total = segs.fold(0.0, (a, s) => a + s.$2);
      final bar = RRect.fromRectAndCorners(
        Rect.fromLTWH(left, size.height - total, barWidth, total),
        topLeft: radius,
        topRight: radius,
      );
      final alpha = i >= highlightFrom ? 1.0 : 0.35;
      canvas.save();
      canvas.clipRRect(bar);
      var bottom = size.height;
      for (final (type, h) in segs) {
        canvas.drawRect(
          Rect.fromLTWH(left, bottom - h, barWidth, h),
          Paint()..color = colors[type]!.withValues(alpha: alpha),
        );
        bottom -= h;
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(WeekBarsPainter old) =>
      old.weeks != weeks ||
      old.maxTimerMs != maxTimerMs ||
      old.highlightFrom != highlightFrom ||
      old.gridColor != gridColor ||
      old.emptyColor != emptyColor ||
      old.colors.toString() != colors.toString();
}

/// Barra unica dividida por esporte e uma linha por esporte.
class _SportDistribution extends StatelessWidget {
  final List<SportShare> shares;
  final bool metric;
  const _SportDistribution({required this.shares, required this.metric});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    if (shares.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Nenhum treino neste período',
          key: const Key('stats_empty'),
          style: AppText.body.copyWith(color: c.textMuted),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: SizedBox(
            height: 14,
            // stretch: sem ele a Row repassa altura frouxa e o ColoredBox sem
            // filho fica com 0 px (EST-01).
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final s in shares)
                  Expanded(
                    key: Key('stats_sport_bar_${s.type.name}'),
                    flex: (s.fraction * 1000).round().clamp(1, 1000),
                    child: ColoredBox(color: c.sport(s.type).fill),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (final s in shares) _SportRow(share: s, metric: metric),
      ],
    );
  }
}

class _SportRow extends StatelessWidget {
  final SportShare share;
  final bool metric;
  const _SportRow({required this.share, required this.metric});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final role = c.sport(share.type);
    final t = share.totals;
    final count = t.count == 1 ? '1 treino' : '${t.count} treinos';
    final dist = formatDistance(t.distanceMeters, metric: metric);
    final time = formatTotalDuration(t.timerTimeMs);
    final percent = (share.fraction * 100).round();
    return Semantics(
      container: true,
      label: activityTypeLabel(share.type),
      value:
          '$count, ${spokenMeasure(dist)}, ${spokenMeasure(time)}, '
          '$percent por cento',
      excludeSemantics: true,
      child: Padding(
        key: Key('stats_sport_${share.type.name}'),
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: role.fill,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activityTypeLabel(share.type),
                    style: AppText.bodyStrong.copyWith(color: c.text),
                  ),
                  Text(
                    '$count · $dist · $time',
                    style: AppText.label.copyWith(color: c.textMuted),
                  ),
                ],
              ),
            ),
            Text('$percent%', style: AppText.metricS.copyWith(color: role.fg)),
          ],
        ),
      ),
    );
  }
}
