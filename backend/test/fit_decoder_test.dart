// Testes do decodificador FIT do backend.
//
// O gerador de arquivo FIT usado como fixture vive em `fit_fixture.dart`.
import 'dart:typed_data';

import 'package:strava_estudo_backend/src/fit_decoder.dart';
import 'package:test/test.dart';

import 'fit_fixture.dart';

void main() {
  const int t0 = 1760000000000; // instante base em ms Unix

  List<Ponto> rota(int n) => rotaSintetica(n, t0);

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
    final Uint8List bytes = envelopeFit(<int>[0x03, 0, 0, 0, 0]);
    expect(() => decodeFitRecords(bytes), throwsA(isA<FitDecodeException>()));
  });
}
