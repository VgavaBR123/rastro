// Seus dados (F07): tetos de tamanho pelo caminho publico (LocalImportFeed):
// .gz que expande alem do teto (solto e dentro do ZIP), entrada do ZIP que
// declara tamanho menor que o real, arquivo solto grande demais e diretorio
// central gigante.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/your_data/domain/gunzip.dart';
import 'package:strava_estudo_app/your_data/domain/import_models.dart';
import 'package:strava_estudo_app/your_data/domain/zip_reader.dart';
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
  setUp(() => dir = Directory.systemTemp.createTempSync('rastro_limits'));
  tearDown(() => dir.deleteSync(recursive: true));

  // GPX valido de ~1,2 MB quando aberto (muitos pontos).
  List<int> bigGpx() => utf8.encode(gpxText(type: 'running', points: line(12000)));

  test('gunzipLimited para no teto sem descomprimir tudo', () {
    final bomb = gz(Uint8List(5 * 1024 * 1024)); // 5 MB de zeros, ~5 KB comprimido
    expect(bomb.length, lessThan(64 * 1024));
    expect(() => gunzipLimited(bomb, maxBytes: 1024 * 1024),
        throwsA(isA<ImportFormatException>().having((e) => e.message, 'm', 'arquivo grande demais')));
    expect(gunzipLimited(gz([1, 2, 3]), maxBytes: 10), [1, 2, 3]);
    expect(() => gunzipLimited(utf8.encode('nao e gzip'), maxBytes: 10),
        throwsA(isA<ImportFormatException>()));
  });

  test('.gz solto que expande alem do teto vira erro e nao para os outros', () async {
    final feed = await LocalImportFeed.open([
      writeTemp(dir, 'bomba.gpx.gz', gz(bigGpx())),
      writeTemp(dir, 'ok.gpx', utf8.encode(gpxText(type: 'running', points: line(20)))),
    ], maxEntryBytes: 200 * 1024);
    final steps = await drain(feed);
    expect((steps.first as ImportStepError).reason, 'arquivo grande demais');
    expect(steps.last, isA<ImportStepActivity>());
  });

  test('.gz dentro do ZIP que expande alem do teto vira erro', () async {
    final zip = zipOf({'activities/1.gpx.gz': gz(bigGpx())});
    final feed = await LocalImportFeed.open([writeTemp(dir, 'z.zip', zip)], maxEntryBytes: 200 * 1024);
    final steps = await drain(feed);
    expect((steps.single as ImportStepError).reason, 'arquivo grande demais');
  });

  test('arquivo solto maior que o teto', () async {
    final feed = await LocalImportFeed.open([writeTemp(dir, 'g.gpx', bigGpx())], maxEntryBytes: 100 * 1024);
    final steps = await drain(feed);
    expect((steps.single as ImportStepError).reason, 'arquivo grande demais');
  });

  test('entrada do ZIP que declara tamanho menor que o real falha nela', () async {
    final content = utf8.encode(gpxText(type: 'running', points: line(200)));
    final bytes = zipOf({'activities/1.gpx': content, 'activities/2.gpx': utf8.encode(gpxText(type: 'running', points: line(20, startMs: kT0 + 86400000)))});
    // Troca o tamanho descomprimido no diretorio central da 1a entrada por 100.
    final cd = _findCentral(bytes, 0);
    bytes[cd + 24] = 100;
    bytes[cd + 25] = 0;
    bytes[cd + 26] = 0;
    bytes[cd + 27] = 0;
    final feed = await LocalImportFeed.open([writeTemp(dir, 'z.zip', bytes)]);
    final steps = await drain(feed);
    expect(steps.first, isA<ImportStepError>());
    expect((steps.first as ImportStepError).reason, contains('corrompidos'));
    expect(steps.last, isA<ImportStepActivity>());
  });

  test('diretorio central com entradas demais ou grande demais: ZIP corrompido', () async {
    final path = writeTemp(dir, 'z.zip', zipOf({'a.gpx': [1], 'b.gpx': [2], 'c.gpx': [3]}));
    expect(() => ZipReader.open(path, maxEntries: 2),
        throwsA(isA<ImportFormatException>().having((e) => e.message, 'm', contains('ZIP corrompido'))));
    expect(() => ZipReader.open(path, maxDirectoryBytes: 50),
        throwsA(isA<ImportFormatException>().having((e) => e.message, 'm', contains('ZIP corrompido'))));
    // Pelo caminho publico: o ZIP inteiro vira um erro.
    final bytes = zipOf({'activities/1.gpx': [1]});
    final eocd = bytes.length - 22;
    // Diretorio central declarado com 1 GB.
    bytes[eocd + 12] = 0;
    bytes[eocd + 13] = 0;
    bytes[eocd + 14] = 0;
    bytes[eocd + 15] = 0x40;
    final steps = await drain(await LocalImportFeed.open([writeTemp(dir, 'g.zip', bytes)]));
    expect((steps.single as ImportStepError).reason, contains('ZIP corrompido'));
    expect(kMaxZipDirectoryBytes, 64 * 1024 * 1024);
    expect(kMaxZipEntries, 200000);
  });
}

/// Posicao do [n]-esimo cabecalho do diretorio central.
int _findCentral(List<int> b, int n) {
  var seen = 0;
  for (var i = 0; i + 4 <= b.length; i++) {
    if (b[i] == 0x50 && b[i + 1] == 0x4b && b[i + 2] == 0x01 && b[i + 3] == 0x02) {
      if (seen++ == n) return i;
    }
  }
  throw StateError('sem diretorio central');
}
