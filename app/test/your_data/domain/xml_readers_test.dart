// Seus dados (F07): leitura de GPX 1.1 e TCX com arquivos gerados aqui.
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/your_data/domain/gpx_reader.dart';
import 'package:strava_estudo_app/your_data/domain/import_models.dart';
import 'package:strava_estudo_app/your_data/domain/tcx_reader.dart';
import 'package:strava_estudo_app/your_data/domain/xml_time.dart';

import '../fixtures.dart';

void main() {
  group('parseXmlTime', () {
    test('UTC com Z', () {
      expect(parseXmlTime('2026-03-01T10:00:00Z'),
          DateTime.utc(2026, 3, 1, 10).millisecondsSinceEpoch);
    });
    test('offset -03:00 vira UTC', () {
      expect(parseXmlTime('2026-03-01T07:00:00-03:00'),
          DateTime.utc(2026, 3, 1, 10).millisecondsSinceEpoch);
    });
    test('fracao de segundo', () {
      expect(parseXmlTime('2026-03-01T10:00:00.500Z'),
          DateTime.utc(2026, 3, 1, 10).millisecondsSinceEpoch + 500);
    });
    test('sem fuso e tratado como UTC (padrao do GPX)', () {
      expect(parseXmlTime('2026-03-01T10:00:00'),
          DateTime.utc(2026, 3, 1, 10).millisecondsSinceEpoch);
    });
    test('lixo devolve null', () {
      expect(parseXmlTime('ontem'), isNull);
      expect(parseXmlTime(''), isNull);
      expect(parseXmlTime(null), isNull);
    });
  });

  group('GPX', () {
    test('le nome, tipo, pontos, elevacao e horario', () {
      final a = parseGpx(gpxText(name: 'Corrida da manha', type: 'running', points: line(5)));
      expect(a.format, ImportFormat.gpx);
      expect(a.name, 'Corrida da manha');
      expect(a.sportName, 'running');
      expect(a.points, hasLength(5));
      final p = a.points.first;
      expect(p.latitude, closeTo(-23.5, 1e-9));
      expect(p.longitude, closeTo(-46.6, 1e-9));
      expect(p.altitudeMeters, 760);
      expect(p.timeMs, kT0);
      expect(a.points[1].timeMs, kT0 + 1000);
    });

    test('nome com acento e caracteres escapados', () {
      final a = parseGpx(gpxText(name: 'Pedal em S&#227;o Jo&#227;o &amp; volta', points: line(2)));
      expect(a.name, 'Pedal em São João & volta');
      final b = parseGpx(gpxText(name: 'Caminhada à beira-mar', points: line(2)));
      expect(b.name, 'Caminhada à beira-mar');
    });

    test('horario com offset vira UTC', () {
      final a = parseGpx(gpxText(points: [
        (lat: 0.0, lon: 0.0, ele: null, time: '2026-03-01T07:00:00-03:00'),
      ]));
      expect(a.points.single.timeMs, DateTime.utc(2026, 3, 1, 10).millisecondsSinceEpoch);
    });

    test('ponto sem horario fica com timeMs null', () {
      final a = parseGpx(gpxText(points: [
        (lat: 0.0, lon: 0.0, ele: null, time: null),
        (lat: 0.0, lon: 0.0001, ele: null, time: '2026-03-01T10:00:00Z'),
      ]));
      expect(a.points.first.timeMs, isNull);
      expect(a.points.last.timeMs, isNotNull);
    });

    test('inicio vem do metadata/time quando existe', () {
      final a = parseGpx(gpxText(metadataTime: '2026-03-01T09:59:00Z', points: line(2)));
      expect(a.startMs, kT0 - 60000);
    });

    test('rota (rte) sem trk tambem e lida', () {
      const xml = '<?xml version="1.0"?><gpx version="1.1" creator="t" '
          'xmlns="http://www.topografix.com/GPX/1/1"><rte><name>R</name>'
          '<rtept lat="1" lon="2"><time>2026-03-01T10:00:00Z</time></rtept>'
          '</rte></gpx>';
      final a = parseGpx(xml);
      expect(a.points.single.latitude, 1);
      expect(a.name, 'R');
    });

    test('extensoes, CDATA e elementos desconhecidos nao atrapalham', () {
      const xml = '<gpx version="1.1"><metadata><name>Meta</name></metadata>'
          '<trk><name><![CDATA[Pedal & cia]]></name><extensions><a><b><name>x</name></b></a></extensions>'
          '<trkseg><trkpt lat="1" lon="2"><ele>10</ele><time>2026-03-01T10:00:00Z</time>'
          '<extensions><hr>150</hr></extensions></trkpt>'
          '<trkpt lat="1.1" lon="2"/></trkseg></trk></gpx>';
      final a = parseGpx(xml);
      expect(a.name, 'Pedal & cia');
      expect(a.points, hasLength(2));
      expect(a.points.first.altitudeMeters, 10);
      expect(a.points.last.timeMs, isNull);
    });

    test('GPX 1.0 sem namespace', () {
      const xml = '<gpx version="1.0"><trk><trkseg><trkpt lat="1" lon="2">'
          '<time>2026-03-01T10:00:00Z</time></trkpt></trkseg></trk></gpx>';
      expect(parseGpx(xml).points, hasLength(1));
    });

    test('atividade de 0 pontos devolve lista vazia (quem decide e o montador)', () {
      expect(parseGpx(gpxText(points: const [])).points, isEmpty);
    });

    test('arquivo vazio', () {
      expect(() => parseGpx(''), throwsA(isA<ImportFormatException>()));
      expect(() => parseGpx('   \n'), throwsA(isA<ImportFormatException>()));
    });

    test('XML quebrado', () {
      expect(() => parseGpx('<gpx><trk><trkseg><trkpt lat="1"'),
          throwsA(isA<ImportFormatException>()));
    });

    test('raiz errada', () {
      expect(() => parseGpx('<html></html>'), throwsA(isA<ImportFormatException>()));
    });

    test('coordenada invalida descarta so o ponto', () {
      const xml = '<gpx><trk><trkseg>'
          '<trkpt lat="abc" lon="2"><time>2026-03-01T10:00:00Z</time></trkpt>'
          '<trkpt lat="1" lon="2"><time>2026-03-01T10:00:01Z</time></trkpt>'
          '</trkseg></trk></gpx>';
      final a = parseGpx(xml);
      expect(a.points.where((p) => p.hasPosition), hasLength(1));
    });
  });

  group('TCX', () {
    test('le esporte, inicio, pontos, voltas e distancia', () {
      final a = parseTcx(tcxText(sport: 'Biking', points: line(4), lapSeconds: 300, lapMeters: 1500));
      expect(a.format, ImportFormat.tcx);
      expect(a.sportName, 'Biking');
      expect(a.startMs, kT0);
      expect(a.points, hasLength(4));
      expect(a.points.first.altitudeMeters, 760);
      expect(a.timerMs, 300000, reason: 'soma de TotalTimeSeconds das voltas');
      expect(a.elapsedMs, 3000, reason: 'ultimo Trackpoint menos o inicio');
      expect(a.distanceMeters, 1500);
    });

    test('esteira: sem posicao, com distancia e tempo da volta', () {
      final a = parseTcx(tcxText(sport: 'Running', points: const [], lapSeconds: 1800, lapMeters: 5000));
      expect(a.points.where((p) => p.hasPosition), isEmpty);
      expect(a.timerMs, 1800000);
      expect(a.elapsedMs, isNull, reason: 'sem Trackpoint com horario');
      expect(a.distanceMeters, 5000);
    });

    test('so a primeira Activity; prefixos de namespace e extensoes ignoradas', () {
      const xml = '<?xml version="1.0"?><ns:TrainingCenterDatabase xmlns:ns="x">'
          '<ns:Activities><ns:Activity Sport="Running"><ns:Id>2026-03-01T10:00:00Z</ns:Id>'
          '<ns:Lap StartTime="2026-03-01T10:00:00Z"><ns:TotalTimeSeconds>10</ns:TotalTimeSeconds>'
          '<ns:Track><ns:Trackpoint><ns:Time>2026-03-01T10:00:05Z</ns:Time>'
          '<ns:Position><ns:LatitudeDegrees>1</ns:LatitudeDegrees><ns:LongitudeDegrees>2</ns:LongitudeDegrees></ns:Position>'
          '<ns:Extensions><x:TPX xmlns:x="y"><x:Speed>3</x:Speed></x:TPX></ns:Extensions>'
          '</ns:Trackpoint></ns:Track></ns:Lap></ns:Activity>'
          '<ns:Activity Sport="Biking"><ns:Id>2026-03-02T10:00:00Z</ns:Id></ns:Activity>'
          '</ns:Activities></ns:TrainingCenterDatabase>';
      final a = parseTcx(xml);
      expect(a.sportName, 'Running');
      expect(a.points.single.latitude, 1);
      expect(a.points.single.longitude, 2);
      expect(a.elapsedMs, 5000);
    });

    test('nome nas notas da atividade', () {
      final a = parseTcx(tcxText(sport: 'Other', notes: 'Trilha do pico', points: line(1)));
      expect(a.name, 'Trilha do pico');
      expect(a.sportName, 'Other');
    });

    test('arquivo vazio, XML quebrado e sem Activity', () {
      expect(() => parseTcx(''), throwsA(isA<ImportFormatException>()));
      expect(() => parseTcx('<TrainingCenterDatabase><Activities>'),
          throwsA(isA<ImportFormatException>()));
      expect(() => parseTcx('<TrainingCenterDatabase></TrainingCenterDatabase>'),
          throwsA(isA<ImportFormatException>()));
    });
  });
}
