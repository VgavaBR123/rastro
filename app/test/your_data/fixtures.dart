// Arquivos de atividade gerados nos testes do F07 (GPX, TCX, FIT, gz e ZIP).
// Nada aqui vem de exportacao real: tudo e montado a partir da documentacao
// publica dos formatos.
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart' as arc;
import 'package:strava_estudo_app/sync/fit/fit_crc.dart';

/// Inicio padrao das fixtures: 2026-03-01 10:00:00 UTC.
final int kT0 = DateTime.utc(2026, 3, 1, 10).millisecondsSinceEpoch;

typedef FixPoint = ({double lat, double lon, double? ele, String? time});

String isoUtc(int ms) =>
    '${DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toIso8601String().split('.').first}Z';

/// [n] pontos indo para o norte a [stepMeters] por segundo, a partir de
/// (-23.5, -46.6), altitude 760 subindo 1 m por ponto.
List<FixPoint> line(int n, {double stepMeters = 3.2, int startMs = 0, int everyMs = 1000}) {
  final t0 = startMs == 0 ? kT0 : startMs;
  final stepDeg = stepMeters / 111195.0;
  return [
    for (var i = 0; i < n; i++)
      (lat: -23.5 + stepDeg * i, lon: -46.6, ele: 760.0 + i, time: isoUtc(t0 + everyMs * i)),
  ];
}

String gpxText({
  String? name,
  String? type,
  String? metadataTime,
  required List<FixPoint> points,
}) {
  final b = StringBuffer()
    ..write('<?xml version="1.0" encoding="UTF-8"?>\n')
    ..write('<gpx version="1.1" creator="teste" xmlns="http://www.topografix.com/GPX/1/1">\n');
  if (metadataTime != null) b.write('<metadata><time>$metadataTime</time></metadata>\n');
  b.write('<trk>');
  if (name != null) b.write('<name>$name</name>');
  if (type != null) b.write('<type>$type</type>');
  b.write('<trkseg>\n');
  for (final p in points) {
    b.write('<trkpt lat="${p.lat}" lon="${p.lon}">');
    if (p.ele != null) b.write('<ele>${p.ele}</ele>');
    if (p.time != null) b.write('<time>${p.time}</time>');
    b.write('</trkpt>\n');
  }
  b.write('</trkseg></trk></gpx>\n');
  return b.toString();
}

String tcxText({
  required String sport,
  required List<FixPoint> points,
  String? notes,
  double lapSeconds = 60,
  double lapMeters = 100,
}) {
  final b = StringBuffer()
    ..write('<?xml version="1.0" encoding="UTF-8"?>\n')
    ..write('<TrainingCenterDatabase xmlns="http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2">')
    ..write('<Activities><Activity Sport="$sport"><Id>${isoUtc(kT0)}</Id>')
    ..write('<Lap StartTime="${isoUtc(kT0)}"><TotalTimeSeconds>$lapSeconds</TotalTimeSeconds>')
    ..write('<DistanceMeters>$lapMeters</DistanceMeters><Track>');
  var d = 0.0;
  for (final p in points) {
    b.write('<Trackpoint><Time>${p.time}</Time>');
    b.write('<Position><LatitudeDegrees>${p.lat}</LatitudeDegrees>'
        '<LongitudeDegrees>${p.lon}</LongitudeDegrees></Position>');
    if (p.ele != null) b.write('<AltitudeMeters>${p.ele}</AltitudeMeters>');
    b.write('<DistanceMeters>$d</DistanceMeters></Trackpoint>');
    d += 3;
  }
  b.write('</Track></Lap>');
  if (notes != null) b.write('<Notes>$notes</Notes>');
  b.write('</Activity></Activities></TrainingCenterDatabase>');
  return b.toString();
}

// --- FIT ---

const int _fitEpoch = 631065600;
int _fitSec(int ms) => ms ~/ 1000 - _fitEpoch;
int _semi(double deg) => (deg * 2147483648.0 / 180.0).round();

class _Sink {
  final BytesBuilder b = BytesBuilder();
  void u8(int v) => b.addByte(v & 0xFF);
  void u16(int v) => b.add((ByteData(2)..setUint16(0, v & 0xFFFF, Endian.little)).buffer.asUint8List());
  void u32(int v) => b.add((ByteData(4)..setUint32(0, v & 0xFFFFFFFF, Endian.little)).buffer.asUint8List());
  void s32(int v) => b.add((ByteData(4)..setInt32(0, v, Endian.little)).buffer.asUint8List());
  void def(int local, int global, List<List<int>> fields) {
    u8(0x40 | local);
    u8(0);
    u8(0);
    u16(global);
    u8(fields.length);
    for (final f in fields) {
      b.add(f);
    }
  }
}

typedef FitEvent = ({int timeMs, bool stop});

/// FIT de atividade com file_id, sport (opcional), records, eventos de timer
/// (opcionais) e session (opcional). [badCrc] estraga o CRC final.
/// [compressedFrom]: a partir deste indice os records usam cabecalho de
/// timestamp comprimido.
Uint8List fitBytes({
  List<FixPoint> points = const [],
  int? sport,
  int? subSport,
  String? sportMessageName,
  int? sessionTimerMs,
  int? sessionElapsedMs,
  double? sessionDistance,
  bool withSession = true,
  List<FitEvent> events = const [],
  bool badCrc = false,
  int? compressedFrom,
  bool noPosition = false,
}) {
  final s = _Sink();
  s.def(0, 0, [
    [0, 1, 0x00],
    [4, 4, 0x86],
  ]);
  s.u8(0);
  s.u8(4);
  s.u32(_fitSec(kT0));
  if (sportMessageName != null || (sport != null && !withSession)) {
    final name = (sportMessageName ?? '').codeUnits;
    s.def(1, 12, [
      [0, 1, 0x00],
      [1, 1, 0x00],
      [3, 16, 0x07],
    ]);
    s.u8(1);
    s.u8(sport ?? 0);
    s.u8(subSport ?? 0);
    s.b.add([...name.take(15), ...List.filled(16 - name.take(15).length, 0)]);
  }
  s.def(2, 20, [
    [253, 4, 0x86],
    [0, 4, 0x85],
    [1, 4, 0x85],
    [2, 2, 0x84],
    [6, 2, 0x84],
  ]);
  // Record comprimido: so posicao, altitude e velocidade (sem timestamp).
  if (compressedFrom != null) {
    s.def(3, 20, [
      [0, 4, 0x85],
      [1, 4, 0x85],
      [2, 2, 0x84],
      [6, 2, 0x84],
    ]);
  }
  for (var i = 0; i < points.length; i++) {
    final p = points[i];
    final ms = DateTime.parse(p.time!).millisecondsSinceEpoch;
    final compressed = compressedFrom != null && i >= compressedFrom;
    if (compressed) {
      s.u8(0x80 | (3 << 5) | (_fitSec(ms) & 0x1F));
    } else {
      s.u8(2);
      s.u32(_fitSec(ms));
    }
    s.s32(noPosition ? 0x7FFFFFFF : _semi(p.lat));
    s.s32(noPosition ? 0x7FFFFFFF : _semi(p.lon));
    s.u16(p.ele == null ? 0xFFFF : ((p.ele! + 500) * 5).round());
    s.u16(0xFFFF);
  }
  if (events.isNotEmpty) {
    s.def(4, 21, [
      [253, 4, 0x86],
      [0, 1, 0x00],
      [1, 1, 0x00],
    ]);
    for (final e in events) {
      s.u8(4);
      s.u32(_fitSec(e.timeMs));
      s.u8(0); // timer
      s.u8(e.stop ? 4 : 0); // stop_all : start
    }
  }
  if (withSession) {
    s.def(5, 18, [
      [253, 4, 0x86],
      [2, 4, 0x86],
      [7, 4, 0x86],
      [8, 4, 0x86],
      [9, 4, 0x86],
      [5, 1, 0x00],
      [6, 1, 0x00],
    ]);
    s.u8(5);
    s.u32(_fitSec(kT0 + (sessionElapsedMs ?? 0)));
    s.u32(_fitSec(kT0));
    s.u32(sessionElapsedMs ?? 0xFFFFFFFF);
    s.u32(sessionTimerMs ?? 0xFFFFFFFF);
    s.u32(sessionDistance == null ? 0xFFFFFFFF : (sessionDistance * 100).round());
    s.u8(sport ?? 0xFF);
    s.u8(subSport ?? 0xFF);
  }
  final data = s.b.toBytes();
  final h = _Sink();
  h.u8(14);
  h.u8(0x20);
  h.u16(2100);
  h.u32(data.length);
  h.b.add('.FIT'.codeUnits);
  final first = h.b.toBytes();
  h.u16(fitCrc16(first));
  final all = BytesBuilder()
    ..add(h.b.toBytes())
    ..add(data);
  final content = all.toBytes();
  final crc = fitCrc16(content) ^ (badCrc ? 0x5A5A : 0);
  return Uint8List.fromList([...content, crc & 0xFF, (crc >> 8) & 0xFF]);
}

// --- gz e ZIP ---

List<int> gz(List<int> bytes) => gzip.encode(bytes);

/// ZIP montado com o pacote `archive` (independente do nosso leitor).
/// [deflate] false grava sem compressao.
List<int> zipOf(Map<String, List<int>> files, {bool deflate = true}) {
  final a = arc.Archive();
  for (final e in files.entries) {
    final f = arc.ArchiveFile.bytes(e.key, e.value);
    if (!deflate) f.compression = arc.CompressionType.none;
    a.addFile(f);
  }
  return arc.ZipEncoder().encode(a);
}

/// activities.csv no layout da exportacao de conta (colunas em ingles).
String stravaCsv(List<({String id, String name, String type, String file})> rows) {
  String q(String v) => '"${v.replaceAll('"', '""')}"';
  final b = StringBuffer('Activity ID,Activity Date,Activity Name,Activity Type,'
      'Activity Description,Elapsed Time,Distance,Filename\n');
  for (final r in rows) {
    b.write('${r.id},"Mar 1, 2026, 10:00:00 AM",${q(r.name)},${r.type},"",60,0.1,${r.file}\n');
  }
  return b.toString();
}

/// Grava [bytes] em um arquivo temporario com [name] e devolve o caminho.
String writeTemp(Directory dir, String name, List<int> bytes) {
  final f = File('${dir.path}/$name')..writeAsBytesSync(bytes);
  return f.path;
}
