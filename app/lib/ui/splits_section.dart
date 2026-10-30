// Parciais por km (ou milha) no detalhe: uma SplitBar por trecho, com a
// distancia e o tempo embaixo e o pace na cor do papel da parcial.
library;

import 'package:flutter/material.dart';

import '../core/format/measures.dart';
import '../recording/domain/splits.dart';
import '../recording/domain/splits_from_waypoints.dart';
import 'components/split_bar.dart';
import 'theme/app_colors.dart';
import 'theme/app_typography.dart';

class SplitsSection extends StatelessWidget {
  final List<ActiveSplit> splits;
  final bool metric;

  /// Modo Gentil (F04): sem pace e sem cores de mais rapido ou mais lento;
  /// cada trecho mostra distancia e tempo.
  final bool gentle;

  const SplitsSection({
    super.key,
    required this.splits,
    required this.metric,
    this.gentle = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final raw = splitBarSpecs([
      for (final s in splits) s.avgSpeedMetersPerSecond,
    ]);
    // Gentil: barras so pelo tamanho, todas na cor normal.
    final specs = gentle
        ? [for (final s in raw) SplitBarSpec(s.fraction, SplitRank.normal)]
        : raw;
    final ranked = specs.any((s) => s.rank != SplitRank.normal);
    return Column(
      key: const Key('splitsSection'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          metric ? 'Splits por km' : 'Splits por milha',
          style: AppText.sectionTitle.copyWith(color: c.text),
        ),
        if (ranked) ...[const SizedBox(height: 8), const SplitBarLegend()],
        const SizedBox(height: 8),
        if (splits.isEmpty)
          Text(
            'Sem splits nesta atividade.',
            style: AppText.body.copyWith(color: c.textMuted),
          )
        else
          for (var i = 0; i < splits.length; i++) _row(c, splits[i], specs[i]),
      ],
    );
  }

  /// O ultimo trecho pode ser parcial (nao fechou a marca); e exibido com o
  /// rotulo "parcial" em vez de omitido, porque numa atividade curta ele seria
  /// a unica informacao de ritmo disponivel.
  Widget _row(AppColors c, ActiveSplit s, SplitBarSpec spec) {
    final muted = AppText.label.copyWith(color: c.textMuted);
    // Trecho fechado: mostra a marca atingida (1 km, 2 km, ...). Trecho
    // parcial: nao ha marca, entao mostra a distancia percorrida nele.
    final distancia = s.complete ? s.endDistanceMeters : s.distanceMeters;
    final role = splitRankRole(c, spec.rank);
    return Padding(
      key: Key('split-${s.number}'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${s.number}',
                    style: AppText.metricS.copyWith(color: c.text),
                  ),
                  if (!s.complete) TextSpan(text: ' (parcial)', style: muted),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SplitBar(spec: spec),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      formatDistance(distancia, metric: metric),
                      style: muted,
                    ),
                    const SizedBox(width: 10),
                    Text(formatDuration(s.durationMs), style: muted),
                  ],
                ),
              ],
            ),
          ),
          if (!gentle)
            SizedBox(
              width: 92,
              child: Text(
                formatPace(splitPaceSecondsPerMeter(s), metric: metric),
                textAlign: TextAlign.end,
                style: AppText.metricS.copyWith(color: role.fg),
              ),
            ),
        ],
      ),
    );
  }
}
