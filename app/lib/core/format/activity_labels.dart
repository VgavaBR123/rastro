// Rotulos de apresentacao para tipos de atividade.
library;

import '../../recording/domain/recording_models.dart';

String activityTypeLabel(ActivityType t) {
  switch (t) {
    case ActivityType.run:
      return 'Corrida';
    case ActivityType.ride:
      return 'Pedal';
    case ActivityType.walk:
      return 'Caminhada';
  }
}

/// Estado de sincronizacao como o usuario le.
String syncStateLabel(SyncState s) {
  switch (s) {
    case SyncState.recording:
      return 'Gravando';
    case SyncState.pending:
      return 'Aguardando envio';
    case SyncState.uploading:
      return 'Enviando';
    case SyncState.synced:
      return 'Sincronizada';
    case SyncState.failed:
      return 'Falhou (sera tentada de novo)';
  }
}

/// Data curta "dd/mm/aaaa hh:mm" a partir de epoch ms (sem dependencia de intl).
String formatDateTimeMs(int epochMs) {
  final d = DateTime.fromMillisecondsSinceEpoch(epochMs);
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
}
