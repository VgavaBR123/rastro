// Seus dados (F07): exportar tudo (ZIP com um GPX por atividade, CSV e
// LEIA-ME) e uma atividade so, com e sem o corte de privacidade da F02.
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/persistence/recording_repository.dart';
import 'package:strava_estudo_app/privacy/domain/privacy_zone.dart';
import 'package:strava_estudo_app/privacy/privacy_repository.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/domain/waypoint.dart' as dom;
import 'package:strava_estudo_app/your_data/domain/csv.dart';
import 'package:strava_estudo_app/your_data/domain/gpx_reader.dart';
import 'package:strava_estudo_app/your_data/domain/gpx_writer.dart';
import 'package:strava_estudo_app/your_data/domain/zip_reader.dart';
import 'package:strava_estudo_app/your_data/export_service.dart';

import 'fixtures.dart';

/// Corrida de 100 pontos indo para o norte, ~11 m entre eles, 1 por segundo.
Future<void> seedRun(RecordingDatabase db, String guid, {int? startMs, String? title}) async {
  final s = startMs ?? kT0;
  await db.upsertActivity(ActivitiesCompanion.insert(
    guid: guid,
    activityType: ActivityType.run,
    startTimestampMs: s,
    endTimestampMs: Value(s + 99000),
    timerTimeMs: const Value(95000),
    distanceMeters: const Value(1100),
    isFinished: const Value(true),
    syncState: SyncState.synced,
    title: Value(title),
  ));
  await db.appendWaypoints([
    for (var i = 0; i < 100; i++)
      waypointToCompanion(
        guid,
        i,
        dom.Waypoint(
          position: GeoPoint(latitude: -23.5 + i * 0.0001, longitude: -46.6, altitudeMeters: 700.0 + (i % 10)),
          cumulativeDistanceMeters: i * 11.1,
          elapsedTimeMs: i * 1000,
          timerTimeMs: i * 1000,
          classification: dom.WaypointClassification.accept,
        ),
      ),
  ]);
}

Future<void> seedTreadmill(RecordingDatabase db) => db.upsertActivity(ActivitiesCompanion.insert(
  guid: 'imp-esteira',
  activityType: ActivityType.run,
  startTimestampMs: kT0 + 86400000,
  endTimestampMs: Value(kT0 + 86400000 + 1800000),
  timerTimeMs: const Value(1800000),
  distanceMeters: const Value(5000),
  isIndoor: const Value(true),
  isFinished: const Value(true),
  syncState: SyncState.pending,
  title: const Value('Esteira, "leve"'),
  importSource: const Value('fit'),
));

void main() {
  group('buildGpx', () {
    test('GPX 1.1 com nome escapado, tipo, tempo UTC e elevacao; o nosso leitor le de volta', () {
      final xml = buildGpx(
        name: 'Pedal <rapido> & "bom"',
        type: ActivityType.ride,
        startMs: kT0,
        points: [
          GpxPoint(latitude: -23.5, longitude: -46.6, altitudeMeters: 760.5, timeMs: kT0),
          GpxPoint(latitude: -23.4999, longitude: -46.6, timeMs: kT0 + 1500),
        ],
      );
      expect(xml, startsWith('<?xml version="1.0" encoding="UTF-8"?>'));
      expect(xml, contains('<gpx version="1.1" creator="Rastro" xmlns="http://www.topografix.com/GPX/1/1"'));
      expect(xml, contains('<time>2026-03-01T10:00:01.500Z</time>'));
      expect(xml, contains('<type>cycling</type>'));
      final back = parseGpx(xml);
      expect(back.name, 'Pedal <rapido> & "bom"');
      expect(back.sportName, 'cycling');
      expect(back.points, hasLength(2));
      expect(back.points.first.altitudeMeters, 760.5);
      expect(back.points.last.altitudeMeters, isNull);
      expect(back.points.last.timeMs, kT0 + 1500);
      expect(back.startMs, kT0);
    });

    test('sem pontos (esteira) continua valido', () {
      final back = parseGpx(buildGpx(name: 'E', type: ActivityType.run, startMs: kT0, points: const []));
      expect(back.points, isEmpty);
    });

    test('caracteres invalidos em XML 1.0 saem do nome; o GPX continua legivel', () {
      final bad = 'A\u0000B\u0007C\tD\nE\uD800F\u{1F3C3}G';
      expect(xmlEscape(bad), 'ABC\tD\nEF\u{1F3C3}G');
      final back = parseGpx(buildGpx(name: bad, type: ActivityType.run, startMs: kT0, points: const []));
      expect(back.name, contains('\u{1F3C3}'));
    });

    test('safeFileName corta por caractere, sem partir emoji', () {
      final name = '${'a' * 59}\u{1F3C3}\u{1F3C3}';
      final cut = safeFileName(name);
      expect(cut.runes.length, 60);
      expect(cut.endsWith('\u{1F3C3}'), isTrue);
      expect(() => utf8.encode(cut), returnsNormally);
      expect(cut.codeUnits.last, isNot(inInclusiveRange(0xD800, 0xDBFF)));
    });

    test('nome de arquivo seguro', () {
      expect(safeFileName('Corrida: 10/10 "top"?'), 'Corrida 10 10 top');
      expect(safeFileName('   '), 'atividade');
      expect(safeFileName('a' * 100).length, 60);
    });
  });

  group('ExportService', () {
    late RecordingDatabase db;
    late Directory dir;
    late ExportService service;
    setUp(() async {
      db = RecordingDatabase(NativeDatabase.memory());
      dir = Directory.systemTemp.createTempSync('rastro_export');
      service = ExportService(db, now: () => DateTime(2026, 10, 30, 8, 5));
      await seedRun(db, 'run-1', title: 'Treino da manha');
      await seedTreadmill(db);
      // Zona em volta do inicio da corrida.
      await PrivacyRepository(db).addZone(const PrivacyZone(
        latitude: -23.5,
        longitude: -46.6,
        radiusMeters: 300,
        label: 'Casa',
      ));
    });
    tearDown(() async {
      await db.close();
      dir.deleteSync(recursive: true);
    });

    Map<String, List<int>> unzip(String path) {
      final z = ZipReader.open(path);
      try {
        return {for (final e in z.entries) e.name: z.read(e)};
      } finally {
        z.close();
      }
    }

    test('exportar tudo: ZIP com LEIA-ME, CSV e um GPX por atividade, com privacidade', () async {
      final progress = <(int, int)>[];
      final r = await service.exportAll(
        outDir: dir,
        applyPrivacy: true,
        onProgress: (d, t) => progress.add((d, t)),
      );
      expect(r, isNotNull);
      expect(r!.count, 2);
      expect(r.path, endsWith('rastro-atividades-20261030-0805.zip'));
      expect(progress.last, (2, 2));
      final files = unzip(r.path);
      expect(files.keys, containsAll(['LEIA-ME.txt', 'atividades.csv']));
      final gpxNames = files.keys.where((k) => k.endsWith('.gpx')).toList()..sort();
      expect(gpxNames, hasLength(2));
      expect(gpxNames.first, startsWith('gpx/2026-03-01'));
      expect(gpxNames.first, contains('Treino da manha'));

      final run = parseGpx(utf8.decode(files[gpxNames.first]!));
      expect(run.points.length, lessThan(100), reason: 'o inicio dentro da zona sai cortado');
      expect(run.points.length, greaterThan(0));
      final esteira = parseGpx(utf8.decode(files[gpxNames.last]!));
      expect(esteira.points, isEmpty);

      final csv = parseCsv(utf8.decode(files['atividades.csv']!));
      expect(csv.first, kExportCsvHeader);
      expect(csv, hasLength(3));
      final row = csv[1];
      expect(row[1], 'Corrida');
      expect(row[2], 'Treino da manha');
      expect(row[3], '1.100');
      expect(row[4], '0:01:35');
      expect(row[5], '0:01:39');
      expect(row[6], '90');
      expect(row[7], 'gravada no app');
      expect(csv[2][2], 'Esteira, "leve"');
      expect(csv[2][7], 'importada de FIT');
      expect(utf8.decode(files['LEIA-ME.txt']!), contains('zonas de privacidade'));
    });

    test('sem privacidade: a rota sai inteira', () async {
      final r = await service.exportAll(outDir: dir, applyPrivacy: false);
      final files = unzip(r!.path);
      final name = files.keys.firstWhere((k) => k.contains('Treino'));
      expect(parseGpx(utf8.decode(files[name]!)).points, hasLength(100));
      expect(utf8.decode(files['LEIA-ME.txt']!), contains('sem o corte'));
    });

    test('cancelar no meio nao deixa arquivo', () async {
      final r = await service.exportAll(outDir: dir, applyPrivacy: true, isCancelled: () => true);
      expect(r, isNull);
      expect(dir.listSync(recursive: true).whereType<File>(), isEmpty);
    });

    test('cada exportacao numa subpasta; so as com mais de 1 hora sao apagadas', () async {
      final nowMs = DateTime(2026, 10, 30, 8, 5).millisecondsSinceEpoch;
      final old = Directory('${dir.path}/${nowMs - 2 * 3600000}')..createSync(recursive: true);
      File('${old.path}/velho.zip').writeAsStringSync('x');
      final recent = Directory('${dir.path}/${nowMs - 600000}')..createSync(recursive: true);
      final inUse = File('${recent.path}/em-uso.gpx')..writeAsStringSync('x');
      final loose = File('${dir.path}/solto.zip')..writeAsStringSync('x');
      final r = await service.exportAll(outDir: dir, applyPrivacy: true);
      expect(old.existsSync(), isFalse);
      expect(inUse.existsSync(), isTrue, reason: 'o app de destino pode estar lendo');
      expect(loose.existsSync(), isFalse, reason: 'arquivo do formato antigo, direto na pasta');
      expect(File(r!.path).parent.parent.path, dir.path);
      expect(File(r.path).existsSync(), isTrue);
    });

    test('exportOne e exportAll nao rodam ao mesmo tempo', () async {
      final a = (await db.finishedActivitiesAscending()).first;
      final all = service.exportAll(outDir: dir, applyPrivacy: true);
      await expectLater(
        ExportService(db).exportOne(a, outDir: dir, applyPrivacy: true),
        throwsA(isA<ExportBusyException>()),
      );
      expect(await all, isNotNull);
      // Terminada a primeira, a proxima roda.
      expect(await service.exportOne(a, outDir: dir, applyPrivacy: true), endsWith('.gpx'));
    });

    test('exportar uma atividade so como GPX', () async {
      final a = (await db.finishedActivitiesAscending()).first;
      final cut = await service.exportOne(a, outDir: dir, applyPrivacy: true);
      expect(cut, endsWith('.gpx'));
      expect(parseGpx(File(cut).readAsStringSync()).points.length, lessThan(100));
      final full = await service.exportOne(a, outDir: dir, applyPrivacy: false);
      expect(parseGpx(File(full).readAsStringSync()).points, hasLength(100));
      expect(File(cut).existsSync(), isTrue, reason: 'a anterior ainda pode estar em uso');
      expect(File(cut).parent.path, isNot(File(full).parent.path));
    });
  });
}
