// Testes de auto-consistencia do codificador FIT.
//
// Nao dependem de um decoder externo: validam o cabecalho, os tamanhos, os
// dois CRCs (header e final) e fazem round-trip de alguns campos lendo o
// buffer gerado diretamente.
library;

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/sync/fit/fit_crc.dart';
import 'package:strava_estudo_app/sync/fit/fit_writer.dart';

void main() {
  group('fitCrc16', () {
    test('lista vazia retorna a semente (0 por padrao)', () {
      expect(fitCrc16(<int>[]), 0);
      expect(fitCrc16(<int>[], 0x1234), 0x1234);
    });

    test('entrada nao-trivial e estavel e diferente de zero', () {
      final List<int> dados = <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
      final int a = fitCrc16(dados);
      final int b = fitCrc16(dados);
      expect(a, b); // determinista
      expect(a, isNot(0));
      expect(a & 0xFFFF, a); // cabe em 16 bits
    });

    test('encadeamento por pedacos equivale ao calculo direto', () {
      final List<int> todos = <int>[10, 20, 30, 40, 50, 60];
      final int direto = fitCrc16(todos);
      final int parcial = fitCrc16(todos.sublist(0, 3));
      final int encadeado = fitCrc16(todos.sublist(3), parcial);
      expect(encadeado, direto);
    });
  });

  group('encodeActivityFit - header', () {
    final Uint8List bytes = encodeActivityFit(
      startTimeUnixMs: 1700000000000,
      records: const <FitRecord>[
        FitRecord(
          timestampUnixMs: 1700000000000,
          latitude: 45.0,
          longitude: -73.5,
          cumulativeDistanceMeters: 0.0,
          altitudeMeters: 100.0,
          speedMetersPerSecond: 2.5,
        ),
      ],
    );

    test('header tem 14 bytes e campos fixos corretos', () {
      expect(bytes.length, greaterThan(14 + 2));
      expect(bytes[0], 14); // tamanho do header
      expect(bytes[1], 0x20); // protocol version
      // ".FIT" em bytes 8..11
      expect(bytes[8], 0x2E);
      expect(bytes[9], 0x46);
      expect(bytes[10], 0x49);
      expect(bytes[11], 0x54);
    });

    test('CRC do header (bytes12-13) == fitCrc16 dos 12 primeiros bytes', () {
      final ByteData bd = ByteData.sublistView(bytes);
      final int crcHeader = bd.getUint16(12, Endian.little);
      expect(crcHeader, fitCrc16(bytes.sublist(0, 12)));
    });

    test('data size (bytes4-7 LE) == total - 14 header - 2 CRC', () {
      final ByteData bd = ByteData.sublistView(bytes);
      final int dataSize = bd.getUint32(4, Endian.little);
      expect(dataSize, bytes.length - 14 - 2);
    });

    test('os 2 ultimos bytes == fitCrc16 de tudo menos os 2 ultimos', () {
      final ByteData bd = ByteData.sublistView(bytes);
      final int crcFinal = bd.getUint16(bytes.length - 2, Endian.little);
      expect(crcFinal, fitCrc16(bytes.sublist(0, bytes.length - 2)));
    });
  });

  group('encodeActivityFit - round-trip de campos do record', () {
    // Offsets dentro do arquivo ate o primeiro dado de record:
    //   header(14)
    //   file_id definition: 6 + 4*3 = 18
    //   file_id data: 1 + 1 + 2 + 2 + 4 = 10
    //   record definition: 6 + 6*3 = 24
    // => primeiro record data comeca em 14+18+10+24 = 66
    // Dentro do record data: header(1) timestamp(4) lat(4) long(4)
    //   altitude(2) distance(4) speed(2)
    const int recordDataStart = 66;
    const int offTimestamp = recordDataStart + 1;
    const int offLat = offTimestamp + 4;
    const int offLong = offLat + 4;
    const int offAltitude = offLong + 4;
    const int offDistance = offAltitude + 2;
    const int offSpeed = offDistance + 4; // distance e uint32 (4 bytes)

    const int startMs = 1700000000000;
    final Uint8List bytes = encodeActivityFit(
      startTimeUnixMs: startMs,
      records: const <FitRecord>[
        FitRecord(
          timestampUnixMs: startMs,
          latitude: 45.0,
          longitude: -73.5,
          cumulativeDistanceMeters: 1234.56,
          altitudeMeters: 100.0,
          speedMetersPerSecond: 3.0,
        ),
      ],
    );
    final ByteData bd = ByteData.sublistView(bytes);

    test('position_lat para 45.0 == semicirculos esperados', () {
      final int esperado = (45.0 * 2147483648 / 180).round();
      expect(bd.getInt32(offLat, Endian.little), esperado);
      expect(esperado, 536870912); // 45/180 = 1/4 de 2^31
    });

    test('position_long negativa preserva o sinal (sint32)', () {
      final int esperado = (-73.5 * 2147483648 / 180).round();
      expect(bd.getInt32(offLong, Endian.little), esperado);
      expect(esperado, lessThan(0));
    });

    test('timestamp em segundos FIT (unix s - offset)', () {
      final int esperado = (startMs ~/ 1000) - fitEpochOffsetSeconds;
      expect(bd.getUint32(offTimestamp, Endian.little), esperado);
    });

    test('distance == metros * 100 cumulativo', () {
      expect(bd.getUint32(offDistance, Endian.little), 123456);
    });

    test('altitude == (m + 500) * 5', () {
      expect(bd.getUint16(offAltitude, Endian.little), ((100.0 + 500) * 5).round());
    });

    test('speed == m/s * 1000', () {
      expect(bd.getUint16(offSpeed, Endian.little), 3000);
    });
  });

  group('encodeActivityFit - campos opcionais ausentes', () {
    const int recordDataStart = 66;
    const int offAltitude = recordDataStart + 1 + 4 + 4 + 4;
    const int offSpeed = offAltitude + 2 + 4;

    final Uint8List bytes = encodeActivityFit(
      startTimeUnixMs: 1700000000000,
      records: const <FitRecord>[
        FitRecord(
          timestampUnixMs: 1700000000000,
          latitude: 10.0,
          longitude: 20.0,
          cumulativeDistanceMeters: 50.0,
        ),
      ],
    );
    final ByteData bd = ByteData.sublistView(bytes);

    test('altitude e speed ausentes gravam valor invalid (0xFFFF)', () {
      expect(bd.getUint16(offAltitude, Endian.little), 0xFFFF);
      expect(bd.getUint16(offSpeed, Endian.little), 0xFFFF);
    });
  });

  test('multiplos records aumentam o data size em 21 bytes cada', () {
    Uint8List comN(int n) {
      return encodeActivityFit(
        startTimeUnixMs: 1700000000000,
        records: List<FitRecord>.generate(
          n,
          (int i) => FitRecord(
            timestampUnixMs: 1700000000000 + i * 1000,
            latitude: 45.0 + i * 0.0001,
            longitude: -73.5,
            cumulativeDistanceMeters: i * 10.0,
            altitudeMeters: 100.0,
            speedMetersPerSecond: 2.0,
          ),
        ),
      );
    }

    final int len1 = comN(1).length;
    final int len3 = comN(3).length;
    expect(len3 - len1, 2 * 21); // cada record data = 21 bytes
  });
}
