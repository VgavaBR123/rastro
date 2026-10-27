// Lista de voltas no detalhe da atividade.
library;

import 'package:flutter/material.dart';

import '../activity/lap_summary.dart';
import '../core/format/measures.dart';

class LapsSection extends StatelessWidget {
  final List<LapSummary> laps;
  final bool metric;

  const LapsSection({super.key, required this.laps, required this.metric});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('lapsSection'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Voltas',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        for (final l in laps) _row(l),
      ],
    );
  }

  Widget _row(LapSummary l) => Padding(
    key: Key('lap-${l.number}'),
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        SizedBox(
          width: 84,
          child: Text(
            'Volta ${l.number}',
            style: const TextStyle(fontSize: 16),
          ),
        ),
        Expanded(
          child: Text(
            formatDistance(l.distanceMeters, metric: metric),
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        SizedBox(
          width: 72,
          child: Text(formatDuration(l.durationMs), textAlign: TextAlign.end),
        ),
        SizedBox(
          width: 96,
          child: Text(
            formatPace(l.paceSecondsPerMeter, metric: metric),
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}
