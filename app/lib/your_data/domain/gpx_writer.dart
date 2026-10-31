/// Escritor de GPX 1.1 da exportacao (F07), a partir do esquema publico do
/// formato (topografix.com). Dart puro.
///
/// Uma trilha (`trk`) com nome, tipo e um segmento; cada ponto com elevacao
/// (quando ha) e horario em UTC. Atividade sem GPS sai com o segmento vazio,
/// que continua sendo GPX valido.
library;

import '../../recording/domain/recording_models.dart';

class GpxPoint {
  final double latitude;
  final double longitude;
  final double? altitudeMeters;
  final int timeMs;

  const GpxPoint({
    required this.latitude,
    required this.longitude,
    required this.timeMs,
    this.altitudeMeters,
  });
}

/// Valor do `<type>` por esporte (nomes comuns entre aplicativos).
String gpxTypeOf(ActivityType t) => switch (t) {
  ActivityType.run => 'running',
  ActivityType.ride => 'cycling',
  ActivityType.walk => 'walking',
};

/// So os caracteres validos em XML 1.0: tab, LF, CR, U+0020..U+D7FF,
/// U+E000..U+FFFD e U+10000..U+10FFFF. Controles e surrogates soltos saem.
String xmlValidChars(String s) {
  final b = StringBuffer();
  for (final r in s.runes) {
    final ok = r == 0x9 ||
        r == 0xA ||
        r == 0xD ||
        (r >= 0x20 && r <= 0xD7FF) ||
        (r >= 0xE000 && r <= 0xFFFD) ||
        (r >= 0x10000 && r <= 0x10FFFF);
    if (ok) b.writeCharCode(r);
  }
  return b.toString();
}

String xmlEscape(String s) => xmlValidChars(s)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');

/// Horario ISO 8601 em UTC ("2026-03-01T10:00:00Z", com milissegundos so
/// quando houver).
String isoUtcTime(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  String two(int v) => v.toString().padLeft(2, '0');
  final base = '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}'
      'T${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
  return d.millisecond == 0 ? '${base}Z' : '$base.${d.millisecond.toString().padLeft(3, '0')}Z';
}

String _num(double v, int digits) {
  final s = v.toStringAsFixed(digits);
  // Sem zeros sobrando no fim (menor e igual de preciso).
  if (!s.contains('.')) return s;
  final t = s.replaceFirst(RegExp(r'0+$'), '');
  return t.endsWith('.') ? t.substring(0, t.length - 1) : t;
}

String buildGpx({
  required String name,
  required ActivityType type,
  required int startMs,
  required List<GpxPoint> points,
}) {
  final b = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
    ..writeln('<gpx version="1.1" creator="Rastro" xmlns="http://www.topografix.com/GPX/1/1" '
        'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
        'xsi:schemaLocation="http://www.topografix.com/GPX/1/1 '
        'http://www.topografix.com/GPX/1/1/gpx.xsd">')
    ..writeln('  <metadata>')
    ..writeln('    <name>${xmlEscape(name)}</name>')
    ..writeln('    <time>${isoUtcTime(startMs)}</time>')
    ..writeln('  </metadata>')
    ..writeln('  <trk>')
    ..writeln('    <name>${xmlEscape(name)}</name>')
    ..writeln('    <type>${gpxTypeOf(type)}</type>')
    ..writeln('    <trkseg>');
  for (final p in points) {
    b.write('      <trkpt lat="${_num(p.latitude, 7)}" lon="${_num(p.longitude, 7)}">');
    final alt = p.altitudeMeters;
    if (alt != null && alt.isFinite) b.write('<ele>${_num(alt, 1)}</ele>');
    b.writeln('<time>${isoUtcTime(p.timeMs)}</time></trkpt>');
  }
  b
    ..writeln('    </trkseg>')
    ..writeln('  </trk>')
    ..writeln('</gpx>');
  return b.toString();
}

final RegExp _unsafe = RegExp(r'[\\/:*?"<>|\x00-\x1F]');
final RegExp _spaces = RegExp(r'\s+');

/// Parte de nome de arquivo sem caracteres proibidos, ate 60 caracteres
/// (contados por rune: nunca parte um emoji ao meio).
String safeFileName(String s) {
  var t = xmlValidChars(s).replaceAll(_unsafe, ' ').replaceAll(_spaces, ' ').trim();
  final runes = t.runes.toList();
  if (runes.length > 60) t = String.fromCharCodes(runes.take(60)).trim();
  return t.isEmpty ? 'atividade' : t;
}
