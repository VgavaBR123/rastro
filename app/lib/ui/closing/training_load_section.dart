// Carga do treino (F04) na aba Estatisticas: total do periodo (soma do sRPE
// = esforco x minutos) e uma barra por semana nas ultimas 8. Sem nenhum
// treino com esforco informado, explica como comecar.
library;

import 'package:flutter/material.dart';

import '../../activity/stats_summary.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class TrainingLoadSection extends StatelessWidget {
  final StatsSummary summary;
  final StatsPeriod period;
  final double height;

  const TrainingLoadSection({
    super.key,
    required this.summary,
    required this.period,
    this.height = 96,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final muted = AppText.label.copyWith(color: c.textMuted);
    if (!summary.hasLoad) {
      return Text(
        'Marque o esforco percebido ao salvar um treino para ver a carga '
        '(esforco x minutos) de cada semana.',
        key: const Key('stats_load_empty'),
        style: AppText.body.copyWith(color: c.textMuted),
      );
    }
    final weeks = summary.weeks;
    final max = summary.maxWeekLoad;
    final highlightFrom = weeks.length - period.weeks;
    String two(int n) => n.toString().padLeft(2, '0');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: Text('Carga no periodo', style: muted)),
            Text(
              '${summary.loadTotal(period)}',
              key: const Key('stats_load_total'),
              style: AppText.metricM.copyWith(color: c.extra.fg),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Semantics(
          label: 'Carga por semana nas ultimas ${weeks.length} semanas',
          value: [
            for (final w in weeks) '${two(w.start.day)}/${two(w.start.month)}: ${w.load}',
          ].join(', '),
          child: SizedBox(
            height: height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < weeks.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: weeks[i].load > 0 && max > 0
                          ? Container(
                              key: Key('stats_load_week_$i'),
                              height: height * weeks[i].load / max,
                              decoration: BoxDecoration(
                                color: i >= highlightFrom ? c.extra.fill : c.extra.tint,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                              ),
                            )
                          : Container(height: 2, color: c.line),
                    ),
                  ),
              ],
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
        const SizedBox(height: 8),
        Text('Esforco (1 a 10) x minutos de cada treino.', style: muted),
      ],
    );
  }
}
