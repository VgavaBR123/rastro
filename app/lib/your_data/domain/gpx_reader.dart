/// Leitor de GPX (1.0 e 1.1) para a importacao (F07). Escrito a partir do
/// esquema publico do formato (topografix.com). Dart puro.
///
/// Le os pontos de trilha (`trk/trkseg/trkpt`) e, sem trilha, os da rota
/// (`rte/rtept`). Pontos com coordenada invalida ficam sem posicao (o montador
/// descarta). O esporte vem de `trk/type`, quando houver.
library;

import 'package:xml/xml.dart';

import 'import_models.dart';
import 'xml_common.dart';
import 'xml_time.dart';

ParsedActivity parseGpx(String text) {
  final doc = parseXmlDocument(text);
  final root = doc.rootElement;
  if (root.name.local != 'gpx') {
    throw const ImportFormatException('nao e um arquivo GPX');
  }
  final trk = childNamed(root, 'trk');
  final rte = childNamed(root, 'rte');
  final owner = trk ?? rte;

  var pts = descendantsNamed(root, 'trkpt').toList();
  if (pts.isEmpty) pts = descendantsNamed(root, 'rtept').toList();

  final metadata = childNamed(root, 'metadata');
  return ParsedActivity(
    format: ImportFormat.gpx,
    name: (owner == null ? null : childText(owner, 'name')) ??
        (metadata == null ? null : childText(metadata, 'name')),
    sportName: owner == null ? null : childText(owner, 'type'),
    startMs: metadata == null ? null : parseXmlTime(childText(metadata, 'time')),
    points: [for (final p in pts) _point(p)],
  );
}

ParsedPoint _point(XmlElement e) => ParsedPoint(
  latitude: parseDouble(e.getAttribute('lat')),
  longitude: parseDouble(e.getAttribute('lon')),
  altitudeMeters: parseDouble(childText(e, 'ele')),
  timeMs: parseXmlTime(childText(e, 'time')),
);
