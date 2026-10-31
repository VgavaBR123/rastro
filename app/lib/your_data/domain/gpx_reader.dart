/// Leitor de GPX (1.0 e 1.1) para a importacao (F07). Escrito a partir do
/// esquema publico do formato (topografix.com). Dart puro, por eventos
/// (xml_common.dart): guarda so pontos, nome, tipo e horario do metadata.
///
/// Le os pontos de trilha (`trk/trkseg/trkpt`) e, sem trilha, os da rota
/// (`rte/rtept`). Pontos com coordenada invalida ficam sem posicao (o montador
/// descarta). O esporte vem de `trk/type`, quando houver.
library;

import 'import_models.dart';
import 'xml_common.dart';
import 'xml_time.dart';

class _Point {
  final double? lat;
  final double? lon;
  final StringBuffer ele = StringBuffer();
  final StringBuffer time = StringBuffer();
  _Point(this.lat, this.lon);

  ParsedPoint build() => ParsedPoint(
    latitude: lat,
    longitude: lon,
    altitudeMeters: parseDouble(cleanText(ele.toString())),
    timeMs: parseXmlTime(cleanText(time.toString())),
  );
}

ParsedActivity parseGpx(String text) {
  final trkPoints = <ParsedPoint>[];
  final rtePoints = <ParsedPoint>[];
  _Point? point;
  String? trkName;
  String? rteName;
  String? metaName;
  String? type;
  String? metaTime;
  var rootChecked = false;
  StringBuffer? capture;
  void Function(String)? onCaptured;

  walkXml(
    text,
    onStart: (stack, attrs) {
      final name = stack.last;
      if (!rootChecked) {
        rootChecked = true;
        if (name != 'gpx') throw const ImportFormatException('nao e um arquivo GPX');
      }
      final parent = parentOf(stack);
      if (name == 'trkpt' || name == 'rtept') {
        point = _Point(parseDouble(attrs['lat']), parseDouble(attrs['lon']));
        return;
      }
      final p = point;
      if (p != null) {
        onCaptured = null;
        if (parent == 'trkpt' || parent == 'rtept') {
          if (name == 'ele') capture = p.ele;
          if (name == 'time') capture = p.time;
        }
        return;
      }
      void take(void Function(String) set) {
        capture = StringBuffer();
        onCaptured = set;
      }

      if (name == 'name' && parent == 'trk' && trkName == null) take((v) => trkName = v);
      if (name == 'name' && parent == 'rte' && rteName == null) take((v) => rteName = v);
      if (name == 'name' && parent == 'metadata' && metaName == null) take((v) => metaName = v);
      if (name == 'type' && (parent == 'trk' || parent == 'rte') && type == null) {
        take((v) => type = v);
      }
      if (name == 'time' && parent == 'metadata' && metaTime == null) take((v) => metaTime = v);
    },
    onText: (stack, t) => capture?.write(t),
    onEnd: (stack) {
      final name = stack.last;
      if (name == 'trkpt' || name == 'rtept') {
        final p = point;
        if (p != null) (name == 'trkpt' ? trkPoints : rtePoints).add(p.build());
        point = null;
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

  return ParsedActivity(
    format: ImportFormat.gpx,
    name: cleanText(trkName) ?? cleanText(rteName) ?? cleanText(metaName),
    sportName: cleanText(type),
    startMs: parseXmlTime(cleanText(metaTime)),
    points: trkPoints.isNotEmpty ? trkPoints : rtePoints,
  );
}
