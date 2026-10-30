// Texto de compartilhamento de uma atividade: titulo e uma linha de resumo com
// esporte, distancia, tempo e pace (velocidade no pedal), na unidade escolhida.
library;

import '../../recording/domain/recording_models.dart';
import 'activity_labels.dart';
import 'measures.dart';

/// Ex.: "Corrida da manha\nCorrida | 5.00 km | 25:00 | 5:00 /km".
String activityShareText({
  required String title,
  required ActivityType type,
  required double distanceMeters,
  required int timerMs,
  required bool metric,

  /// Modo Gentil (F04): sem pace nem velocidade.
  bool gentle = false,
}) {
  final seconds = timerMs / 1000.0;
  final rate = type == ActivityType.ride
      ? formatSpeed(seconds > 0 ? distanceMeters / seconds : 0, metric: metric)
      : formatPace(
          distanceMeters > 0 ? seconds / distanceMeters : null,
          metric: metric,
        );
  final parts = [
    activityTypeLabel(type),
    formatDistance(distanceMeters, metric: metric),
    formatDuration(timerMs),
    if (!gentle) rate,
  ];
  return '$title\n${parts.join(' | ')}';
}
