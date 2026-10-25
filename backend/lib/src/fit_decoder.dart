// Decodificador de arquivo FIT (Flexible and Interoperable Data Transfer) em
// Dart puro, lado servidor.
//
// Le o arquivo enviado pelo app (header de 12 ou 14 bytes + data records +
// CRC-16 final) e extrai apenas o que o backend precisa: a lista de pontos da
// rota (mensagem global `record`, numero 20) com timestamp, latitude,
// longitude e altitude quando existir.
//
// O decodificador foi escrito a partir da especificacao publica do formato FIT
// (mesma base do codificador do app) e e deliberadamente defensivo: qualquer
// arquivo truncado, header invalido ou CRC errado resulta em
// [FitDecodeException] em vez de RangeError.
library;

import 'dart:math';
import 'dart:typed_data';

/// Offset entre o epoch Unix (1970-01-01) e o epoch FIT (1989-12-31 00:00:00
/// UTC), em segundos.
const int fitEpochOffsetSeconds = 631065600;

/// Fator de conversao de semicirculos para graus: 180 / 2^31.
const double _degreesPerSemicircle = 180.0 / 2147483648.0;

/// Global message number da mensagem `record`.
const int _globalRecord = 20;

// Numeros dos campos da mensagem `record` que nos interessam.
const int _fieldTimestamp = 253;
const int _fieldPositionLat = 0;
const int _fieldPositionLong = 1;
const int _fieldAltitude = 2;

// Valores "invalid" do FIT por tipo.
const int _invalidUint16 = 0xFFFF;
const int _invalidUint32 = 0xFFFFFFFF;
const int _invalidSint32 = 0x7FFFFFFF;

/// Limite de semicirculos correspondente a 90 graus de latitude.
const int _maxLatSemicircles = 1073741824; // 2^30

/// Erro de decodificacao do FIT. Mensagem sempre descreve o motivo.
class FitDecodeException implements Exception {
  final String message;
  const FitDecodeException(this.message);

  @override
  String toString() => 'FitDecodeException: $message';
}

/// Um ponto da rota extraido de uma mensagem `record`.
class FitTrackPoint {
  /// Instante do ponto, em UTC.
  final DateTime timestamp;

  /// Latitude em graus.
  final double latitude;

  /// Longitude em graus.
  final double longitude;

  /// Altitude em metros, quando o campo estava presente e valido.
  final double? altitudeMeters;

  const FitTrackPoint({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.altitudeMeters,
  });

  /// Milissegundos Unix do ponto (conveniencia).
  int get timestampUnixMs => timestamp.millisecondsSinceEpoch;

  @override
  String toString() =>
      'FitTrackPoint($latitude, $longitude, ${timestamp.toIso8601String()}'
      '${altitudeMeters != null ? ', alt=$altitudeMeters' : ''})';
}

/// Tabela de 16 entradas do CRC-16 do FIT (indexada por nibble).
const List<int> _crcTable = <int>[
  0x0000, 0xCC01, 0xD801, 0x1400, //
  0xF001, 0x3C00, 0x2800, 0xE401, //
  0xA001, 0x6C00, 0x7800, 0xB401, //
  0x5000, 0x9C01, 0x8801, 0x4400, //
];

/// CRC-16 do FIT sobre [bytes], de [start] (inclusive) a [end] (exclusive).
int _crc16(Uint8List bytes, int start, int end) {
  int crc = 0;
  for (int i = start; i < end; i++) {
    final int byte = bytes[i];
    int tmp = _crcTable[crc & 0x0F];
    crc = (crc >> 4) & 0x0FFF;
    crc = crc ^ tmp ^ _crcTable[byte & 0x0F];
    tmp = _crcTable[crc & 0x0F];
    crc = (crc >> 4) & 0x0FFF;
    crc = crc ^ tmp ^ _crcTable[(byte >> 4) & 0x0F];
  }
  return crc & 0xFFFF;
}

/// Descricao de um campo dentro de uma definition message.
class _FieldDef {
  final int number;
  final int size;
  final int baseType;
  const _FieldDef(this.number, this.size, this.baseType);

  /// Tamanho em bytes de um elemento do base type (0 = desconhecido).
  int get elementSize {
    switch (baseType & 0x1F) {
      case 0x00: // enum
      case 0x01: // sint8
      case 0x02: // uint8
      case 0x07: // string
      case 0x0A: // uint8z
      case 0x0D: // byte
        return 1;
      case 0x03: // sint16
      case 0x04: // uint16
      case 0x0B: // uint16z
        return 2;
      case 0x05: // sint32
      case 0x06: // uint32
      case 0x08: // float32
      case 0x0C: // uint32z
        return 4;
      case 0x09: // float64
      case 0x0E: // sint64
      case 0x0F: // uint64
      case 0x10: // uint64z
        return 8;
      default:
        return 0;
    }
  }
}

/// Definicao de uma mensagem local (local message type 0..15).
class _MessageDef {
  final int globalNumber;
  final Endian endian;
  final List<_FieldDef> fields;
  final int totalSize;
  const _MessageDef(
      this.globalNumber, this.endian, this.fields, this.totalSize);
}

/// Decodifica os pontos da rota de um arquivo FIT.
///
/// Lanca [FitDecodeException] se o arquivo estiver vazio, com header invalido,
/// truncado, com CRC invalido ou sem nenhuma mensagem `record` com posicao.
/// Pontos com lat/lon marcados como "invalid" pelo FIT sao ignorados.
List<FitTrackPoint> decodeFitRecords(List<int> bytes) {
  final Uint8List data =
      bytes is Uint8List ? bytes : Uint8List.fromList(bytes);

  if (data.isEmpty) {
    throw const FitDecodeException('arquivo vazio');
  }
  if (data.length < 14) {
    throw const FitDecodeException(
        'arquivo menor que o header minimo do FIT (14 bytes)');
  }

  final int headerSize = data[0];
  if (headerSize != 12 && headerSize != 14) {
    throw FitDecodeException(
        'tamanho de header invalido: $headerSize (esperado 12 ou 14)');
  }
  // Assinatura ".FIT" nos bytes 8..11.
  if (data[8] != 0x2E ||
      data[9] != 0x46 ||
      data[10] != 0x49 ||
      data[11] != 0x54) {
    throw const FitDecodeException('assinatura ".FIT" ausente no header');
  }

  final ByteData view = ByteData.sublistView(data);
  final int dataSize = view.getUint32(4, Endian.little);
  if (dataSize <= 0) {
    throw const FitDecodeException('data size do header e zero');
  }

  // Precisa de header + data records + CRC final (2 bytes).
  final int minLength = headerSize + dataSize + 2;
  if (data.length < minLength) {
    throw FitDecodeException(
        'arquivo truncado: esperados $minLength bytes, encontrados '
        '${data.length}');
  }

  // CRC do proprio header (quando header de 14 bytes e CRC diferente de 0).
  if (headerSize == 14) {
    final int headerCrc = view.getUint16(12, Endian.little);
    if (headerCrc != 0 && headerCrc != _crc16(data, 0, 12)) {
      throw const FitDecodeException('CRC do header invalido');
    }
  }

  // CRC final cobre header + data records.
  final int fileCrcOffset = headerSize + dataSize;
  final int fileCrc = view.getUint16(fileCrcOffset, Endian.little);
  if (fileCrc != _crc16(data, 0, fileCrcOffset)) {
    throw const FitDecodeException('CRC final do arquivo invalido');
  }

  final List<FitTrackPoint> points = <FitTrackPoint>[];
  final Map<int, _MessageDef> defs = <int, _MessageDef>{};

  int pos = headerSize;
  final int end = fileCrcOffset;

  while (pos < end) {
    final int recordHeader = data[pos];
    pos++;

    final bool compressed = (recordHeader & 0x80) != 0;
    if (compressed) {
      // Compressed timestamp header: local type nos bits 5-6. Nao geramos
      // esse formato, mas sabemos pular o dado se a definicao for conhecida.
      final int localType = (recordHeader >> 5) & 0x03;
      final _MessageDef? def = defs[localType];
      if (def == null) {
        throw FitDecodeException(
            'dado comprimido sem definicao para o local type $localType');
      }
      pos = _consumeData(data, pos, end, def, points, timestampOverride: null);
      continue;
    }

    final int localType = recordHeader & 0x0F;
    final bool isDefinition = (recordHeader & 0x40) != 0;
    final bool hasDevFields = (recordHeader & 0x20) != 0;

    if (isDefinition) {
      pos = _readDefinition(data, pos, end, localType, hasDevFields, defs);
    } else {
      final _MessageDef? def = defs[localType];
      if (def == null) {
        throw FitDecodeException(
            'dado sem definicao previa para o local type $localType');
      }
      pos = _consumeData(data, pos, end, def, points, timestampOverride: null);
    }
  }

  if (points.isEmpty) {
    throw const FitDecodeException(
        'nenhuma mensagem record com posicao valida no arquivo');
  }
  return points;
}

/// Le uma definition message a partir de [pos] e registra em [defs].
/// Devolve a nova posicao.
int _readDefinition(
  Uint8List data,
  int pos,
  int end,
  int localType,
  bool hasDevFields,
  Map<int, _MessageDef> defs,
) {
  // reserved(1) + architecture(1) + global number(2) + num fields(1)
  _require(pos + 5 <= end, 'definition message truncada');
  final int arch = data[pos + 1];
  if (arch != 0 && arch != 1) {
    throw FitDecodeException('architecture invalida na definicao: $arch');
  }
  final Endian endian = arch == 0 ? Endian.little : Endian.big;
  final ByteData view = ByteData.sublistView(data);
  final int globalNumber = view.getUint16(pos + 2, endian);
  final int numFields = data[pos + 4];
  pos += 5;

  _require(pos + numFields * 3 <= end,
      'lista de campos da definicao truncada (global $globalNumber)');

  final List<_FieldDef> fields = <_FieldDef>[];
  int totalSize = 0;
  for (int i = 0; i < numFields; i++) {
    final _FieldDef f =
        _FieldDef(data[pos], data[pos + 1], data[pos + 2]);
    fields.add(f);
    totalSize += f.size;
    pos += 3;
  }

  if (hasDevFields) {
    _require(pos + 1 <= end, 'contador de developer fields truncado');
    final int numDev = data[pos];
    pos++;
    _require(pos + numDev * 3 <= end, 'developer fields truncados');
    for (int i = 0; i < numDev; i++) {
      // Developer fields nao sao interpretados, apenas o tamanho importa.
      totalSize += data[pos + 1];
      pos += 3;
    }
  }

  if (totalSize <= 0) {
    throw FitDecodeException(
        'definicao sem campos de dado (global $globalNumber)');
  }

  defs[localType] = _MessageDef(globalNumber, endian, fields, totalSize);
  return pos;
}

/// Consome um data message segundo [def]; se for `record`, extrai o ponto.
/// Devolve a nova posicao.
int _consumeData(
  Uint8List data,
  int pos,
  int end,
  _MessageDef def,
  List<FitTrackPoint> points, {
  int? timestampOverride,
}) {
  _require(pos + def.totalSize <= end,
      'data message truncada (global ${def.globalNumber})');

  if (def.globalNumber != _globalRecord) {
    return pos + def.totalSize;
  }

  final ByteData view = ByteData.sublistView(data);
  int? timestampFit = timestampOverride;
  int? latRaw;
  int? lonRaw;
  int? altRaw;

  int offset = pos;
  for (final _FieldDef f in def.fields) {
    final int fieldStart = offset;
    offset += f.size;
    switch (f.number) {
      case _fieldTimestamp:
        timestampFit =
            _readUnsigned(view, fieldStart, f, def.endian) ?? timestampFit;
        break;
      case _fieldPositionLat:
        latRaw = _readSigned(view, fieldStart, f, def.endian);
        break;
      case _fieldPositionLong:
        lonRaw = _readSigned(view, fieldStart, f, def.endian);
        break;
      case _fieldAltitude:
        altRaw = _readUnsigned(view, fieldStart, f, def.endian);
        break;
      default:
        break;
    }
  }

  final int newPos = pos + def.totalSize;

  // Sem posicao valida ou sem timestamp: ponto ignorado (nao e erro).
  if (latRaw == null || lonRaw == null || timestampFit == null) {
    return newPos;
  }
  if (latRaw == _invalidSint32 || lonRaw == _invalidSint32) {
    return newPos;
  }
  if (timestampFit == _invalidUint32) {
    return newPos;
  }
  if (latRaw.abs() > _maxLatSemicircles) {
    return newPos; // latitude fora de -90..90
  }

  final double lat = latRaw * _degreesPerSemicircle;
  final double lon = lonRaw * _degreesPerSemicircle;
  if (lat.isNaN || lon.isNaN || lat < -90 || lat > 90 || lon < -180 || lon > 180) {
    return newPos;
  }

  double? altitude;
  if (altRaw != null && altRaw != _invalidUint16 && altRaw != _invalidUint32) {
    // Escala do FIT para altitude: valor = (metros + 500) * 5.
    altitude = altRaw / 5.0 - 500.0;
  }

  points.add(FitTrackPoint(
    timestamp: DateTime.fromMillisecondsSinceEpoch(
      (timestampFit + fitEpochOffsetSeconds) * 1000,
      isUtc: true,
    ),
    latitude: lat,
    longitude: lon,
    altitudeMeters: altitude,
  ));
  return newPos;
}

/// Le um campo como inteiro sem sinal (1, 2 ou 4 bytes). Devolve null quando o
/// tamanho nao e interpretavel.
int? _readUnsigned(ByteData view, int offset, _FieldDef f, Endian endian) {
  final int size = f.elementSize == 0 ? f.size : f.elementSize;
  switch (size) {
    case 1:
      return view.getUint8(offset);
    case 2:
      return view.getUint16(offset, endian);
    case 4:
      return view.getUint32(offset, endian);
    default:
      return null;
  }
}

/// Le um campo como inteiro com sinal (1, 2 ou 4 bytes).
int? _readSigned(ByteData view, int offset, _FieldDef f, Endian endian) {
  final int size = f.elementSize == 0 ? f.size : f.elementSize;
  switch (size) {
    case 1:
      return view.getInt8(offset);
    case 2:
      return view.getInt16(offset, endian);
    case 4:
      return view.getInt32(offset, endian);
    default:
      return null;
  }
}

void _require(bool condition, String message) {
  if (!condition) {
    throw FitDecodeException(message);
  }
}

/// Raio medio da Terra em metros (esfera), usado no calculo de distancia.
const double _raioTerraMetros = 6371008.8;

/// Comprimento da linha formada por [pontos], em metros.
///
/// Soma de distancias haversine entre pontos consecutivos. E o equivalente
/// "em memoria" do `ST_Length(route::geography)` do PostGIS; o PostGIS mede
/// sobre o elipsoide WGS84, entao os dois valores diferem em cerca de 0,2%.
/// Menos de 2 pontos: devolve 0.
double comprimentoMetros(List<FitTrackPoint> pontos) {
  if (pontos.length < 2) return 0;
  double total = 0;
  for (int i = 1; i < pontos.length; i++) {
    total += _distanciaHaversine(pontos[i - 1], pontos[i]);
  }
  return total;
}

double _distanciaHaversine(FitTrackPoint a, FitTrackPoint b) {
  final double grausParaRad = pi / 180.0;
  final double lat1 = a.latitude * grausParaRad;
  final double lat2 = b.latitude * grausParaRad;
  final double dLat = lat2 - lat1;
  final double dLon = (b.longitude - a.longitude) * grausParaRad;
  final double sinLat = sin(dLat / 2);
  final double sinLon = sin(dLon / 2);
  final double h = sinLat * sinLat + cos(lat1) * cos(lat2) * sinLon * sinLon;
  return 2 * _raioTerraMetros * asin(sqrt(h < 1.0 ? h : 1.0));
}

/// Resultado da tentativa de extrair a rota de um arquivo FIT.
///
/// [wkt] e o LINESTRING pronto para o PostGIS, ou null quando nao da para
/// montar uma linha (decodificacao falhou ou menos de 2 pontos).
/// [erro] descreve o motivo quando [wkt] e null por causa de falha.
class RotaDecodificada {
  final String? wkt;
  final int pointCount;
  final String? erro;

  const RotaDecodificada({
    required this.wkt,
    required this.pointCount,
    this.erro,
  });
}

/// Decodifica [fitBytes] e devolve o LINESTRING da rota, sem nunca lancar.
///
/// Pensado para o caminho de upload: o arquivo bruto ja esta salvo, entao um
/// FIT ilegivel apenas deixa a geometria vazia em vez de derrubar a requisicao.
RotaDecodificada decodificarRota(List<int> fitBytes) {
  List<FitTrackPoint> pontos;
  try {
    pontos = decodeFitRecords(fitBytes);
  } on FitDecodeException catch (e) {
    return RotaDecodificada(wkt: null, pointCount: 0, erro: e.message);
  } catch (e) {
    // Rede de seguranca: nenhum erro inesperado deve vazar daqui.
    return RotaDecodificada(wkt: null, pointCount: 0, erro: e.toString());
  }

  if (pontos.length < 2) {
    return RotaDecodificada(
      wkt: null,
      pointCount: pontos.length,
      erro: 'menos de 2 pontos com posicao valida',
    );
  }

  final StringBuffer sb = StringBuffer('LINESTRING(');
  for (int i = 0; i < pontos.length; i++) {
    if (i > 0) sb.write(', ');
    // PostGIS espera a ordem (longitude latitude) no SRID 4326.
    sb.write(pontos[i].longitude.toStringAsFixed(7));
    sb.write(' ');
    sb.write(pontos[i].latitude.toStringAsFixed(7));
  }
  sb.write(')');

  return RotaDecodificada(wkt: sb.toString(), pointCount: pontos.length);
}
