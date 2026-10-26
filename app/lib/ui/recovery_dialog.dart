// Recuperacao pos-crash na subida do app: oferece retomar, salvar ou descartar
// uma atividade que ficou sem finalizar. Clean room a partir de
// relatorios/05-persistencia.md (recuperacao apos crash).
library;

import 'package:flutter/material.dart';

import '../core/format/activity_labels.dart';
import '../core/format/measures.dart';
import '../persistence/recording_repository.dart';

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
    builder: (ctx) => AlertDialog(
      key: const Key('recovery_dialog'),
      title: const Text('Atividade interrompida'),
      content: Text(
        '${activityTypeLabel(a.activityType)} iniciada em '
        '${formatDateTimeMs(a.startTimestampMs)} nao foi encerrada.\n\n'
        'Salvo ate agora: ${formatDistance(it.distanceMeters, metric: metric)} '
        'em ${formatDuration(it.timerMs)}.',
      ),
      actions: [
        TextButton(
          key: const Key('recovery_discard'),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          onPressed: () => Navigator.of(ctx).pop(RecoveryChoice.discard),
          child: const Text('Descartar'),
        ),
        if (hasPoints)
          TextButton(
            key: const Key('recovery_save'),
            onPressed: () => Navigator.of(ctx).pop(RecoveryChoice.save),
            child: const Text('Salvar'),
          ),
        if (allowResume)
          FilledButton(
            key: const Key('recovery_resume'),
            onPressed: () => Navigator.of(ctx).pop(RecoveryChoice.resume),
            child: const Text('Retomar'),
          ),
      ],
    ),
  );
}
