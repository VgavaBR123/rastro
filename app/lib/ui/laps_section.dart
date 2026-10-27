// Lista de voltas no detalhe da atividade: numero numa pilula tingida,
// distancia, tempo e pace na cor de cada funcao.
library;

import 'package:flutter/material.dart';

import '../activity/lap_summary.dart';
import '../core/format/measures.dart';
import 'theme/app_colors.dart';
import 'theme/app_typography.dart';

class LapsSection extends StatelessWidget {
  final List<LapSummary> laps;
  final bool metric;

  const LapsSection({super.key, required this.laps, required this.metric});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      key: const Key('lapsSection'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Voltas', style: AppText.sectionTitle.copyWith(color: c.text)),
        const SizedBox(height: 8),
        for (var i = 0; i < laps.length; i++) ...[
          if (i > 0) Divider(height: 1, color: c.line),
          _row(c, laps[i]),
        ],
      ],
    );
  }

  Widget _row(AppColors c, LapSummary l) => Padding(
    key: Key('lap-${l.number}'),
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Container(
          height: 26,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: c.surface2,
            shape: const StadiumBorder(),
          ),
          child: Text(
            'Volta ${l.number}',
            style: AppText.label.copyWith(color: c.text),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            formatDistance(l.distanceMeters, metric: metric),
            style: AppText.metricS.copyWith(color: c.dist.fg),
          ),
        ),
        SizedBox(
          width: 64,
          child: Text(
            formatDuration(l.durationMs),
            textAlign: TextAlign.end,
            style: AppText.metricS.copyWith(color: c.tempo.fg),
          ),
        ),
        SizedBox(
          width: 96,
          child: Text(
            formatPace(l.paceSecondsPerMeter, metric: metric),
            textAlign: TextAlign.end,
            style: AppText.metricS.copyWith(color: c.pace.fg),
          ),
        ),
      ],
    ),
  );
}
