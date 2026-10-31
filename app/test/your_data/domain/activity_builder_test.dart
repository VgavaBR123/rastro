// Seus dados (F07): do arquivo lido a atividade pronta para o banco, com as
// metricas do nosso pipeline, o tipo e o guid deterministico.
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/your_data/domain/activity_builder.dart';
import 'package:strava_estudo_app/your_data/domain/content_hash.dart';
import 'package:strava_estudo_app/your_data/domain/gpx_reader.dart';
import 'package:strava_estudo_app/your_data/domain/import_models.dart';
import 'package:strava_estudo_app/your_data/domain/sport_mapping.dart';

import '../fixtures.dart';

ParsedActivity gpx(List<FixPoint> pts, {String? type, String? name}) =>
    parseGpx(gpxText(points: pts, type: type, name: name));

ImportedActivity built(BuildResult r) => (r as BuiltActivity).activity;

void main() {
  group('matchSport', () {
    test('corrida, pedal e caminhada em varios nomes', () {
      for (final s in ['Run', 'running', 'Trail Run', 'VirtualRun', 'Corrida', 'treadmill']) {
        expect(matchSport(s), const SportMatch.known(ActivityType.run), reason: s);
      }
      for (final s in ['Ride', 'cycling', 'Biking', 'Virtual Ride', 'E-Bike Ride', 'MountainBikeRide', 'GravelRide', 'e_biking']) {
        expect(matchSport(s), const SportMatch.known(ActivityType.ride), reason: s);
      }
      for (final s in ['Walk', 'walking', 'Hike', 'hiking', 'Caminhada', 'Trilha']) {
        expect(matchSport(s), const SportMatch.known(ActivityType.walk), reason: s);
      }
    });

    test('outros esportes viram rotulo em portugues ou o nome original', () {
      expect(matchSport('Swim'), const SportMatch.other('natacao'));
      expect(matchSport('swimming'), const SportMatch.other('natacao'));
      expect(matchSport('Yoga'), const SportMatch.other('ioga'));
      expect(matchSport('Kitesurf'), const SportMatch.other('kitesurf'));
      expect(matchSport('sport_200'), const SportMatch.other('outros'));
    });

    test('sem tipo (ou so numero / Other) e desconhecido', () {
      expect(matchSport(null), const SportMatch.unknown());
      expect(matchSport('  '), const SportMatch.unknown());
      expect(matchSport('9'), const SportMatch.unknown());
      expect(matchSport('Other'), const SportMatch.unknown());
    });
  });

  group('inferSportFromSpeed', () {
    test('devagar caminhada, medio corrida, rapido pedal', () {
      expect(inferSportFromSpeed(1.2), ActivityType.walk);
      expect(inferSportFromSpeed(3.0), ActivityType.run);
      expect(inferSportFromSpeed(7.0), ActivityType.ride);
    });
  });

  test('contentHash e deterministico e muda com o conteudo', () {
    expect(contentHash([1, 2, 3]), contentHash([1, 2, 3]));
    expect(contentHash([1, 2, 3]), isNot(contentHash([1, 2, 4])));
    expect(contentHash(<int>[]), hasLength(greaterThan(8)));
  });

  group('buildImportedActivity', () {
    test('corrida GPX: distancia, tempo e pontos pelo nosso pipeline', () {
      // 61 pontos, 3,2 m/s, 1 s entre eles: 192 m em 60 s.
      final r = buildImportedActivity(gpx(line(61), type: 'running', name: 'Treino'), hash: 'abc');
      final a = built(r);
      expect(a.guid, 'imp-abc');
      expect(a.type, ActivityType.run);
      expect(a.format, ImportFormat.gpx);
      expect(a.title, 'Treino');
      expect(a.startMs, kT0);
      expect(a.endMs, kT0 + 60000);
      expect(a.distanceMeters, closeTo(192, 1));
      expect(a.timerMs, 60000);
      expect(a.isIndoor, isFalse);
      expect(a.points, hasLength(61));
      expect(a.points.last.cumulativeDistanceMeters, closeTo(a.distanceMeters, 1e-6));
      expect(a.points.last.position.altitudeMeters, 820);
    });

    test('parada no meio: o tempo em movimento desconta a pausa (nosso criterio)', () {
      final t0 = kT0;
      final pts = <FixPoint>[
        ...line(31),
        // 60 s parado no mesmo lugar.
        for (var i = 1; i <= 60; i++)
          (lat: line(31).last.lat, lon: -46.6, ele: 790.0, time: isoUtc(t0 + 30000 + i * 1000)),
        ...line(31, startMs: t0 + 91000).map((p) => (
              lat: p.lat + 96 / 111195.0,
              lon: p.lon,
              ele: p.ele,
              time: p.time,
            )),
      ];
      final a = built(buildImportedActivity(gpx(pts, type: 'Run'), hash: 'h'));
      expect(a.endMs - a.startMs, 121000);
      expect(a.timerMs, lessThan(75000));
      expect(a.timerMs, greaterThan(55000));
    });

    test('FIT: tempo em movimento vem da sessao e as pausas do aparelho valem por ponto', () {
      final parsed = ParsedActivity(
        format: ImportFormat.fit,
        sportName: 'cycling',
        startMs: kT0,
        timerMs: 7000,
        elapsedMs: 10000,
        timerPauses: [TimerPause(kT0 + 3000, kT0 + 6000)],
        points: [
          for (var i = 0; i <= 10; i++)
            ParsedPoint(timeMs: kT0 + i * 1000, latitude: -23.5 + i * 0.0001, longitude: -46.6),
        ],
      );
      final a = built(buildImportedActivity(parsed, hash: 'f'));
      expect(a.type, ActivityType.ride);
      expect(a.timerMs, 7000);
      expect(a.points.last.timerTimeMs, 7000);
      expect(a.points.last.elapsedTimeMs, 10000);
    });

    test('esteira: sem GPS, com distancia e tempo do arquivo, entra sem rota', () {
      final parsed = ParsedActivity(
        format: ImportFormat.fit,
        sportName: 'running',
        startMs: kT0,
        timerMs: 1800000,
        elapsedMs: 1850000,
        distanceMeters: 5000,
        points: [for (var i = 0; i < 5; i++) ParsedPoint(timeMs: kT0 + i * 1000)],
      );
      final a = built(buildImportedActivity(parsed, hash: 'e'));
      expect(a.isIndoor, isTrue);
      expect(a.points, isEmpty);
      expect(a.distanceMeters, 5000);
      expect(a.timerMs, 1800000);
      expect(a.endMs, kT0 + 1850000);
    });

    test('tipo do CSV vence o do arquivo; nome do CSV vence o do arquivo', () {
      final a = built(buildImportedActivity(
        gpx(line(5), type: 'running', name: 'Do arquivo'),
        hash: 'x',
        sportOverride: 'Hike',
        nameOverride: 'Trilha do Pico',
      ));
      expect(a.type, ActivityType.walk);
      expect(a.title, 'Trilha do Pico');
    });

    test('outro esporte e ignorado com o rotulo', () {
      final r = buildImportedActivity(gpx(line(5), type: 'Swim'), hash: 'x');
      expect(r, isA<SkippedSport>());
      expect((r as SkippedSport).label, 'natacao');
    });

    test('tipo desconhecido: inferido pelo ritmo', () {
      // 8 m/s = pedal.
      final a = built(buildImportedActivity(gpx(line(30, stepMeters: 8)), hash: 'x'));
      expect(a.type, ActivityType.ride);
    });

    test('pontos sem horario sao descartados; sem nenhum horario e erro', () {
      final pts = [...line(5), (lat: -23.4, lon: -46.6, ele: null, time: null)];
      expect(built(buildImportedActivity(gpx(pts, type: 'Run'), hash: 'x')).points, hasLength(5));
      final none = [for (final p in line(5)) (lat: p.lat, lon: p.lon, ele: p.ele, time: null)];
      expect(
        () => buildImportedActivity(gpx(none, type: 'Run'), hash: 'x'),
        throwsA(isA<ImportFormatException>()),
      );
    });

    test('atividade de 0 pontos e sem totais e erro', () {
      expect(
        () => buildImportedActivity(gpx(const [], type: 'Run'), hash: 'x'),
        throwsA(isA<ImportFormatException>().having((e) => e.message, 'motivo', contains('pontos'))),
      );
    });

    test('pontos fora de ordem no tempo sao descartados', () {
      final pts = line(6);
      final shuffled = [pts[0], pts[1], pts[2], pts[1], pts[3], pts[4], pts[5]];
      final a = built(buildImportedActivity(gpx(shuffled, type: 'Run'), hash: 'x'));
      expect(a.points, hasLength(6));
    });

    test('GPX: inicio declarado longe do primeiro ponto e ignorado; perto vale', () {
      final far = parseGpx(gpxText(type: 'Run', metadataTime: isoUtc(kT0 - 3600000), points: line(10)));
      expect(built(buildImportedActivity(far, hash: 'x')).startMs, kT0);
      final near = parseGpx(gpxText(type: 'Run', metadataTime: isoUtc(kT0 - 30000), points: line(10)));
      final a = built(buildImportedActivity(near, hash: 'x'));
      expect(a.startMs, kT0 - 30000);
      expect(a.endMs, kT0 + 9000);
    });

    test('FIT: session.start_time continua valendo', () {
      final parsed = ParsedActivity(
        format: ImportFormat.fit,
        sportName: 'running',
        startMs: kT0 - 3600000,
        points: [for (var i = 0; i < 5; i++) ParsedPoint(timeMs: kT0 + i * 1000, latitude: -23.5 + i * 0.0001, longitude: -46.6)],
      );
      expect(built(buildImportedActivity(parsed, hash: 'x')).startMs, kT0 - 3600000);
    });

    test('TCX: tempo em movimento das voltas', () {
      final parsed = ParsedActivity(
        format: ImportFormat.tcx,
        sportName: 'Running',
        startMs: kT0,
        timerMs: 50000,
        elapsedMs: 60000,
        points: [for (final p in line(61)) ParsedPoint(timeMs: DateTime.parse(p.time!).millisecondsSinceEpoch, latitude: p.lat, longitude: p.lon)],
      );
      final a = built(buildImportedActivity(parsed, hash: 'x'));
      expect(a.timerMs, 50000);
      expect(a.endMs, kT0 + 60000);
    });

    test('tipo inferido fica marcado; tipo do arquivo nao', () {
      expect(built(buildImportedActivity(gpx(line(30, stepMeters: 8)), hash: 'x')).typeInferred, isTrue);
      expect(built(buildImportedActivity(gpx(line(30), type: 'Run'), hash: 'x')).typeInferred, isFalse);
    });

    test('titulo vazio vira null', () {
      final a = built(buildImportedActivity(gpx(line(3), type: 'Run', name: '  '), hash: 'x'));
      expect(a.title, isNull);
    });
  });
}
