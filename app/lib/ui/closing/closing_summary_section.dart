// Fechamento gentil (F04) no Detalhe: esforco percebido com o rotulo da
// faixa, carga do treino (sRPE = RPE x minutos) e humor. Some quando nenhum
// dos dois foi informado.
library;

import 'package:flutter/material.dart';

import '../../closing/domain/effort.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'effort_picker.dart';

class ClosingSummarySection extends StatelessWidget {
  final int? rpe;
  final Mood? mood;
  final int timerMs;

  const ClosingSummarySection({
    super.key,
    required this.rpe,
    required this.mood,
    required this.timerMs,
  });

  /// Ha algo para mostrar.
  static bool hasData(int? rpe, Mood? mood) => isValidRpe(rpe) || mood != null;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final r = normalizeRpe(rpe);
    final m = mood;
    final load = trainingLoad(rpe: r, timerMs: timerMs);
    final muted = AppText.label.copyWith(color: c.textMuted);

    Widget block(Key key, RoleColors role, List<Widget> children) => Expanded(
      child: Container(
        key: key,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: role.tint,
          borderRadius: BorderRadius.circular(AppShape.tile),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );

    final blocks = <Widget>[
      if (r != null)
        block(const Key('detailEffort'), c.extra, [
          Text('Esforco', style: muted),
          const SizedBox(height: 4),
          Text('$r', style: AppText.metricM.copyWith(color: c.extra.fg)),
          Text(rpeLabel(r), key: const Key('detailEffortLabel'), style: muted),
        ]),
      if (load != null)
        block(const Key('detailLoad'), c.extra, [
          Text('Carga', style: muted),
          const SizedBox(height: 4),
          Text('$load', style: AppText.metricM.copyWith(color: c.extra.fg)),
          Text('RPE x min', style: muted),
        ]),
      if (m != null)
        block(const Key('detailMood'), c.ciano, [
          Text('Humor', style: muted),
          const SizedBox(height: 4),
          Icon(moodIcon(m), color: c.ciano.fg, size: 28),
          Text(m.label, style: AppText.bodyStrong.copyWith(color: c.ciano.fg)),
        ]),
    ];
    if (blocks.isEmpty) return const SizedBox.shrink();
    return IntrinsicHeight(
      key: const Key('detailClosing'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < blocks.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            blocks[i],
          ],
        ],
      ),
    );
  }
}
