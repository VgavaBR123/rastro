/// Leitor de TCX (Training Center XML) para a importacao (F07). Escrito a
/// partir do esquema publico do formato. Dart puro, por eventos
/// (xml_common.dart).
///
/// Le a primeira `Activity`: esporte (atributo `Sport`), inicio (`Id`), os
/// `Trackpoint` de todas as voltas e a soma de `TotalTimeSeconds` (tempo em
/// movimento) e `DistanceMeters` das voltas. O tempo total e o ultimo
/// Trackpoint menos o inicio, quando ha horarios.
library;

import 'import_models.dart';
import 'xml_common.dart';
import 'xml_time.dart';

class _Tp {
  final StringBuffer time = StringBuffer();
  final StringBuffer lat = StringBuffer();
  final StringBuffer lon = StringBuffer();
  final StringBuffer alt = StringBuffer();

  ParsedPoint build() => ParsedPoint(
    timeMs: parseXmlTime(cleanText(time.toString())),
    latitude: parseDouble(cleanText(lat.toString())),
    longitude: parseDouble(cleanText(lon.toString())),
    altitudeMeters: parseDouble(cleanText(alt.toString())),
  );
}

ParsedActivity parseTcx(String text) {
  var rootChecked = false;
  // 0 = antes da 1a Activity, 1 = dentro dela, 2 = depois (ignora o resto).
  var activityState = 0;
  String? sport;
  String? id;
  String? notes;
  String? firstLapStart;
  var seconds = 0.0;
  var meters = 0.0;
  var hasSeconds = false;
  var hasMeters = false;
  final points = <ParsedPoint>[];
  _Tp? tp;
  StringBuffer? capture;
  void Function(String)? onCaptured;

  walkXml(
    text,
    onStart: (stack, attrs) {
      final name = stack.last;
      if (!rootChecked) {
        rootChecked = true;
        if (name != 'TrainingCenterDatabase') {
          throw const ImportFormatException('nao e um arquivo TCX');
        }
      }
      if (name == 'Activity' && activityState == 0) {
        activityState = 1;
        sport = attrs['Sport'];
        return;
      }
      if (activityState != 1) return;
      final parent = parentOf(stack);
      if (name == 'Lap') {
        firstLapStart ??= attrs['StartTime'];
        return;
      }
      if (name == 'Trackpoint') {
        tp = _Tp();
        return;
      }
      final t = tp;
      if (t != null) {
        onCaptured = null;
        if (name == 'Time' && parent == 'Trackpoint') capture = t.time;
        if (name == 'AltitudeMeters' && parent == 'Trackpoint') capture = t.alt;
        if (name == 'LatitudeDegrees' && parent == 'Position') capture = t.lat;
        if (name == 'LongitudeDegrees' && parent == 'Position') capture = t.lon;
        return;
      }
      void take(void Function(String) set) {
        capture = StringBuffer();
        onCaptured = set;
      }

      if (name == 'Id' && parent == 'Activity') take((v) => id = v);
      if (name == 'Notes' && parent == 'Activity') take((v) => notes = v);
      if (name == 'TotalTimeSeconds' && parent == 'Lap') {
        take((v) {
          final s = parseDouble(v);
          if (s != null) {
            seconds += s;
            hasSeconds = true;
          }
        });
      }
      if (name == 'DistanceMeters' && parent == 'Lap') {
        take((v) {
          final m = parseDouble(v);
          if (m != null) {
            meters += m;
            hasMeters = true;
          }
        });
      }
    },
    onText: (stack, t) => capture?.write(t),
    onEnd: (stack) {
      if (activityState != 1) return;
      final name = stack.last;
      if (name == 'Activity') {
        activityState = 2;
        return;
      }
      if (name == 'Trackpoint') {
        final t = tp;
        if (t != null) points.add(t.build());
        tp = null;
        capture = null;
        return;
      }
      final c = capture;
      if (c != null) {
        onCaptured?.call(c.toString());
        capture = null;
        onCaptured = null;
      }
    },
  );

  if (activityState == 0) throw const ImportFormatException('TCX sem atividade');
  final startMs = parseXmlTime(cleanText(id)) ?? parseXmlTime(cleanText(firstLapStart));
  int? firstTime;
  int? lastTime;
  for (final p in points) {
    final t = p.timeMs;
    if (t == null) continue;
    firstTime ??= t;
    lastTime = t;
  }
  final base = startMs ?? firstTime;
  return ParsedActivity(
    format: ImportFormat.tcx,
    sportName: cleanText(sport),
    name: cleanText(notes),
    startMs: startMs,
    points: points,
    timerMs: hasSeconds ? (seconds * 1000).round() : null,
    elapsedMs: lastTime != null && base != null && lastTime >= base ? lastTime - base : null,
    distanceMeters: hasMeters ? meters : null,
  );
}
