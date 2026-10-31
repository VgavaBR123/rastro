/// Montagem da atividade importada (F07): do que o arquivo traz
/// ([ParsedActivity]) para o que vai ao banco ([ImportedActivity]). Dart puro.
///
/// As metricas saem do NOSSO pipeline de gravacao: cada ponto vira uma
/// amostra de localizacao e passa pela [RecordingSession] (filtro de ruido,
/// distancia, relogio e pausa automatica), como numa gravacao feita no app.
/// - Tempo em movimento: o do arquivo quando ele tem (FIT: total_timer_time,
///   com as pausas do aparelho aplicadas ponto a ponto); senao, o nosso
///   criterio de movimento (pausa automatica do esporte).
/// - Sem GPS (esteira) mas com distancia/tempo no arquivo: entra sem rota.
/// - Sem tipo no arquivo: inferido pelo ritmo medio.
library;

import '../../recording/domain/geo.dart';
import '../../recording/domain/location_sample.dart';
import '../../recording/domain/recording_models.dart';
import '../../recording/domain/recording_session.dart';
import '../../recording/domain/waypoint.dart';
import 'import_models.dart';
import 'sport_mapping.dart';

/// Precisao horizontal atribuida aos pontos importados. Os arquivos nao trazem
/// precisao e o pipeline descarta ponto sem ela; 5 m e um fix bom de GPS.
const double kImportedAccuracyMeters = 5.0;

/// Distancia maxima entre o inicio declarado no GPX/TCX e o primeiro ponto
/// para o declarado valer.
const int kDeclaredStartToleranceMs = 60000;

/// Atividade pronta para gravar no banco.
class ImportedActivity {
  final String guid;
  final ActivityType type;
  final ImportFormat format;
  final String? title;
  final int startMs;
  final int endMs;
  final int timerMs;
  final double distanceMeters;
  final bool isIndoor;

  /// O arquivo nao dizia o esporte: [type] saiu do ritmo medio. A duplicata
  /// por horario nao exige o mesmo tipo.
  final bool typeInferred;

  /// So os pontos aceitos pelo pipeline, em ordem (como a gravacao persiste).
  final List<Waypoint> points;

  const ImportedActivity({
    required this.guid,
    required this.type,
    required this.format,
    required this.title,
    required this.startMs,
    required this.endMs,
    required this.timerMs,
    required this.distanceMeters,
    required this.isIndoor,
    required this.points,
    this.typeInferred = false,
  });
}

sealed class BuildResult {
  const BuildResult();
}

class BuiltActivity extends BuildResult {
  final ImportedActivity activity;
  const BuiltActivity(this.activity);
}

/// Esporte fora de corrida, pedal e caminhada. [label] agrupa no resumo.
class SkippedSport extends BuildResult {
  final String label;
  const SkippedSport(this.label);
}

String? _clean(String? s) {
  final t = s?.trim();
  return t == null || t.isEmpty ? null : t;
}

/// Monta a atividade de [parsed]. [hash] e o hash do conteudo do arquivo
/// (guid `imp-<hash>`). [sportOverride] e [nameOverride] vem do activities.csv
/// e valem mais que o arquivo. Lanca [ImportFormatException] quando nao ha
/// dados suficientes.
BuildResult buildImportedActivity(
  ParsedActivity parsed, {
  required String hash,
  String? sportOverride,
  String? nameOverride,
}) {
  // CSV primeiro; sem tipo no CSV, ou com um nome que nao conhecemos, vale o
  // esporte do proprio arquivo. Se o arquivo nao disser nada, o nome
  // desconhecido do CSV e ignorado (nao inventamos o esporte).
  final fromCsv = matchSport(sportOverride);
  var sport = fromCsv;
  if (fromCsv.isUnknown || !fromCsv.listed) {
    final fromFile = matchSport(parsed.sportName);
    if (!fromFile.isUnknown) sport = fromFile;
  }
  if (sport.otherLabel != null) return SkippedSport(sport.otherLabel!);

  final title = _clean(nameOverride) ?? _clean(parsed.name);
  final guid = 'imp-$hash';

  // Pontos com horario, em ordem: os que voltam no tempo sao descartados.
  final timed = <ParsedPoint>[];
  for (final p in parsed.points) {
    final t = p.timeMs;
    if (t == null) continue;
    if (timed.isNotEmpty && t < timed.last.timeMs!) continue;
    timed.add(p);
  }
  final located = [for (final p in timed) if (p.hasPosition) p];
  final anyPosition = parsed.points.any((p) => p.hasPosition);

  var start = parsed.startMs;
  if (timed.isNotEmpty) {
    final first = timed.first.timeMs!;
    if (parsed.format == ImportFormat.fit) {
      // FIT: session.start_time vale (o primeiro ponto so se for antes).
      if (start == null || first < start) start = first;
    } else if (start == null || (start - first).abs() > kDeclaredStartToleranceMs) {
      // GPX/TCX: o horario declarado (metadata/time, Id) so vale perto do
      // primeiro ponto; longe dele costuma ser a hora do arquivo, nao da
      // atividade.
      start = first;
    } else if (first < start) {
      start = first;
    }
  }

  if (located.isEmpty) {
    if (anyPosition) throw const ImportFormatException('pontos sem horario');
    final timer = parsed.timerMs ?? parsed.elapsedMs;
    final dist = parsed.distanceMeters ?? 0;
    if (start == null || ((timer ?? 0) <= 0 && dist <= 0)) {
      throw const ImportFormatException('atividade sem pontos nem totais');
    }
    final lastPointMs = timed.isEmpty ? start : timed.last.timeMs!;
    final elapsed = parsed.elapsedMs ?? timer ?? (lastPointMs - start);
    final movingMs = timer ?? elapsed;
    final type = sport.type ??
        inferSportFromSpeed(movingMs > 0 ? dist / (movingMs / 1000) : 0);
    return BuiltActivity(ImportedActivity(
      guid: guid,
      type: type,
      format: parsed.format,
      title: title,
      startMs: start,
      endMs: start + elapsed,
      timerMs: movingMs,
      distanceMeters: dist,
      isIndoor: true,
      points: const [],
      typeInferred: sport.type == null,
    ));
  }

  final startMs = start!;
  final usesDevicePauses = parsed.timerPauses.isNotEmpty;
  // Sem tipo: o pipeline roda como corrida (a pausa automatica de corrida e a
  // intermediaria) e o tipo e decidido depois pelo ritmo.
  final session = RecordingSession(
    activityType: sport.type ?? ActivityType.run,
    autoPauseEnabled: !usesDevicePauses,
  );
  final accepted = <Waypoint>[];
  final pauses = [...parsed.timerPauses]
    ..sort((a, b) => a.stopMs.compareTo(b.stopMs));
  var pi = 0;
  var paused = false;
  session.start(0);
  for (final p in located) {
    final t = p.timeMs!;
    // Aplica as pausas do aparelho que comecaram (e terminaram) ate este ponto.
    while (pi < pauses.length) {
      final pause = pauses[pi];
      if (!paused && pause.stopMs <= t) {
        session.pauseManual(pause.stopMs - startMs);
        paused = true;
      }
      if (paused && pause.startMs <= t) {
        session.resumeManual(pause.startMs - startMs);
        paused = false;
        pi++;
        continue;
      }
      break;
    }
    final wp = session.addSample(LocationSample(
      position: GeoPoint(
        latitude: p.latitude!,
        longitude: p.longitude!,
        altitudeMeters: p.altitudeMeters,
      ),
      wallClockMs: t,
      monotonicMs: t - startMs,
      horizontalAccuracyMeters: kImportedAccuracyMeters,
      speedMetersPerSecond: p.speedMetersPerSecond,
    ));
    if (wp.classification == WaypointClassification.accept) accepted.add(wp);
  }
  session.finish();
  final stats = session.stats;
  var elapsed = stats.elapsedMs;
  final fileElapsed = parsed.elapsedMs;
  if (fileElapsed != null && fileElapsed > elapsed) elapsed = fileElapsed;
  var timer = parsed.timerMs ?? stats.timerMs;
  if (timer > elapsed) timer = elapsed;
  final distance = stats.distanceMeters;
  if (elapsed <= 0 && distance <= 0) {
    throw const ImportFormatException('poucos pontos para formar uma atividade');
  }
  final type = sport.type ??
      inferSportFromSpeed(timer > 0 ? distance / (timer / 1000) : 0);

  return BuiltActivity(ImportedActivity(
    guid: guid,
    type: type,
    format: parsed.format,
    title: title,
    startMs: startMs,
    endMs: startMs + elapsed,
    timerMs: timer,
    distanceMeters: distance,
    isIndoor: false,
    points: accepted,
    typeInferred: sport.type == null,
  ));
}
