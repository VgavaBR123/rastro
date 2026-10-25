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

/// Data curta "dd/mm/aaaa hh:mm" a partir de epoch ms (sem dependencia de intl).
String formatDateTimeMs(int epochMs) {
  final d = DateTime.fromMillisecondsSinceEpoch(epochMs);
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
}
