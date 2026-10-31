// Resumo da semana do Inicio (relatorio 11, WeekSummaryCard): "Esta semana",
// contagem de treinos com uma faixa segmentada pelo esporte de cada treino, tres
// metricas (distancia, tempo, subida) e barras por dia na cor do esporte do dia.
// Ainda nao ha meta de treinos no app: mostra so a contagem.
library;

import 'package:flutter/material.dart';

import '../../activity/week_summary.dart';
import '../../core/format/measures.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'metric_tile.dart';

/// Iniciais dos dias, de segunda a domingo.
const List<String> kWeekdayInitials = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];

/// "Nenhum treino", "1 treino", "3 treinos".
String workoutCountLabel(int n) => switch (n) {
      0 => 'Nenhum treino',
      1 => '1 treino',
      _ => '$n treinos',
    };

class WeekSummaryCard extends StatelessWidget {
  final WeekSummary summary;
  final bool useMetric;

  /// Dia de hoje (0 = segunda), destacado no rotulo; null para nenhum.
  final int? todayIndex;

  const WeekSummaryCard({
    super.key,
    required this.summary,
    required this.useMetric,
    this.todayIndex,
  });

  static const double _barMaxHeight = 56;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final (dist, distUnit) = splitMeasure(formatDistance(summary.distanceMeters, metric: useMetric));
    final (gain, gainUnit) = splitMeasure(formatElevation(summary.elevationGainMeters, metric: useMetric));
    final maxMs = summary.maxDayTimerMs;

    return Container(
      key: const Key('week_summary'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppShape.card),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Esta semana', style: AppText.sectionTitle.copyWith(color: c.text)),
              ),
              Text(
                workoutCountLabel(summary.count),
                key: const Key('week_count'),
                style: AppText.label.copyWith(color: c.textMuted),
              ),
            ],
          ),
          if (summary.count > 0) ...[
            const SizedBox(height: 10),
            // Um segmento por treino, na cor do esporte.
            SizedBox(
              height: 6,
              child: Row(
                children: [
                  for (var i = 0; i < summary.workouts.length; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: c.sport(summary.workouts[i]).fill,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: MetricTile(
                  key: const Key('week_distance'),
                  label: 'Distância',
                  value: dist,
                  unit: distUnit,
                  role: c.dist,
                  valueStyle: AppText.metricM,
                ),
              ),
              Expanded(
                child: MetricTile(
                  key: const Key('week_time'),
                  label: 'Tempo',
                  value: formatDuration(summary.timerTimeMs),
                  role: c.tempo,
                  valueStyle: AppText.metricM,
                ),
              ),
              Expanded(
                child: MetricTile(
                  key: const Key('week_gain'),
                  label: 'Subida',
                  value: gain,
                  unit: gainUnit,
                  role: c.subida,
                  valueStyle: AppText.metricM,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final d in summary.days)
                Expanded(
                  child: Column(
                    key: Key('week_day_${d.index}'),
                    children: [
                      SizedBox(
                        height: _barMaxHeight,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: 14,
                            // Dia sem treino vira um trilho baixo em surface2.
                            height: d.isEmpty || maxMs <= 0
                                ? 6
                                : (6 + (_barMaxHeight - 6) * d.timerTimeMs / maxMs),
                            decoration: BoxDecoration(
                              color: d.isEmpty ? c.surface2 : c.sport(d.mainType!).fill,
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        kWeekdayInitials[d.index],
                        style: AppText.label.copyWith(
                          color: d.index == todayIndex ? c.text : c.textMuted,
                          fontWeight: d.index == todayIndex ? FontWeight.w700 : null,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
