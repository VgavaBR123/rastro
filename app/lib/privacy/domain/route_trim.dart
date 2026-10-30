/// Corte de privacidade da rota (F02). Funcao pura: dada a rota e as zonas,
/// devolve o intervalo de pontos que pode aparecer. Vale para o cartao
/// compartilhado, o upload e a exportacao.
///
/// Regras:
/// - O raio efetivo de cada zona e o maior entre o raio dela e um valor
///   "aleatorio" entre 200 e 600 m derivado do guid da atividade. A mesma
///   atividade corta sempre igual (quem compara duas imagens dela nao ganha
///   nada), e atividades diferentes cortam em pontos diferentes (o centro
///   nao aparece desenhando os cortes de varias atividades no mesmo raio).
/// - Corta o maior prefixo de pontos dentro de alguma zona e o maior sufixo
///   idem. Passar pela zona no meio do trajeto nao corta o meio.
/// - Opcao por atividade: ocultar os primeiros e os ultimos X metros. Vale o
///   maior corte entre zona e distancia.
library;

import '../../recording/domain/geo.dart';
import 'privacy_zone.dart';

const double kMinCutRadiusMeters = 200;
const double kMaxCutRadiusMeters = 600;

/// Raio de corte da atividade [activityGuid], entre [kMinCutRadiusMeters] e
/// [kMaxCutRadiusMeters]. Hash FNV-1a de 32 bits do guid: deterministico e
/// igual em qualquer plataforma.
double cutRadiusForActivity(String activityGuid) {
  var hash = 0x811c9dc5;
  for (final unit in activityGuid.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  final fraction = hash / 0xFFFFFFFF;
  return kMinCutRadiusMeters +
      fraction * (kMaxCutRadiusMeters - kMinCutRadiusMeters);
}

/// Intervalo visivel de uma rota: pontos de [start] (inclusivo) ate [end]
/// (exclusivo), sobre uma rota de [length] pontos.
class RouteTrim {
  final int start;
  final int end;
  final int length;

  const RouteTrim({
    required this.start,
    required this.end,
    required this.length,
  });

  /// Nada cortado.
  const RouteTrim.none(this.length) : start = 0, end = length;

  bool get hidesStart => start > 0;
  bool get hidesEnd => end < length;
  bool get hidesAnything => hidesStart || hidesEnd;

  /// A rota inteira ficou escondida.
  bool get hidesAll => length > 0 && start >= end;

  /// Recorta uma lista paralela a rota (pontos, waypoints, registros FIT).
  List<T> apply<T>(List<T> items) {
    assert(items.length == length, 'lista com tamanho diferente da rota');
    if (start >= end) return <T>[];
    return items.sublist(start, end);
  }

  @override
  String toString() => 'RouteTrim($start..$end de $length)';
}

/// Calcula o corte de [route] para as [zones] e as distancias pedidas.
RouteTrim computeRouteTrim(
  List<GeoPoint> route, {
  required List<PrivacyZone> zones,
  required String activityGuid,
  double hideStartMeters = 0,
  double hideEndMeters = 0,
}) {
  final n = route.length;
  if (n == 0) return const RouteTrim.none(0);
  final cut = cutRadiusForActivity(activityGuid);

  bool inAnyZone(GeoPoint p) {
    for (final z in zones) {
      final r = z.radiusMeters > cut ? z.radiusMeters : cut;
      if (z.contains(p, radiusMeters: r)) return true;
    }
    return false;
  }

  // Prefixo dentro das zonas.
  var start = 0;
  while (start < n && inAnyZone(route[start])) {
    start++;
  }
  // Prefixo dos primeiros X metros (ao longo da rota).
  if (hideStartMeters > 0) {
    var acc = 0.0;
    var i = 0;
    while (i < n - 1 && acc < hideStartMeters) {
      acc += haversineMeters(route[i], route[i + 1]);
      i++;
    }
    final byDistance = acc < hideStartMeters ? n : i;
    if (byDistance > start) start = byDistance;
  }

  // Sufixo dentro das zonas.
  var end = n;
  while (end > 0 && inAnyZone(route[end - 1])) {
    end--;
  }
  if (hideEndMeters > 0) {
    var acc = 0.0;
    var i = n - 1;
    while (i > 0 && acc < hideEndMeters) {
      acc += haversineMeters(route[i], route[i - 1]);
      i--;
    }
    // i e o ultimo indice cuja distancia ate o fim ja passou de X.
    final byDistance = acc < hideEndMeters ? 0 : i + 1;
    if (byDistance < end) end = byDistance;
  }

  if (start > end) start = end;
  return RouteTrim(start: start, end: end, length: n);
}
