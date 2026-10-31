// Seus dados (F07): leitor FIT da importacao, com arquivos montados aqui e
// com o FIT que o proprio app gera para o upload.
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/sync/fit/fit_writer.dart';
import 'package:strava_estudo_app/your_data/domain/fit_reader.dart';
import 'package:strava_estudo_app/your_data/domain/import_models.dart';

import '../fixtures.dart';

void main() {
  test('le pontos, sessao (tempo em movimento, total, distancia) e esporte', () {
    final a = parseFit(fitBytes(
      points: line(4),
      sport: 1,
      sessionTimerMs: 3000,
      sessionElapsedMs: 3500,
      sessionDistance: 9.5,
    ));
    expect(a.format, ImportFormat.fit);
    expect(a.sportName, 'running');
    expect(a.points, hasLength(4));
    expect(a.points.first.timeMs, kT0);
    expect(a.points.first.latitude, closeTo(-23.5, 1e-6));
    expect(a.points.first.altitudeMeters, closeTo(760, 0.2));
    expect(a.timerMs, 3000);
    expect(a.elapsedMs, 3500);
    expect(a.distanceMeters, closeTo(9.5, 1e-9));
    expect(a.startMs, kT0);
  });

  test('esportes: pedal, caminhada, trilha, natacao e desconhecido', () {
    String? sportOf(int s) => parseFit(fitBytes(points: line(1), sport: s)).sportName;
    expect(sportOf(2), 'cycling');
    expect(sportOf(11), 'walking');
    expect(sportOf(17), 'hiking');
    expect(sportOf(5), 'swimming');
    expect(sportOf(200), 'sport_200');
  });

  test('sem sessao: esporte da mensagem sport, nome dela e sem tempo em movimento', () {
    final a = parseFit(fitBytes(
      points: line(2),
      sport: 2,
      withSession: false,
      sportMessageName: 'Pedal',
    ));
    expect(a.sportName, 'cycling');
    expect(a.name, 'Pedal');
    expect(a.timerMs, isNull);
  });

  test('eventos de timer viram pausas', () {
    final a = parseFit(fitBytes(points: line(10), sport: 1, events: [
      (timeMs: kT0, stop: false),
      (timeMs: kT0 + 3000, stop: true),
      (timeMs: kT0 + 6000, stop: false),
      (timeMs: kT0 + 9000, stop: true),
    ]));
    expect(a.timerPauses, hasLength(1));
    expect(a.timerPauses.single.stopMs, kT0 + 3000);
    expect(a.timerPauses.single.startMs, kT0 + 6000);
  });

  test('cabecalho de timestamp comprimido', () {
    final a = parseFit(fitBytes(points: line(5), sport: 1, compressedFrom: 2));
    expect([for (final p in a.points) p.timeMs],
        [kT0, kT0 + 1000, kT0 + 2000, kT0 + 3000, kT0 + 4000]);
  });

  test('esteira: records sem posicao, distancia e tempo da sessao', () {
    final a = parseFit(fitBytes(
      points: line(3),
      noPosition: true,
      sport: 1,
      subSport: 1,
      sessionTimerMs: 1800000,
      sessionElapsedMs: 1800000,
      sessionDistance: 5000,
    ));
    expect(a.points.where((p) => p.hasPosition), isEmpty);
    expect(a.distanceMeters, 5000);
    expect(a.timerMs, 1800000);
  });

  test('le o FIT que o app gera para o upload', () {
    final bytes = encodeActivityFit(startTimeUnixMs: kT0, records: [
      for (var i = 0; i < 3; i++)
        FitRecord(
          timestampUnixMs: kT0 + i * 1000,
          latitude: -23.5,
          longitude: -46.6 + i * 0.0001,
          cumulativeDistanceMeters: i * 10.0,
          altitudeMeters: 700,
          speedMetersPerSecond: 3.25,
        ),
    ]);
    final a = parseFit(bytes);
    expect(a.points, hasLength(3));
    expect(a.points.last.speedMetersPerSecond, closeTo(3.25, 1e-3));
    expect(a.sportName, isNull);
  });

  test('arquivo vazio, curto, sem assinatura e com CRC errado', () {
    expect(() => parseFit(Uint8List(0)), throwsA(isA<ImportFormatException>()));
    expect(() => parseFit(Uint8List(5)), throwsA(isA<ImportFormatException>()));
    final good = fitBytes(points: line(2), sport: 1);
    final noSig = Uint8List.fromList(good)..[9] = 0x41;
    expect(() => parseFit(noSig), throwsA(isA<ImportFormatException>()));
    expect(
      () => parseFit(fitBytes(points: line(2), sport: 1, badCrc: true)),
      throwsA(isA<ImportFormatException>().having((e) => e.message, 'motivo', contains('CRC'))),
    );
  });

  test('truncado no meio dos dados', () {
    final good = fitBytes(points: line(5), sport: 1);
    final cut = Uint8List.sublistView(good, 0, good.length - 20);
    expect(() => parseFit(cut), throwsA(isA<ImportFormatException>()));
  });
}
