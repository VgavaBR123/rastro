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

/// Titulo pelo horario de inicio: manha de 5h a 11h, tarde de 12h a 17h,
/// noite no resto ("Corrida da manha").
String suggestedActivityTitle(ActivityType type, DateTime start) {
  final h = start.hour;
  final period = h >= 5 && h < 12
      ? 'da manhã'
      : h >= 12 && h < 18
          ? 'da tarde'
          : 'da noite';
  return '${activityTypeLabel(type)} $period';
}

/// Titulo a mostrar: o salvo pelo usuario ou, sem ele, o sugerido.
String displayActivityTitle(String? saved, ActivityType type, DateTime start) {
  final t = saved?.trim();
  return t == null || t.isEmpty ? suggestedActivityTitle(type, start) : t;
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
      return 'Falhou (será tentada de novo)';
  }
}

/// Data curta "dd/mm/aaaa hh:mm" a partir de epoch ms (sem dependencia de intl).
String formatDateTimeMs(int epochMs) {
  final d = DateTime.fromMillisecondsSinceEpoch(epochMs);
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
}
