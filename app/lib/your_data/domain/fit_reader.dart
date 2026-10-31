/// Leitor FIT da importacao (F07), em Dart puro.
///
/// Mesma base do decodificador do backend (backend/lib/src/fit_decoder.dart),
/// escrito a partir da especificacao publica do formato FIT, estendido com o
/// que a importacao precisa:
/// - `record` (20): horario, posicao, altitude (e enhanced_altitude) e
///   velocidade (e enhanced_speed);
/// - `session` (18): inicio, tempo total, tempo em movimento
///   (total_timer_time), distancia e esporte;
/// - `sport` (12): esporte e nome, quando nao ha sessao;
/// - `event` (21) de timer: as pausas do cronometro do aparelho;
/// - cabecalho de timestamp comprimido.
///
/// Defensivo: arquivo vazio, truncado, com assinatura ou CRC errado vira
/// [ImportFormatException], nunca RangeError.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'import_models.dart';

const int _fitEpochOffsetSeconds = 631065600;
const double _degreesPerSemicircle = 180.0 / 2147483648.0;

const int _msgSport = 12;
const int _msgSession = 18;
const int _msgRecord = 20;
const int _msgEvent = 21;

/// Nomes do enum `sport` do perfil FIT (os mais comuns). 0 (generic) fica
/// sem nome: o montador infere pelo ritmo.
const Map<int, String> _sportNames = {
  1: 'running',
  2: 'cycling',
  3: 'transition',
  4: 'fitness_equipment',
  5: 'swimming',
  6: 'basketball',
  7: 'soccer',
  8: 'tennis',
  9: 'american_football',
  10: 'training',
  11: 'walking',
  12: 'cross_country_skiing',
  13: 'alpine_skiing',
  14: 'snowboarding',
  15: 'rowing',
  16: 'mountaineering',
  17: 'hiking',
  18: 'multisport',
  19: 'paddling',
  21: 'e_biking',
};

const List<int> _crcTable = <int>[
  0x0000, 0xCC01, 0xD801, 0x1400, 0xF001, 0x3C00, 0x2800, 0xE401, //
  0xA001, 0x6C00, 0x7800, 0xB401, 0x5000, 0x9C01, 0x8801, 0x4400, //
];

int _crc16(Uint8List bytes, int start, int end) {
  var crc = 0;
  for (var i = start; i < end; i++) {
    final byte = bytes[i];
    var tmp = _crcTable[crc & 0x0F];
    crc = (crc >> 4) & 0x0FFF;
    crc = crc ^ tmp ^ _crcTable[byte & 0x0F];
    tmp = _crcTable[crc & 0x0F];
    crc = (crc >> 4) & 0x0FFF;
    crc = crc ^ tmp ^ _crcTable[(byte >> 4) & 0x0F];
  }
  return crc & 0xFFFF;
}

class _Field {
  final int number;
  final int size;
  final int baseType;
  final int offset;
  const _Field(this.number, this.size, this.baseType, this.offset);
}

class _Def {
  final int global;
  final Endian endian;
  final Map<int, _Field> fields;
  final int totalSize;
  const _Def(this.global, this.endian, this.fields, this.totalSize);
}

Never _fail(String m) => throw ImportFormatException(m);

/// Le um arquivo FIT de atividade.
ParsedActivity parseFit(Uint8List data) {
  if (data.isEmpty) _fail('arquivo vazio');
  if (data.length < 14) _fail('arquivo FIT curto demais');
  final headerSize = data[0];
  if (headerSize != 12 && headerSize != 14) _fail('cabecalho FIT invalido');
  if (data[8] != 0x2E || data[9] != 0x46 || data[10] != 0x49 || data[11] != 0x54) {
    _fail('nao e um arquivo FIT');
  }
  final view = ByteData.sublistView(data);
  final dataSize = view.getUint32(4, Endian.little);
  final end = headerSize + dataSize;
  if (dataSize == 0 || data.length < end + 2) _fail('arquivo FIT truncado');
  if (headerSize == 14) {
    final hc = view.getUint16(12, Endian.little);
    if (hc != 0 && hc != _crc16(data, 0, 12)) _fail('CRC do cabecalho FIT invalido');
  }
  if (view.getUint16(end, Endian.little) != _crc16(data, 0, end)) {
    _fail('CRC do arquivo FIT invalido (corrompido)');
  }

  final defs = <int, _Def>{};
  final points = <ParsedPoint>[];
  String? sessionSport;
  String? sportMsgSport;
  String? sportMsgName;
  int? sessionStart;
  int? sessionTimer;
  int? sessionElapsed;
  double? sessionDistance;
  int? lastTimestamp;
  final pauses = <TimerPause>[];
  int? stoppedAt;

  var pos = headerSize;
  while (pos < end) {
    final h = data[pos++];
    int? compressedTs;
    _Def def;
    if ((h & 0x80) != 0) {
      final local = (h >> 5) & 0x03;
      def = defs[local] ?? _fail('FIT mal formado (dado sem definicao)');
      final offset = h & 0x1F;
      final last = lastTimestamp ?? _fail('FIT mal formado (timestamp comprimido sem base)');
      var ts = (last & ~0x1F) + offset;
      if (offset < (last & 0x1F)) ts += 0x20;
      compressedTs = ts;
    } else if ((h & 0x40) != 0) {
      pos = _readDef(data, view, pos, end, h & 0x0F, (h & 0x20) != 0, defs);
      continue;
    } else {
      def = defs[h & 0x0F] ?? _fail('FIT mal formado (dado sem definicao)');
    }
    if (pos + def.totalSize > end) _fail('arquivo FIT truncado');

    int? u(int field) => _unsigned(view, pos, def, field);
    final ts = compressedTs ?? u(253);
    if (ts != null) lastTimestamp = ts;
    int? tsMs(int? fitSeconds) =>
        fitSeconds == null ? null : (fitSeconds + _fitEpochOffsetSeconds) * 1000;

    switch (def.global) {
      case _msgRecord:
        final lat = _signed(view, pos, def, 0);
        final lon = _signed(view, pos, def, 1);
        final enhancedAlt = u(78);
        final alt = enhancedAlt ?? u(2);
        final enhancedSpeed = u(73);
        final speed = enhancedSpeed ?? u(6);
        points.add(ParsedPoint(
          timeMs: tsMs(ts),
          latitude: lat == null ? null : lat * _degreesPerSemicircle,
          longitude: lon == null ? null : lon * _degreesPerSemicircle,
          altitudeMeters: alt == null ? null : alt / 5.0 - 500.0,
          speedMetersPerSecond: speed == null ? null : speed / 1000.0,
        ));
      case _msgSession:
        sessionSport ??= _sportName(u(5));
        sessionStart ??= tsMs(u(2));
        final timer = u(8);
        final elapsed = u(7);
        final dist = u(9);
        if (timer != null) sessionTimer = (sessionTimer ?? 0) + timer;
        if (elapsed != null) sessionElapsed = (sessionElapsed ?? 0) + elapsed;
        if (dist != null) sessionDistance = (sessionDistance ?? 0) + dist / 100.0;
      case _msgSport:
        sportMsgSport ??= _sportName(u(0));
        sportMsgName ??= _string(data, pos, def, 3);
      case _msgEvent:
        final t = tsMs(ts);
        if (u(0) == 0 && t != null) {
          final type = u(1);
          if (type == 0) {
            if (stoppedAt != null && t > stoppedAt) pauses.add(TimerPause(stoppedAt, t));
            stoppedAt = null;
          } else if (type == 1 || type == 4 || type == 8 || type == 9) {
            stoppedAt ??= t;
          }
        }
    }
    pos += def.totalSize;
  }

  return ParsedActivity(
    format: ImportFormat.fit,
    sportName: sessionSport ?? sportMsgSport,
    name: sportMsgName,
    startMs: sessionStart,
    points: points,
    timerMs: sessionTimer,
    elapsedMs: sessionElapsed,
    distanceMeters: sessionDistance,
    timerPauses: pauses,
  );
}

int _readDef(
  Uint8List data,
  ByteData view,
  int pos,
  int end,
  int local,
  bool dev,
  Map<int, _Def> defs,
) {
  if (pos + 5 > end) _fail('arquivo FIT truncado');
  final arch = data[pos + 1];
  if (arch > 1) _fail('FIT mal formado (arquitetura)');
  final endian = arch == 0 ? Endian.little : Endian.big;
  final global = view.getUint16(pos + 2, endian);
  final n = data[pos + 4];
  pos += 5;
  if (pos + n * 3 > end) _fail('arquivo FIT truncado');
  final fields = <int, _Field>{};
  var size = 0;
  for (var i = 0; i < n; i++) {
    final f = _Field(data[pos], data[pos + 1], data[pos + 2], size);
    fields.putIfAbsent(f.number, () => f);
    size += f.size;
    pos += 3;
  }
  if (dev) {
    if (pos + 1 > end) _fail('arquivo FIT truncado');
    final nd = data[pos++];
    if (pos + nd * 3 > end) _fail('arquivo FIT truncado');
    for (var i = 0; i < nd; i++) {
      size += data[pos + 1];
      pos += 3;
    }
  }
  defs[local] = _Def(global, endian, fields, size);
  return pos;
}

/// Inteiro sem sinal do campo [number]; null se ausente ou "invalido".
int? _unsigned(ByteData view, int base, _Def def, int number) {
  final f = def.fields[number];
  if (f == null) return null;
  final o = base + f.offset;
  switch (f.size) {
    case 1:
      final v = view.getUint8(o);
      return v == 0xFF ? null : v;
    case 2:
      final v = view.getUint16(o, def.endian);
      return v == 0xFFFF ? null : v;
    case 4:
      final v = view.getUint32(o, def.endian);
      return v == 0xFFFFFFFF ? null : v;
    default:
      return null;
  }
}

/// Inteiro de 32 bits com sinal (semicirculos); null se ausente ou invalido.
int? _signed(ByteData view, int base, _Def def, int number) {
  final f = def.fields[number];
  if (f == null || f.size != 4) return null;
  final v = view.getInt32(base + f.offset, def.endian);
  return v == 0x7FFFFFFF ? null : v;
}

String? _string(Uint8List data, int base, _Def def, int number) {
  final f = def.fields[number];
  if (f == null || (f.baseType & 0x1F) != 0x07) return null;
  final raw = data.sublist(base + f.offset, base + f.offset + f.size);
  final zero = raw.indexOf(0);
  final s = utf8.decode(zero < 0 ? raw : raw.sublist(0, zero), allowMalformed: true).trim();
  return s.isEmpty ? null : s;
}

String? _sportName(int? code) {
  if (code == null || code == 0) return null;
  return _sportNames[code] ?? 'sport_$code';
}
