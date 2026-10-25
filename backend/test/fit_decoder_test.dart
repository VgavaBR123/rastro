// Testes do decodificador FIT do backend.
//
// O fixture abaixo e um gerador minimo de arquivo FIT que segue exatamente a
// mesma estrutura do codificador do app (header de 14 bytes, file_id,
// definicao de record com 6 campos e CRC-16 final). Ele existe aqui para o
// teste nao depender do pacote do app.
import 'dart:typed_data';

import 'package:strava_estudo_backend/src/fit_decoder.dart';
import 'package:test/test.dart';

const int _epochOffset = 631065600;
const double _semicirclesPerDegree = 2147483648.0 / 180.0;

const List<int> _crcTable = <int>[
  0x0000, 0xCC01, 0xD801, 0x1400, //
  0xF001, 0x3C00, 0x2800, 0xE401, //
  0xA001, 0x6C00, 0x7800, 0xB401, //
  0x5000, 0x9C01, 0x8801, 0x4400, //
];

int _crc16(List<int> bytes, [int crc = 0]) {
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

class _Sink {
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

/// Gera um arquivo FIT igual ao que o app produz.
Uint8List gerarFit({
  required int startTimeUnixMs,
  required List<Ponto> pontos,
}) {
  final _Sink d = _Sink();

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

  final List<int> dataBytes = d.bytes;

  final _Sink h = _Sink();
  h.u8(14);
  h.u8(0x20);
  h.u16(2100);
  h.u32(dataBytes.length);
  h.raw(<int>[0x2E, 0x46, 0x49, 0x54]);
  final int headerCrc = _crc16(h.bytes);
  h.u16(headerCrc);

  final List<int> content = <int>[...h.bytes, ...dataBytes];
  final List<int> arquivo = <int>[...content];
  final int fileCrc = _crc16(content);
  arquivo.add(fileCrc & 0xFF);
  arquivo.add((fileCrc >> 8) & 0xFF);
  return Uint8List.fromList(arquivo);
}

void main() {
  const int t0 = 1760000000000; // instante base em ms Unix

  List<Ponto> rota(int n) => <Ponto>[
        for (int i = 0; i < n; i++)
          Ponto(
            timestampUnixMs: t0 + i * 1000,
            latitude: -23.561 + i * 0.0001,
            longitude: -46.656 - i * 0.00015,
            altitudeMeters: 740.0 + i,
            distanciaMetros: i * 12.5,
          ),
      ];

  test('round-trip: N pontos entram, N pontos saem', () {
    final List<Ponto> pontos = rota(25);
    final Uint8List bytes = gerarFit(startTimeUnixMs: t0, pontos: pontos);

    final List<FitTrackPoint> saida = decodeFitRecords(bytes);
    expect(saida.length, pontos.length);

    for (int i = 0; i < pontos.length; i++) {
      expect(saida[i].latitude, closeTo(pontos[i].latitude!, 1e-5));
      expect(saida[i].longitude, closeTo(pontos[i].longitude!, 1e-5));
      expect(saida[i].timestamp.millisecondsSinceEpoch,
          pontos[i].timestampUnixMs);
      expect(saida[i].altitudeMeters,
          closeTo(pontos[i].altitudeMeters!, 0.2));
      expect(saida[i].timestamp.isUtc, isTrue);
    }
  });

  test('ponto unico tambem decodifica', () {
    final Uint8List bytes = gerarFit(startTimeUnixMs: t0, pontos: rota(1));
    expect(decodeFitRecords(bytes).length, 1);
  });

  test('pontos sem lat/lon valida sao ignorados', () {
    final List<Ponto> pontos = <Ponto>[
      Ponto(timestampUnixMs: t0, latitude: -23.5, longitude: -46.6),
      Ponto(timestampUnixMs: t0 + 1000), // lat/lon invalid
      Ponto(timestampUnixMs: t0 + 2000, latitude: -23.51, longitude: -46.61),
    ];
    final Uint8List bytes = gerarFit(startTimeUnixMs: t0, pontos: pontos);
    final List<FitTrackPoint> saida = decodeFitRecords(bytes);
    expect(saida.length, 2);
    expect(saida[1].latitude, closeTo(-23.51, 1e-5));
  });

  test('altitude ausente vira null', () {
    final Uint8List bytes = gerarFit(
      startTimeUnixMs: t0,
      pontos: <Ponto>[
        Ponto(timestampUnixMs: t0, latitude: 10.0, longitude: 20.0),
      ],
    );
    expect(decodeFitRecords(bytes).single.altitudeMeters, isNull);
  });

  test('altitude negativa (abaixo do nivel do mar) sobrevive', () {
    final Uint8List bytes = gerarFit(
      startTimeUnixMs: t0,
      pontos: <Ponto>[
        Ponto(
          timestampUnixMs: t0,
          latitude: 31.5,
          longitude: 35.5,
          altitudeMeters: -200.0,
        ),
      ],
    );
    expect(decodeFitRecords(bytes).single.altitudeMeters, closeTo(-200.0, 0.2));
  });

  test('bytes vazios lancam FitDecodeException', () {
    expect(() => decodeFitRecords(<int>[]),
        throwsA(isA<FitDecodeException>()));
  });

  test('arquivo curto demais lanca FitDecodeException', () {
    expect(() => decodeFitRecords(<int>[14, 0x20, 0, 0]),
        throwsA(isA<FitDecodeException>()));
  });

  test('header invalido (sem assinatura .FIT) lanca FitDecodeException', () {
    final Uint8List bytes = gerarFit(startTimeUnixMs: t0, pontos: rota(3));
    bytes[8] = 0x58; // destroi o '.' da assinatura
    expect(() => decodeFitRecords(bytes), throwsA(isA<FitDecodeException>()));
  });

  test('tamanho de header fora de 12/14 lanca FitDecodeException', () {
    final Uint8List bytes = gerarFit(startTimeUnixMs: t0, pontos: rota(3));
    bytes[0] = 13;
    expect(() => decodeFitRecords(bytes), throwsA(isA<FitDecodeException>()));
  });

  test('arquivo truncado lanca FitDecodeException em vez de RangeError', () {
    final Uint8List bytes = gerarFit(startTimeUnixMs: t0, pontos: rota(10));
    for (final int corte in <int>[20, 40, 60, bytes.length - 1]) {
      final Uint8List parcial = Uint8List.sublistView(bytes, 0, corte);
      expect(
        () => decodeFitRecords(parcial),
        throwsA(isA<FitDecodeException>()),
        reason: 'corte em $corte deveria lancar FitDecodeException',
      );
    }
  });

  test('CRC final invalido lanca FitDecodeException', () {
    final Uint8List bytes = gerarFit(startTimeUnixMs: t0, pontos: rota(3));
    bytes[bytes.length - 1] = bytes[bytes.length - 1] ^ 0xFF;
    expect(() => decodeFitRecords(bytes), throwsA(isA<FitDecodeException>()));
  });

  test('CRC do header invalido lanca FitDecodeException', () {
    final Uint8List bytes = gerarFit(startTimeUnixMs: t0, pontos: rota(3));
    bytes[12] = bytes[12] ^ 0xFF;
    expect(() => decodeFitRecords(bytes), throwsA(isA<FitDecodeException>()));
  });

  test('arquivo sem nenhuma record lanca FitDecodeException', () {
    final Uint8List bytes =
        gerarFit(startTimeUnixMs: t0, pontos: const <Ponto>[]);
    expect(() => decodeFitRecords(bytes), throwsA(isA<FitDecodeException>()));
  });

  group('decodificarRota', () {
    test('monta LINESTRING na ordem lon lat', () {
      final Uint8List bytes = gerarFit(startTimeUnixMs: t0, pontos: rota(3));
      final RotaDecodificada r = decodificarRota(bytes);
      expect(r.pointCount, 3);
      expect(r.erro, isNull);
      expect(r.wkt, startsWith('LINESTRING(-46.656'));
      expect(r.wkt!.split(', ').length, 3);
    });

    test('menos de 2 pontos devolve wkt null sem lancar', () {
      final Uint8List bytes = gerarFit(startTimeUnixMs: t0, pontos: rota(1));
      final RotaDecodificada r = decodificarRota(bytes);
      expect(r.wkt, isNull);
      expect(r.pointCount, 1);
      expect(r.erro, isNotNull);
    });

    test('arquivo invalido devolve wkt null sem lancar', () {
      final RotaDecodificada r = decodificarRota(<int>[1, 2, 3]);
      expect(r.wkt, isNull);
      expect(r.pointCount, 0);
      expect(r.erro, isNotNull);
    });
  });

  test('dado sem definicao previa lanca FitDecodeException', () {
    // Monta um arquivo com um unico data record de local type 3 sem definicao.
    final List<int> dataBytes = <int>[0x03, 0, 0, 0, 0];
    final _Sink h = _Sink();
    h.u8(14);
    h.u8(0x20);
    h.u16(2100);
    h.u32(dataBytes.length);
    h.raw(<int>[0x2E, 0x46, 0x49, 0x54]);
    h.u16(_crc16(h.bytes));
    final List<int> content = <int>[...h.bytes, ...dataBytes];
    final int crc = _crc16(content);
    final Uint8List bytes =
        Uint8List.fromList(<int>[...content, crc & 0xFF, (crc >> 8) & 0xFF]);
    expect(() => decodeFitRecords(bytes), throwsA(isA<FitDecodeException>()));
  });
}
