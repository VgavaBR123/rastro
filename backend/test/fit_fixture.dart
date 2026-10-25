// Gerador minimo de arquivo FIT para os testes.
//
// Segue exatamente a mesma estrutura do codificador do app (header de 14
// bytes, file_id, definicao de record com 6 campos e CRC-16 final). Existe
// aqui para os testes do backend nao dependerem do pacote do app.
import 'dart:typed_data';

const int _epochOffset = 631065600;
const double _semicirclesPerDegree = 2147483648.0 / 180.0;

const List<int> _crcTable = <int>[
  0x0000, 0xCC01, 0xD801, 0x1400, //
  0xF001, 0x3C00, 0x2800, 0xE401, //
  0xA001, 0x6C00, 0x7800, 0xB401, //
  0x5000, 0x9C01, 0x8801, 0x4400, //
];

int crc16Fit(List<int> bytes, [int crc = 0]) {
  for (final int rawByte in bytes) {
    final int byte = rawByte & 0xFF;
    int tmp = _crcTable[crc & 0x0F];
    crc = (crc >> 4) & 0x0FFF;
    crc = crc ^ tmp ^ _crcTable[byte & 0x0F];
    tmp = _crcTable[crc & 0x0F];
    crc = (crc >> 4) & 0x0FFF;
    crc = crc ^ tmp ^ _crcTable[(byte >> 4) & 0x0F];
  }
  return crc & 0xFFFF;
}

/// Ponto de entrada do gerador de fixture.
class Ponto {
  final int timestampUnixMs;
  final double? latitude;
  final double? longitude;
  final double? altitudeMeters;
  final double distanciaMetros;

  const Ponto({
    required this.timestampUnixMs,
    this.latitude,
    this.longitude,
    this.altitudeMeters,
    this.distanciaMetros = 0,
  });
}

class Sink2 {
  final List<int> _out = <int>[];
  void u8(int v) => _out.add(v & 0xFF);
  void u16(int v) {
    _out.add(v & 0xFF);
    _out.add((v >> 8) & 0xFF);
  }

  void u32(int v) {
    _out.add(v & 0xFF);
    _out.add((v >> 8) & 0xFF);
    _out.add((v >> 16) & 0xFF);
    _out.add((v >> 24) & 0xFF);
  }

  void s32(int v) {
    final ByteData bd = ByteData(4)..setInt32(0, v, Endian.little);
    _out.addAll(bd.buffer.asUint8List());
  }

  void raw(List<int> b) => _out.addAll(b);
  List<int> get bytes => _out;
}

/// Envelopa [dataBytes] com header de 14 bytes e CRC final.
Uint8List envelopeFit(List<int> dataBytes) {
  final Sink2 h = Sink2();
  h.u8(14);
  h.u8(0x20);
  h.u16(2100);
  h.u32(dataBytes.length);
  h.raw(<int>[0x2E, 0x46, 0x49, 0x54]);
  h.u16(crc16Fit(h.bytes));

  final List<int> content = <int>[...h.bytes, ...dataBytes];
  final int fileCrc = crc16Fit(content);
  return Uint8List.fromList(
      <int>[...content, fileCrc & 0xFF, (fileCrc >> 8) & 0xFF]);
}

/// Gera um arquivo FIT igual ao que o app produz.
Uint8List gerarFit({
  required int startTimeUnixMs,
  required List<Ponto> pontos,
}) {
  final Sink2 d = Sink2();

  // Definicao de file_id (local type 0).
  d.u8(0x40);
  d.u8(0);
  d.u8(0);
  d.u16(0); // global file_id
  d.u8(4);
  d.raw(<int>[0, 1, 0x02]);
  d.raw(<int>[1, 2, 0x84]);
  d.raw(<int>[2, 2, 0x84]);
  d.raw(<int>[4, 4, 0x86]);
  // Dado de file_id.
  d.u8(0);
  d.u8(4);
  d.u16(255);
  d.u16(0);
  d.u32((startTimeUnixMs ~/ 1000) - _epochOffset);

  // Definicao de record (local type 1).
  d.u8(0x41);
  d.u8(0);
  d.u8(0);
  d.u16(20); // global record
  d.u8(6);
  d.raw(<int>[253, 4, 0x86]); // timestamp uint32
  d.raw(<int>[0, 4, 0x85]); // position_lat sint32
  d.raw(<int>[1, 4, 0x85]); // position_long sint32
  d.raw(<int>[2, 2, 0x84]); // altitude uint16
  d.raw(<int>[5, 4, 0x86]); // distance uint32
  d.raw(<int>[6, 2, 0x84]); // speed uint16

  for (final Ponto p in pontos) {
    d.u8(0x01);
    d.u32((p.timestampUnixMs ~/ 1000) - _epochOffset);
    d.s32(p.latitude == null
        ? 0x7FFFFFFF
        : (p.latitude! * _semicirclesPerDegree).round());
    d.s32(p.longitude == null
        ? 0x7FFFFFFF
        : (p.longitude! * _semicirclesPerDegree).round());
    d.u16(p.altitudeMeters == null
        ? 0xFFFF
        : ((p.altitudeMeters! + 500.0) * 5.0).round() & 0xFFFF);
    d.u32((p.distanciaMetros * 100.0).round() & 0xFFFFFFFF);
    d.u16(0xFFFF);
  }

  return envelopeFit(d.bytes);
}

/// Rota sintetica com [n] pontos a partir de [t0].
List<Ponto> rotaSintetica(int n, int t0) => <Ponto>[
      for (int i = 0; i < n; i++)
        Ponto(
          timestampUnixMs: t0 + i * 1000,
          latitude: -23.561 + i * 0.0001,
          longitude: -46.656 - i * 0.00015,
          altitudeMeters: 740.0 + i,
          distanciaMetros: i * 12.5,
        ),
    ];
