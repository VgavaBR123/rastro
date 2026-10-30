// Cartao "Saude da gravacao" (F01) do detalhe da atividade: quantas lacunas e
// quanto tempo sem dados, precisao media do GPS, pontos que o filtro de ruido
// descartou e a bateria gasta.
library;

import 'package:flutter/material.dart';

import '../core/format/measures.dart';
import '../recording/domain/recording_health.dart';
import 'theme/app_colors.dart';
import 'theme/app_typography.dart';

class RecordingHealthSection extends StatelessWidget {
  final RecordingHealth health;
  final bool metric;

  const RecordingHealthSection({
    super.key,
    required this.health,
    required this.metric,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final h = health;
    final acc = h.avgHorizontalAccuracyMeters;
    final battery = h.batteryUsedPercent;
    // Sem batimento (atividade antiga ou baixada) nao da para afirmar que
    // nao houve lacuna nem descarte.
    final known = h.monitored;
    const noData = 'Sem dados';
    return Column(
      key: const Key('recordingHealth'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              !known
                  ? Icons.info_outline_rounded
                  : h.hasGaps
                  ? Icons.warning_amber_rounded
                  : Icons.verified_rounded,
              color: !known
                  ? c.textMuted
                  : h.hasGaps
                  ? c.extra.fg
                  : c.dist.fg,
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Saude da gravacao',
                style: AppText.sectionTitle.copyWith(color: c.text),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _Row(
          label: 'Lacunas',
          value: !known
              ? noData
              : h.hasGaps
              ? '${h.gapCount} (${formatGapDuration(h.gapTotalMs)})'
              : 'Nenhuma',
          valueKey: const Key('healthGaps'),
          highlight: h.hasGaps ? c.extra.fg : null,
        ),
        _Row(
          label: 'Precisao media do GPS',
          value: acc == null
              ? 'Sem leitura'
              : formatElevation(acc, metric: metric),
          valueKey: const Key('healthAccuracy'),
        ),
        _Row(
          label: 'Pontos descartados pelo filtro',
          value: known ? '${h.discardedPoints}' : noData,
          valueKey: const Key('healthDiscarded'),
        ),
        _Row(
          label: 'Bateria gasta',
          value: battery == null ? 'Sem leitura' : '$battery%',
          valueKey: const Key('healthBattery'),
          last: true,
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Key valueKey;
  final Color? highlight;
  final bool last;

  const _Row({
    required this.label,
    required this.value,
    required this.valueKey,
    this.highlight,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: c.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppText.body.copyWith(color: c.textMuted),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            key: valueKey,
            style: AppText.metricS.copyWith(color: highlight ?? c.text),
          ),
        ],
      ),
    );
  }
}
