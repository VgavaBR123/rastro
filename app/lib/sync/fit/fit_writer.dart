// Codificador de arquivo FIT (Flexible and Interoperable Data Transfer) em
// Dart puro.
//
// FIT e o formato aberto e publico da industria de fitness para troca de
// atividades. Este codificador foi derivado da especificacao publica do
// formato e do relatorio relatorios/06-sincronizacao.md (clean room): ele
// monta um arquivo minimo porem valido com as mensagens file_id e record,
// suficiente para exportar uma atividade gravada (corrida, pedal, caminhada).
//
// Layout do arquivo:
//   Header (14 bytes) + Data Records + CRC-16 final (2 bytes).
// O CRC final cobre todo o conteudo (header + data records).
library;

import 'dart:typed_data';

import 'fit_crc.dart';

/// Offset entre o epoch Unix (1970-01-01) e o epoch FIT (1989-12-31 00:00:00
/// UTC), em segundos. Para converter um instante Unix em segundos FIT basta
/// subtrair este valor.
const int fitEpochOffsetSeconds = 631065600;

/// Fator de conversao de graus para semicirculos: 2^31 / 180.
const double _semicirclesPerDegree = 2147483648.0 / 180.0;

// Base types do FIT (byte identificador na definicao de campo).
const int _baseTypeUint8 = 0x02;
const int _baseTypeUint16 = 0x84;
const int _baseTypeSint32 = 0x85;
const int _baseTypeUint32 = 0x86;

// Valores "invalid" por tipo (usados quando um campo opcional nao tem dado).
const int _invalidUint16 = 0xFFFF;

// Local message types reservados neste codificador.
const int _localTypeFileId = 0;
const int _localTypeRecord = 1;

// Global message numbers.
const int _globalFileId = 0;
const int _globalRecord = 20;

/// Converte graus (latitude/longitude) em semicirculos (sint32).
int degreesToSemicircles(double degrees) =>
    (degrees * _semicirclesPerDegree).round();

/// Converte milissegundos Unix em segundos do epoch FIT (uint32).
int unixMsToFitSeconds(int unixMs) =>
    (unixMs ~/ 1000) - fitEpochOffsetSeconds;

/// Um ponto da atividade (mensagem `record` do FIT).
class FitRecord {
  final int timestampUnixMs;
  final double latitude;
  final double longitude;
  final double? altitudeMeters;
  final double cumulativeDistanceMeters;
  final double? speedMetersPerSecond;

  const FitRecord({
    required this.timestampUnixMs,
    required this.latitude,
    required this.longitude,
    required this.cumulativeDistanceMeters,
    this.altitudeMeters,
    this.speedMetersPerSecond,
  });
}

/// Pequeno acumulador de bytes com helpers little-endian.
class _ByteSink {
  final BytesBuilder _builder = BytesBuilder(copy: false);

  int get length => _builder.length;

  void u8(int v) => _builder.addByte(v & 0xFF);

  void u16(int v) {
    final ByteData bd = ByteData(2)..setUint16(0, v & 0xFFFF, Endian.little);
    _builder.add(bd.buffer.asUint8List());
  }

  void u32(int v) {
    // Mascara para 32 bits antes de gravar (aceita valores "invalid").
    final ByteData bd = ByteData(4)
      ..setUint32(0, v & 0xFFFFFFFF, Endian.little);
    _builder.add(bd.buffer.asUint8List());
  }

  void s32(int v) {
    final ByteData bd = ByteData(4)..setInt32(0, v, Endian.little);
    _builder.add(bd.buffer.asUint8List());
  }

  void raw(List<int> bytes) => _builder.add(bytes);

  Uint8List toBytes() => _builder.toBytes();
}

/// Escreve a definicao da mensagem `file_id` (local type 0).
void _writeFileIdDefinition(_ByteSink sink) {
  sink.u8(0x40 | _localTypeFileId); // header de definicao
  sink.u8(0); // reserved
  sink.u8(0); // architecture: 0 = little-endian
  sink.u16(_globalFileId); // global message number
  sink.u8(4); // numero de campos
  // field def: (field def num, size, base type)
  sink.raw(<int>[0, 1, _baseTypeUint8]); // type
  sink.raw(<int>[1, 2, _baseTypeUint16]); // manufacturer
  sink.raw(<int>[2, 2, _baseTypeUint16]); // product
  sink.raw(<int>[4, 4, _baseTypeUint32]); // time_created
}

/// Escreve os dados da mensagem `file_id` (local type 0).
void _writeFileIdData(_ByteSink sink, int timeCreatedFit) {
  sink.u8(_localTypeFileId); // header de dado (bit7=0)
  sink.u8(4); // type = 4 (activity)
  sink.u16(255); // manufacturer = 255 (development)
  sink.u16(0); // product = 0
  sink.u32(timeCreatedFit); // time_created em segundos FIT
}

/// Escreve a definicao da mensagem `record` (local type 1).
void _writeRecordDefinition(_ByteSink sink) {
  sink.u8(0x40 | _localTypeRecord);
  sink.u8(0); // reserved
  sink.u8(0); // architecture: little-endian
  sink.u16(_globalRecord);
  sink.u8(6); // numero de campos
  sink.raw(<int>[253, 4, _baseTypeUint32]); // timestamp
  sink.raw(<int>[0, 4, _baseTypeSint32]); // position_lat
  sink.raw(<int>[1, 4, _baseTypeSint32]); // position_long
  sink.raw(<int>[2, 2, _baseTypeUint16]); // altitude
  sink.raw(<int>[5, 4, _baseTypeUint32]); // distance
  sink.raw(<int>[6, 2, _baseTypeUint16]); // speed
}

/// Escreve um dado da mensagem `record` (local type 1).
void _writeRecordData(_ByteSink sink, FitRecord r) {
  sink.u8(_localTypeRecord); // header de dado

  sink.u32(unixMsToFitSeconds(r.timestampUnixMs)); // timestamp
  sink.s32(degreesToSemicircles(r.latitude)); // position_lat
  sink.s32(degreesToSemicircles(r.longitude)); // position_long

  // altitude: (m + 500) * 5, uint16; invalid quando ausente.
  if (r.altitudeMeters != null) {
    sink.u16(((r.altitudeMeters! + 500.0) * 5.0).round() & 0xFFFF);
  } else {
    sink.u16(_invalidUint16);
  }

  // distance: metros acumulados * 100, uint32.
  sink.u32((r.cumulativeDistanceMeters * 100.0).round() & 0xFFFFFFFF);

  // speed: m/s * 1000, uint16; invalid quando ausente.
  if (r.speedMetersPerSecond != null) {
    sink.u16((r.speedMetersPerSecond! * 1000.0).round() & 0xFFFF);
  } else {
    sink.u16(_invalidUint16);
  }
}

/// Codifica uma atividade em um arquivo FIT completo.
///
/// Monta header + file_id + definicao de record + todas as data records,
/// preenche o data size no header e anexa o CRC-16 final sobre
/// header(14) + data records.
Uint8List encodeActivityFit({
  required int startTimeUnixMs,
  required List<FitRecord> records,
}) {
  // 1) Monta as data records num buffer separado para medir o data size.
  final _ByteSink data = _ByteSink();
  _writeFileIdDefinition(data);
  _writeFileIdData(data, unixMsToFitSeconds(startTimeUnixMs));
  _writeRecordDefinition(data);
  for (final FitRecord r in records) {
    _writeRecordData(data, r);
  }
  final Uint8List dataBytes = data.toBytes();
  final int dataSize = dataBytes.length;

  // 2) Monta o header de 14 bytes.
  final _ByteSink header = _ByteSink();
  header.u8(14); // tamanho do header
  header.u8(0x20); // protocol version
  header.u16(2100); // profile version
  header.u32(dataSize); // data size (so as data records)
  header.raw(<int>[0x2E, 0x46, 0x49, 0x54]); // ".FIT"
  final Uint8List headerFirst12 = header.toBytes();
  final int headerCrc = fitCrc16(headerFirst12);
  header.u16(headerCrc); // CRC-16 do proprio header
  final Uint8List headerBytes = header.toBytes();

  // 3) Concatena header + dados e calcula o CRC-16 final sobre tudo.
  final _ByteSink file = _ByteSink();
  file.raw(headerBytes);
  file.raw(dataBytes);
  final Uint8List contentBytes = file.toBytes();
  final int fileCrc = fitCrc16(contentBytes);
  file.u16(fileCrc);

  return file.toBytes();
}
