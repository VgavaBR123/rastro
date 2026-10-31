// Teste de ponta a ponta NO APARELHO do "Seus dados" (F07).
//
// As entradas sao montadas aqui, de forma independente dos geradores dos
// testes de unidade: GPX e TCX escritos a mao, FIT pelo fit_writer do upload e
// o ZIP de exportacao de conta pelo pacote `archive`. Os arquivos vao para o
// cache do app no aparelho e o seletor do sistema e trocado por caminhos fixos.
//
// 1) Importa um ZIP no formato da exportacao de conta (CSV + pasta
//    activities/) com GPX, TCX.gz, FIT.gz, uma natacao, uma linha sem arquivo
//    e um GPX quebrado: 3 importadas, 2 ignoradas, 1 erro. Depois reimporta o
//    GPX solto: duplicata.
// 2) Exporta tudo com o corte de privacidade: o ZIP tem um GPX por atividade,
//    o CSV e o LEIA-ME, e o GPX cortado comeca longe do ponto original.
//
// Execucao:
//   flutter test integration_test/seus_dados_test.dart -d <device>
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/app/router.dart';
import 'package:strava_estudo_app/auth/session_store.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/persistence/recording_repository.dart';
import 'package:strava_estudo_app/platform/activity_sharer.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/service/recording_service.dart';
import 'package:strava_estudo_app/sync/fit/fit_writer.dart';
import 'package:strava_estudo_app/your_data/import_file_picker.dart';
import 'package:strava_estudo_app/your_data/your_data_providers.dart';

/// Guarda o que seria entregue ao compartilhar do sistema (a folha do sistema
/// ficaria por cima do app e congelaria o teste).
class _SharerGravador implements ActivitySharer {
  final List<(String, String)> arquivos = [];
  @override
  Future<void> shareFile(String path, {required String mimeType}) async =>
      arquivos.add((path, mimeType));
  @override
  Future<void> shareImage(String path, {String? text}) async {}
  @override
  Future<void> shareText(String text) async {}
}

// Belo Horizonte, 1/3/2026 07:00 -03:00 = 10:00 UTC.
const double _lat0 = -19.9245;
const double _lon0 = -43.9352;
final int _t0 = DateTime.utc(2026, 3, 1, 10).millisecondsSinceEpoch;

/// [n] pontos para nordeste, [passo] m entre eles, 1 por segundo.
List<({double lat, double lon, int ms, double ele})> _rota(int n, double passo, int inicioMs) {
  final dGrau = passo / 111320 / math.sqrt2;
  return [
    for (var i = 0; i < n; i++)
      (lat: _lat0 + i * dGrau, lon: _lon0 + i * dGrau, ms: inicioMs + i * 1000, ele: 850.0 + i % 7),
  ];
}

String _iso(int ms) => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toIso8601String();

/// GPX com horario em -03:00 (nao em Z) e nome com acento e caractere de XML.
String _gpx(List<({double lat, double lon, int ms, double ele})> pts) {
  String local(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).subtract(const Duration(hours: 3));
    String p(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${p(d.month)}-${p(d.day)}T${p(d.hour)}:${p(d.minute)}:${p(d.second)}-03:00';
  }

  final b = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
    ..writeln('<gpx version="1.1" creator="teste e2e" xmlns="http://www.topografix.com/GPX/1/1">')
    ..writeln('<trk><name>Corrida no parque &amp; lagoa, manhã</name><type>running</type><trkseg>');
  for (final p in pts) {
    b.writeln('<trkpt lat="${p.lat}" lon="${p.lon}"><ele>${p.ele}</ele><time>${local(p.ms)}</time></trkpt>');
  }
  b.writeln('</trkseg></trk></gpx>');
  return b.toString();
}

String _tcx(List<({double lat, double lon, int ms, double ele})> pts) {
  final b = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
    ..writeln('<TrainingCenterDatabase xmlns="http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2">')
    ..writeln('<Activities><Activity Sport="Biking"><Id>${_iso(pts.first.ms)}</Id>')
    ..writeln('<Lap StartTime="${_iso(pts.first.ms)}"><Track>');
  for (final p in pts) {
    b.writeln('<Trackpoint><Time>${_iso(p.ms)}</Time><Position><LatitudeDegrees>${p.lat}'
        '</LatitudeDegrees><LongitudeDegrees>${p.lon}</LongitudeDegrees></Position>'
        '<AltitudeMeters>${p.ele}</AltitudeMeters></Trackpoint>');
  }
  b.writeln('</Track></Lap></Activity></Activities></TrainingCenterDatabase>');
  return b.toString();
}

List<int> _fit(List<({double lat, double lon, int ms, double ele})> pts, double passo) =>
    encodeActivityFit(
      startTimeUnixMs: pts.first.ms,
      records: [
        for (var i = 0; i < pts.length; i++)
          FitRecord(
            timestampUnixMs: pts[i].ms,
            latitude: pts[i].lat,
            longitude: pts[i].lon,
            altitudeMeters: pts[i].ele,
            cumulativeDistanceMeters: i * passo,
            speedMetersPerSecond: passo,
          ),
      ],
    );

double _metros(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371000.0;
  double rad(double g) => g * math.pi / 180;
  final dLat = rad(lat2 - lat1), dLon = rad(lon2 - lon1);
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLon / 2), 2);
  return 2 * r * math.asin(math.sqrt(a));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('importar exportacao de conta, duplicata e exportar tudo com privacidade', (
    tester,
  ) async {
    final db = RecordingDatabase();
    addTearDown(db.close);
    await db.delete(db.waypoints).go();
    await db.delete(db.laps).go();
    await db.delete(db.activities).go();
    await db.saveSettings(reliabilityChecklistSeen: true);

    // Arquivos de entrada no cache do app.
    final dir = Directory('${(await getTemporaryDirectory()).path}/e2e_f07');
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);

    final corrida = _rota(600, 3.0, _t0); // ~1,8 km em 10 min
    final pedal = _rota(900, 7.0, _t0 + 86400000); // ~6,3 km em 15 min, dia seguinte
    final esteira = _rota(480, 2.8, _t0 + 2 * 86400000);
    final gpxCorrida = _gpx(corrida);
    final csv = StringBuffer()
      ..writeln('Activity ID,Activity Date,Activity Name,Activity Type,Elapsed Time,Distance,Filename')
      ..writeln('101,"Mar 1, 2026, 10:00:00 AM",Corrida no parque,Run,600,1.80,activities/101.gpx')
      ..writeln('102,"Mar 2, 2026, 10:00:00 AM",Pedal até a serra,Ride,900,6.30,activities/102.tcx.gz')
      ..writeln('103,"Mar 3, 2026, 9:00:00 AM",Natação,Swim,1800,1.50,activities/103.fit.gz')
      ..writeln('104,"Mar 4, 2026, 9:00:00 AM",Treino manual,Run,1200,3.00,')
      ..writeln('105,"Mar 5, 2026, 9:00:00 AM",Arquivo quebrado,Walk,600,1.00,activities/105.gpx')
      ..writeln('106,"Mar 3, 2026, 10:00:00 AM",Corrida do FIT,Run,480,1.34,activities/106.fit.gz');
    final zip = Archive()
      ..addFile(ArchiveFile.string('activities.csv', csv.toString()))
      ..addFile(ArchiveFile.string('activities/101.gpx', gpxCorrida))
      ..addFile(ArchiveFile.bytes('activities/102.tcx.gz', gzip.encode(_tcx(pedal).codeUnits)))
      ..addFile(ArchiveFile.bytes('activities/103.fit.gz', gzip.encode(_fit(esteira, 2.8))))
      ..addFile(ArchiveFile.string('activities/105.gpx', '<gpx><trk><trkseg><trkpt lat='))
      ..addFile(ArchiveFile.bytes('activities/106.fit.gz', gzip.encode(_fit(esteira, 2.8))));
    final caminhoZip = '${dir.path}/export_12345.zip';
    File(caminhoZip).writeAsBytesSync(ZipEncoder().encode(zip));
    final caminhoGpx = '${dir.path}/101.gpx';
    File(caminhoGpx).writeAsStringSync(gpxCorrida);

    final sharer = _SharerGravador();
    final picker = _PickerTrocavel()..paths = [caminhoZip];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recordingDatabaseProvider.overrideWithValue(db),
          sessionStoreProvider.overrideWithValue(InMemorySessionStore()),
          recordingServiceProvider.overrideWithValue(const NoopRecordingService()),
          importFilePickerProvider.overrideWithValue(picker),
          activitySharerProvider.overrideWithValue(sharer),
        ],
        child: MaterialApp.router(routerConfig: buildAppRouter()),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> esperar(Finder f, {int segundos = 60}) async {
      for (var i = 0; i < segundos * 4 && f.evaluate().isEmpty; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 250)));
        await tester.pump();
      }
      await tester.pumpAndSettle();
    }

    String texto(Key k) {
      final f = find.byKey(k);
      if (f.evaluate().isEmpty) return '-';
      return find
          .descendant(of: f, matching: find.byType(Text), matchRoot: true)
          .evaluate()
          .map((e) => (e.widget as Text).data ?? (e.widget as Text).textSpan?.toPlainText() ?? '')
          .join(' ');
    }

    // 0) Configuracoes -> Seus dados.
    await tester.tap(find.byKey(const Key('nav_profile')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('profile_settings')));
    await tester.tap(find.byKey(const Key('profile_settings')));
    await tester.pumpAndSettle();
    // Rola a lista vertical ate o item existir e o centraliza (a secao de
    // Seguranca da F08 empurrou o item para a borda da tela).
    await tester.scrollUntilVisible(
      find.byKey(const Key('your_data')),
      200,
      scrollable: find
          .byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down)
          .first,
    );
    await tester.runAsync(() => Scrollable.ensureVisible(
          tester.element(find.byKey(const Key('your_data'))),
          alignment: 0.5,
        ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('your_data')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('your_data_screen')), findsOneWidget);

    // 1) Importa o ZIP.
    await tester.tap(find.byKey(const Key('import_pick')));
    await esperar(find.byKey(const Key('import_summary')));
    for (final k in ['imported', 'duplicates', 'ignored', 'errors']) {
      debugPrint('[e2e-f07] resumo $k: ${texto(Key('import_summary_$k'))}');
    }
    final atividades = await db.recentActivities(limit: 50);
    for (final a in atividades) {
      debugPrint('[e2e-f07] ${a.activityType.name} "${a.title}" ${a.importSource} '
          '${a.distanceMeters.toStringAsFixed(0)} m, ${a.timerTimeMs ~/ 1000} s, '
          'inicio ${DateTime.fromMillisecondsSinceEpoch(a.startTimestampMs, isUtc: true)}, '
          'sync ${a.syncState.name}, visib ${a.visibility}');
    }
    expect(atividades.length, 3, reason: 'GPX, TCX.gz e FIT.gz; natacao, sem arquivo e quebrado fora');
    final porTipo = {for (final a in atividades) a.activityType: a};
    expect(porTipo.keys.toSet(), {ActivityType.run, ActivityType.ride});
    final doGpx = atividades.firstWhere((a) => a.startTimestampMs == _t0);
    expect(doGpx.activityType, ActivityType.run);
    expect(doGpx.distanceMeters, inInclusiveRange(1700, 1900));
    expect(doGpx.startTimestampMs, _t0, reason: 'GPX em -03:00 vira o mesmo instante UTC');
    final doPedal = porTipo[ActivityType.ride]!;
    expect(doPedal.distanceMeters, inInclusiveRange(6000, 6600));
    expect(atividades.every((a) => a.syncState == SyncState.pending), isTrue,
        reason: 'importadas entram na fila de sync');
    expect(texto(const Key('import_summary_errors')), contains('1'));
    await tester.tap(find.byKey(const Key('import_done')));
    await tester.pumpAndSettle();

    // 2) Reimporta o GPX solto: duplicata, nada novo.
    picker.paths = [caminhoGpx];
    await tester.tap(find.byKey(const Key('import_pick')));
    await esperar(find.byKey(const Key('import_summary')));
    debugPrint('[e2e-f07] reimportar: ${texto(const Key('import_summary_duplicates'))}');
    expect(texto(const Key('import_summary_duplicates')), contains('1'));
    expect((await db.recentActivities(limit: 50)).length, 3);
    await tester.tap(find.byKey(const Key('import_done')));
    await tester.pumpAndSettle();

    // 3) Exporta tudo com o corte de privacidade (300 m nas pontas da corrida).
    // O titulo veio do CSV (prioridade sobre o <name> do GPX); troca por um com
    // caracteres de XML para conferir o escape no GPX exportado.
    expect(doGpx.title, 'Corrida no parque');
    await RecordingRepository(db).saveDetails(
      doGpx.guid,
      title: 'Parque & lagoa <manhã>',
      hideEdgesMeters: 300,
    );
    final privacidade = tester.widget<SwitchListTile>(find.byKey(const Key('export_privacy')));
    expect(privacidade.value, isTrue, reason: 'corte ligado por padrao');
    await tester.ensureVisible(find.byKey(const Key('export_all')));
    await tester.tap(find.byKey(const Key('export_all')));
    for (var i = 0; i < 240 && sharer.arquivos.isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 250)));
      await tester.pump();
    }
    expect(sharer.arquivos, hasLength(1));
    final (caminho, mime) = sharer.arquivos.single;
    debugPrint('[e2e-f07] exportado: $caminho ($mime, ${File(caminho).lengthSync()} bytes)');
    expect(mime, 'application/zip');
    final saida = ZipDecoder().decodeBytes(File(caminho).readAsBytesSync());
    final nomes = [for (final f in saida.files) if (f.isFile) f.name];
    debugPrint('[e2e-f07] no zip: $nomes');
    expect(nomes.where((n) => n.endsWith('.gpx')).length, 3);
    expect(nomes, containsAll(['atividades.csv', 'LEIA-ME.txt']));
    final csvSaida = utf8.decode(saida.findFile('atividades.csv')!.content as List<int>);
    for (final l in const LineSplitter().convert(csvSaida)) {
      debugPrint('[e2e-f07] csv: $l');
    }
    expect(csvSaida, isNot(contains(_lat0.toString())), reason: 'o CSV nao leva a rota');

    // O GPX da corrida comeca a mais de 250 m do ponto original (corte de 300 m).
    final gpxCortado = saida.files.firstWhere((f) => f.name.endsWith('.gpx') &&
        utf8.decode(f.content as List<int>).contains('Parque &amp; lagoa'));
    final xml = utf8.decode(gpxCortado.content as List<int>);
    final m = RegExp(r'<trkpt lat="([-\d.]+)" lon="([-\d.]+)"').firstMatch(xml)!;
    final deslocamento = _metros(_lat0, _lon0, double.parse(m[1]!), double.parse(m[2]!));
    debugPrint('[e2e-f07] 1o ponto exportado a ${deslocamento.toStringAsFixed(0)} m do original');
    expect(deslocamento, greaterThan(250));
    expect(xml, contains('Parque &amp; lagoa &lt;manhã&gt;'), reason: 'titulo escapado no XML');
    debugPrint('[e2e-f07] nome no zip: ${gpxCortado.name}');
  });
}

class _PickerTrocavel implements ImportFilePicker {
  List<String> paths = const [];
  @override
  Future<List<String>> pick() async => paths;
  @override
  Future<void> cleanUp() async {}
}
