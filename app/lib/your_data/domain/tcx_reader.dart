/// Leitor de TCX (Training Center XML) para a importacao (F07). Escrito a
/// partir do esquema publico do formato. Dart puro.
///
/// Le a primeira `Activity`: esporte (atributo `Sport`), inicio (`Id`), os
/// `Trackpoint` de todas as voltas e a soma de `TotalTimeSeconds` e
/// `DistanceMeters` das voltas (usadas so quando nao ha GPS, como na esteira).
/// O TCX nao separa tempo em movimento: ele sai do nosso criterio.
library;

import 'package:xml/xml.dart';

import 'import_models.dart';
import 'xml_common.dart';
import 'xml_time.dart';

ParsedActivity parseTcx(String text) {
  final doc = parseXmlDocument(text);
  final root = doc.rootElement;
  if (root.name.local != 'TrainingCenterDatabase') {
    throw const ImportFormatException('nao e um arquivo TCX');
  }
  final activity = descendantsNamed(root, 'Activity').firstOrNull;
  if (activity == null) {
    throw const ImportFormatException('TCX sem atividade');
  }

  var seconds = 0.0;
  var meters = 0.0;
  var hasSeconds = false;
  var hasMeters = false;
  final points = <ParsedPoint>[];
  for (final lap in childrenNamed(activity, 'Lap')) {
    final s = parseDouble(childText(lap, 'TotalTimeSeconds'));
    if (s != null) {
      seconds += s;
      hasSeconds = true;
    }
    final m = parseDouble(childText(lap, 'DistanceMeters'));
    if (m != null) {
      meters += m;
      hasMeters = true;
    }
    for (final tp in descendantsNamed(lap, 'Trackpoint')) {
      points.add(_point(tp));
    }
  }

  final firstLapStart = childrenNamed(activity, 'Lap').firstOrNull?.getAttribute('StartTime');
  return ParsedActivity(
    format: ImportFormat.tcx,
    sportName: activity.getAttribute('Sport')?.trim(),
    name: childText(activity, 'Notes'),
    startMs: parseXmlTime(childText(activity, 'Id')) ?? parseXmlTime(firstLapStart),
    points: points,
    elapsedMs: hasSeconds ? (seconds * 1000).round() : null,
    distanceMeters: hasMeters ? meters : null,
  );
}

ParsedPoint _point(XmlElement tp) {
  final pos = childNamed(tp, 'Position');
  return ParsedPoint(
    timeMs: parseXmlTime(childText(tp, 'Time')),
    latitude: pos == null ? null : parseDouble(childText(pos, 'LatitudeDegrees')),
    longitude: pos == null ? null : parseDouble(childText(pos, 'LongitudeDegrees')),
    altitudeMeters: parseDouble(childText(tp, 'AltitudeMeters')),
  );
}
