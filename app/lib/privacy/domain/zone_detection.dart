/// Deteccao automatica de casa e trabalho (F02), so no aparelho: agrupa os
/// inicios e fins das atividades em grupos de ~150 m e sugere esconder os
/// lugares que se repetem pelo menos 3 vezes. Dart puro e deterministico.
library;

import '../../recording/domain/geo.dart';
import 'privacy_zone.dart';

/// Raio dos grupos de inicio/fim.
const double kZoneClusterRadiusMeters = 150;

/// Ocorrencias minimas para virar sugestao.
const int kZoneMinOccurrences = 3;

/// Raio padrao de uma zona criada a partir de uma sugestao.
const double kDefaultZoneRadiusMeters = 200;

/// Primeiro e ultimo ponto aceito de uma atividade.
class ActivityEndpoints {
  final String guid;
  final GeoPoint start;
  final GeoPoint end;
  const ActivityEndpoints({
    required this.guid,
    required this.start,
    required this.end,
  });
}

/// Como a sugestao e apresentada: o lugar mais frequente e a casa, o
/// segundo o trabalho, os demais "local frequente".
enum SuggestionKind {
  home('Casa', 'Parece que aqui e sua casa. Quer esconder?'),
  work('Trabalho', 'Parece que aqui e seu trabalho. Quer esconder?'),
  frequent(
    'Local frequente',
    'Voce comeca ou termina muitas atividades aqui. Quer esconder?',
  );

  final String label;
  final String question;
  const SuggestionKind(this.label, this.question);
}

class ZoneSuggestion {
  final GeoPoint center;
  final int occurrences;
  final SuggestionKind kind;
  const ZoneSuggestion({
    required this.center,
    required this.occurrences,
    required this.kind,
  });

  /// Zona que nasce ao aceitar a sugestao.
  PrivacyZone toZone({double radiusMeters = kDefaultZoneRadiusMeters}) =>
      PrivacyZone(
        latitude: center.latitude,
        longitude: center.longitude,
        radiusMeters: radiusMeters,
        label: kind.label,
      );
}

class _Cluster {
  double sumLat = 0;
  double sumLon = 0;
  int count = 0;
  GeoPoint get center =>
      GeoPoint(latitude: sumLat / count, longitude: sumLon / count);
  void add(GeoPoint p) {
    sumLat += p.latitude;
    sumLon += p.longitude;
    count++;
  }
}

/// Sugestoes de zona a partir de [activities], sem repetir lugares ja
/// protegidos por [zones] nem os [dismissed] (sugestoes ignoradas).
List<ZoneSuggestion> suggestPrivacyZones(
  List<ActivityEndpoints> activities, {
  List<PrivacyZone> zones = const [],
  List<GeoPoint> dismissed = const [],
  double clusterRadiusMeters = kZoneClusterRadiusMeters,
  int minOccurrences = kZoneMinOccurrences,
}) {
  // Agrupamento guloso: cada ponto entra no grupo mais proximo cujo centro
  // esta a ate clusterRadius, senao abre um grupo novo.
  final clusters = <_Cluster>[];
  for (final a in activities) {
    for (final p in [a.start, a.end]) {
      _Cluster? best;
      var bestD = double.infinity;
      for (final c in clusters) {
        final d = haversineMeters(c.center, p);
        if (d <= clusterRadiusMeters && d < bestD) {
          best = c;
          bestD = d;
        }
      }
      (best ?? (clusters..add(_Cluster())).last).add(p);
    }
  }

  bool covered(GeoPoint center) {
    for (final z in zones) {
      final r = z.radiusMeters > clusterRadiusMeters
          ? z.radiusMeters
          : clusterRadiusMeters;
      if (z.contains(center, radiusMeters: r)) return true;
    }
    for (final d in dismissed) {
      if (haversineMeters(d, center) <= clusterRadiusMeters) return true;
    }
    return false;
  }

  final kept = [
    for (final c in clusters)
      if (c.count >= minOccurrences && !covered(c.center)) c,
  ];
  // Ordem estavel: mais ocorrencias primeiro; empate fica na ordem de chegada.
  final indexed = [for (var i = 0; i < kept.length; i++) (i, kept[i])]
    ..sort((a, b) {
      final byCount = b.$2.count.compareTo(a.$2.count);
      return byCount != 0 ? byCount : a.$1.compareTo(b.$1);
    });

  // Casa e trabalho so contam entre os lugares ainda sem zona: com a casa ja
  // protegida, o primeiro restante e tratado como trabalho.
  final hasHome = zones.any((z) => z.label == SuggestionKind.home.label);
  final hasWork = zones.any((z) => z.label == SuggestionKind.work.label);
  final kinds = [
    if (!hasHome) SuggestionKind.home,
    if (!hasWork) SuggestionKind.work,
  ];
  return [
    for (var i = 0; i < indexed.length; i++)
      ZoneSuggestion(
        center: indexed[i].$2.center,
        occurrences: indexed[i].$2.count,
        kind: i < kinds.length ? kinds[i] : SuggestionKind.frequent,
      ),
  ];
}
