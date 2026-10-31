// Recuperacao pos-crash na subida do app: oferece retomar, salvar ou descartar
// uma atividade que ficou sem finalizar. Clean room a partir de
// relatorios/05-persistencia.md (recuperacao apos crash).
library;

import 'package:flutter/material.dart';

import '../core/format/activity_labels.dart';
import '../core/format/measures.dart';
import '../persistence/recording_repository.dart';
import 'components/big_action_button.dart';
import 'components/metric_tile.dart';
import 'components/sport_chip.dart';
import 'theme/app_colors.dart';
import 'theme/app_typography.dart';

/// Depois disso a atividade interrompida nao pode mais ser retomada, so salva ou
/// descartada: continuar uma corrida de horas atras misturaria duas saidas.
const Duration kMaxResumeGap = Duration(hours: 2);

enum RecoveryChoice { resume, save, discard }

/// Se ainda da para retomar: o ultimo ponto salvo (ou o inicio, sem pontos)
/// esta dentro de [kMaxResumeGap] de [nowMs].
bool canResume(InterruptedActivity it, int nowMs) {
  final lastMs = it.activity.startTimestampMs + it.elapsedMs;
  return nowMs - lastMs <= kMaxResumeGap.inMilliseconds;
}

Future<RecoveryChoice?> showRecoveryDialog(
  BuildContext context,
  InterruptedActivity it, {
  required bool metric,
  required bool allowResume,
}) {
  final a = it.activity;
  final hasPoints = it.acceptedPoints.isNotEmpty;
  return showDialog<RecoveryChoice>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final c = AppColors.of(ctx);
      void pick(RecoveryChoice v) => Navigator.of(ctx).pop(v);
      // A acao principal e Retomar quando da; senao Salvar.
      final saveIsMain = hasPoints && !allowResume;
      return AlertDialog(
        key: const Key('recovery_dialog'),
        icon: Icon(Icons.history_toggle_off_rounded, color: c.extra.fg, size: 32),
        title: const Text('Atividade interrompida'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: SportChip(type: a.activityType),
            ),
            const SizedBox(height: 10),
            Text(
              '${activityTypeLabel(a.activityType)} iniciada em '
              '${formatDateTimeMs(a.startTimestampMs)} não foi encerrada. '
              'Salvo até agora:',
              style: AppText.body.copyWith(color: c.textMuted),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MetricTile(
                    key: const Key('recovery_distance'),
                    label: 'Distância',
                    value: formatDistance(it.distanceMeters, metric: metric),
                    role: c.dist,
                    block: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: MetricTile(
                    key: const Key('recovery_duration'),
                    label: 'Tempo',
                    value: formatDuration(it.timerMs),
                    role: c.tempo,
                    block: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (allowResume)
              BigActionButton(
                key: const Key('recovery_resume'),
                label: 'Retomar',
                icon: Icons.play_arrow_rounded,
                variant: BigActionVariant.role,
                role: c.dist,
                height: 56,
                onPressed: () => pick(RecoveryChoice.resume),
              ),
            if (hasPoints) ...[
              if (allowResume) const SizedBox(height: 10),
              if (saveIsMain)
                BigActionButton(
                  key: const Key('recovery_save'),
                  label: 'Salvar',
                  icon: Icons.check_rounded,
                  height: 56,
                  onPressed: () => pick(RecoveryChoice.save),
                )
              else
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    key: const Key('recovery_save'),
                    onPressed: () => pick(RecoveryChoice.save),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Salvar como está'),
                  ),
                ),
            ],
            const SizedBox(height: 6),
            SizedBox(
              height: 48,
              child: TextButton.icon(
                key: const Key('recovery_discard'),
                style: TextButton.styleFrom(foregroundColor: c.danger),
                onPressed: () => pick(RecoveryChoice.discard),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Descartar'),
              ),
            ),
          ],
        ),
      );
    },
  );
}
