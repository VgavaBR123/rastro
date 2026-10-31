// Seus dados (F07): a fila de itens da importacao (arquivos soltos e ZIP da
// exportacao de conta), no mesmo isolate e no isolate separado.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/your_data/domain/import_models.dart';
import 'package:strava_estudo_app/your_data/import_feed.dart';

import 'fixtures.dart';

Future<List<ImportStep>> drain(ImportFeed feed) async {
  final out = <ImportStep>[];
  while (true) {
    final s = await feed.next();
    if (s == null) break;
    out.add(s);
  }
  await feed.close();
  return out;
}

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('rastro_feed'));
  tearDown(() => dir.deleteSync(recursive: true));

  List<int> runGpx({String name = 'Corrida', int n = 20, int startMs = 0}) =>
      utf8.encode(gpxText(name: name, type: 'running', points: line(n, startMs: startMs)));

  test('arquivos soltos: gpx, gpx.gz, tcx.gz, fit, fit.gz, formato desconhecido e corrompido', () async {
    final day = 86400000;
    final paths = [
      writeTemp(dir, 'a.gpx', runGpx(startMs: kT0)),
      writeTemp(dir, 'b.gpx.gz', gz(runGpx(startMs: kT0 + day))),
      writeTemp(dir, 'c.tcx.gz', gz(utf8.encode(tcxText(sport: 'Biking', points: line(20, startMs: kT0 + 2 * day))))),
      writeTemp(dir, 'd.fit', fitBytes(points: line(20), sport: 11)),
      writeTemp(dir, 'e.fit.gz', gz(fitBytes(points: line(20), sport: 17, sessionTimerMs: 15000))),
      writeTemp(dir, 'f.kml', utf8.encode('<kml/>')),
      writeTemp(dir, 'g.gpx', utf8.encode('<gpx><trk>')),
      writeTemp(dir, 'h.fit', fitBytes(points: line(5), sport: 1, badCrc: true)),
      writeTemp(dir, 'i.gpx.gz', utf8.encode('isto nao e gzip')),
    ];
    final feed = await LocalImportFeed.open(paths);
    expect(feed.total, 9);
    final steps = await drain(feed);
    expect(steps, hasLength(9));
    final acts = steps.whereType<ImportStepActivity>().toList();
    expect(acts.map((s) => s.activity.type),
        [ActivityType.run, ActivityType.run, ActivityType.ride, ActivityType.walk, ActivityType.walk]);
    expect(acts.map((s) => s.activity.format),
        [ImportFormat.gpx, ImportFormat.gpx, ImportFormat.tcx, ImportFormat.fit, ImportFormat.fit]);
    expect(acts.last.activity.timerMs, 15000);
    final errors = steps.whereType<ImportStepError>().toList();
    expect(errors.map((e) => e.source), ['f.kml', 'g.gpx', 'h.fit', 'i.gpx.gz']);
    expect(errors.first.reason, contains('formato'));
    expect(errors[2].reason, contains('CRC'));
  });

  test('o mesmo conteudo em gpx e gpx.gz da o mesmo guid', () async {
    final feed = await LocalImportFeed.open([
      writeTemp(dir, 'a.gpx', runGpx()),
      writeTemp(dir, 'a.gpx.gz', gz(runGpx())),
    ]);
    final acts = (await drain(feed)).whereType<ImportStepActivity>().toList();
    expect(acts[0].activity.guid, acts[1].activity.guid);
  });

  test('ZIP da exportacao de conta: nome e tipo do CSV, faltando, outros esportes e sem arquivo', () async {
    final csv = stravaCsv([
      (id: '1', name: 'Longão de domingo', type: 'Run', file: 'activities/1.gpx.gz'),
      (id: '2', name: 'Pedal, com vírgula', type: 'Ride', file: 'activities/2.fit.gz'),
      (id: '3', name: 'Natacao', type: 'Swim', file: 'activities/3.fit.gz'),
      (id: '4', name: 'Sumiu', type: 'Run', file: 'activities/4.gpx'),
      (id: '5', name: 'Manual', type: 'Run', file: ''),
      (id: '6', name: 'Trilha', type: 'Hike', file: 'activities/6.tcx'),
    ]);
    final zip = zipOf({
      'export_9/activities.csv': utf8.encode(csv),
      'export_9/activities/1.gpx.gz': gz(runGpx(name: 'Nome do arquivo')),
      'export_9/activities/2.fit.gz': gz(fitBytes(points: line(20), sport: 1)),
      'export_9/activities/3.fit.gz': gz(fitBytes(points: line(20), sport: 5)),
      'export_9/activities/6.tcx': utf8.encode(tcxText(sport: 'Running', points: line(20))),
      'export_9/activities/7.gpx': runGpx(name: 'Fora do CSV'),
      'export_9/profile.jpg': [1, 2, 3],
    });
    final feed = await LocalImportFeed.open([writeTemp(dir, 'export.zip', zip)]);
    expect(feed.total, 7);
    final steps = await drain(feed);
    final acts = steps.whereType<ImportStepActivity>().toList();
    expect(acts.map((s) => s.activity.title), ['Longão de domingo', 'Pedal, com vírgula', 'Trilha', 'Fora do CSV']);
    expect(acts.map((s) => s.activity.type),
        [ActivityType.run, ActivityType.ride, ActivityType.walk, ActivityType.run]);
    final skipped = steps.whereType<ImportStepSkipped>().toList();
    expect(skipped.map((s) => s.label), ['natacao', kNoFileLabel]);
    final errors = steps.whereType<ImportStepError>().toList();
    expect(errors.single.source, 'activities/4.gpx');
    expect(errors.single.reason, contains('nao esta no ZIP'));
  });

  test('ZIP com CSV em portugues; com CSV, so a pasta activities/ entra', () async {
    const csv = 'ID da atividade,Data da atividade,Nome da atividade,Tipo de atividade,Nome do arquivo\n'
        '1,"1 de mar. de 2026",Pedal no parque,Pedalada,activities/1.gpx\n'
        '2,"2 de mar. de 2026",Trilha da serra,Trilha,activities/2.tcx\n'
        '3,"3 de mar. de 2026",Nadei,Natação,activities/3.fit\n';
    final zip = zipOf({
      'activities.csv': utf8.encode(csv),
      'activities/1.gpx': runGpx(name: 'x'),
      'activities/2.tcx': utf8.encode(tcxText(sport: 'Running', points: line(20, startMs: kT0 + 86400000))),
      'activities/3.fit': fitBytes(points: line(20), sport: 5),
      'activities/9.gpx': runGpx(startMs: kT0 + 2 * 86400000),
      'routes/rota.gpx': runGpx(startMs: kT0 + 3 * 86400000),
      'outra/coisa.fit': fitBytes(points: line(5), sport: 1),
    });
    final feed = await LocalImportFeed.open([writeTemp(dir, 'pt.zip', zip)]);
    expect(feed.total, 4);
    final steps = await drain(feed);
    final acts = steps.whereType<ImportStepActivity>().toList();
    expect(acts.map((s) => s.activity.type), [ActivityType.ride, ActivityType.walk, ActivityType.run]);
    expect(acts.map((s) => s.activity.title), ['Pedal no parque', 'Trilha da serra', 'Corrida']);
    expect(steps.whereType<ImportStepSkipped>().single.label, 'natacao');
    expect(steps.whereType<ImportStepError>(), isEmpty);
  });

  test('ZIP sem CSV: todos os arquivos de atividade; arquivo que nao e ZIP vira erro', () async {
    final zip = zipOf({
      'a/1.gpx': runGpx(),
      'b/2.tcx': utf8.encode(tcxText(sport: 'Biking', points: line(10))),
      'leia.txt': utf8.encode('x'),
    });
    final feed = await LocalImportFeed.open([
      writeTemp(dir, 'z.zip', zip),
      writeTemp(dir, 'quebrado.zip', utf8.encode('nao e zip')),
    ]);
    expect(feed.total, 3);
    final steps = await drain(feed);
    expect(steps.whereType<ImportStepActivity>(), hasLength(2));
    expect(steps.whereType<ImportStepError>().single.source, 'quebrado.zip');
  });

  test('arquivo vazio', () async {
    final feed = await LocalImportFeed.open([writeTemp(dir, 'v.gpx', const [])]);
    final steps = await drain(feed);
    expect((steps.single as ImportStepError).reason, 'arquivo vazio');
  });

  test('no isolate: mesmo resultado e fechar no meio para', () async {
    final paths = [
      for (var i = 0; i < 4; i++)
        writeTemp(dir, '$i.gpx', runGpx(startMs: kT0 + i * 86400000)),
    ];
    final feed = await IsolateImportFeed.open(paths);
    expect(feed.total, 4);
    final first = await feed.next();
    expect(first, isA<ImportStepActivity>());
    expect((first as ImportStepActivity).activity.points, isNotEmpty);
    await feed.close();
    expect(await feed.next(), isNull, reason: 'depois de fechar nao entrega mais nada');

    final all = await drain(await IsolateImportFeed.open(paths));
    expect(all.whereType<ImportStepActivity>(), hasLength(4));
  });
}
