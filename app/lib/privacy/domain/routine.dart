/// Aviso de rotina previsivel (F02): se pelo menos 4 das ultimas 6
/// atividades comecam no mesmo lugar (~150 m) e na mesma faixa de horario
/// (+-30 min), quem ve as atividades consegue prever onde a pessoa estara.
/// Dart puro; o horario chega como minuto do dia local.
library;

import '../../recording/domain/geo.dart';

const int kRoutineWindow = 6;
const int kRoutineMinMatches = 4;
const double kRoutineRadiusMeters = 150;
const int kRoutineToleranceMinutes = 30;

class ActivityStartSample {
  final GeoPoint start;

  /// Minuto do dia na hora local (0..1439).
  final int minuteOfDay;

  const ActivityStartSample({required this.start, required this.minuteOfDay});

  factory ActivityStartSample.at(GeoPoint start, DateTime localTime) =>
      ActivityStartSample(
        start: start,
        minuteOfDay: localTime.hour * 60 + localTime.minute,
      );
}

/// Diferenca entre dois minutos do dia, dando a volta na meia-noite.
int _minuteDistance(int a, int b) {
  final d = (a - b).abs() % 1440;
  return d > 720 ? 1440 - d : d;
}

/// [latestFirst]: atividades da mais recente para a mais antiga. So as
/// [kRoutineWindow] primeiras contam.
bool isRoutinePredictable(List<ActivityStartSample> latestFirst) {
  final window = latestFirst.take(kRoutineWindow).toList();
  if (window.length < kRoutineMinMatches) return false;
  for (final anchor in window) {
    var matches = 0;
    for (final other in window) {
      if (haversineMeters(anchor.start, other.start) <= kRoutineRadiusMeters &&
          _minuteDistance(anchor.minuteOfDay, other.minuteOfDay) <=
              kRoutineToleranceMinutes) {
        matches++;
      }
    }
    if (matches >= kRoutineMinMatches) return true;
  }
  return false;
}

/// Aviso de rotina para uma atividade especifica ([target], por exemplo a
/// que esta sendo compartilhada): a janela e ela mais as atividades
/// anteriores a ela ([previousLatestFirst], da mais nova para a mais
/// antiga), e so avisa se a propria [target] esta no grupo repetido.
bool isRoutinePredictableFor(
  ActivityStartSample target,
  List<ActivityStartSample> previousLatestFirst,
) {
  final window = [target, ...previousLatestFirst.take(kRoutineWindow - 1)];
  var matches = 0;
  for (final other in window) {
    if (haversineMeters(target.start, other.start) <= kRoutineRadiusMeters &&
        _minuteDistance(target.minuteOfDay, other.minuteOfDay) <=
            kRoutineToleranceMinutes) {
      matches++;
    }
  }
  return matches >= kRoutineMinMatches;
}
