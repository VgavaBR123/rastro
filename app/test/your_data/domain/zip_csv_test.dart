// Seus dados (F07): leitor e escritor de ZIP proprios (por partes, sem
// carregar o arquivo inteiro), CRC-32 e o CSV da exportacao de conta.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:archive/archive.dart' as arc;
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/your_data/domain/crc32.dart';
import 'package:strava_estudo_app/your_data/domain/csv.dart';
import 'package:strava_estudo_app/your_data/domain/import_models.dart';
import 'package:strava_estudo_app/your_data/domain/zip_reader.dart';
import 'package:strava_estudo_app/your_data/domain/zip_writer.dart';

import '../fixtures.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('rastro_zip'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('crc32 de referencia', () {
    expect(crc32(ascii.encode('123456789')), 0xCBF43926);
    expect(crc32(const []), 0);
    final c = Crc32()
      ..add(ascii.encode('1234'))
      ..add(ascii.encode('56789'));
    expect(c.value, 0xCBF43926);
  });

  group('ZipReader', () {
    test('le entradas comprimidas e sem compressao de um ZIP de outro gerador', () {
      final big = List<int>.generate(300000, (i) => Random(i).nextInt(4));
      final path = writeTemp(dir, 'a.zip', zipOf({
        'activities.csv': utf8.encode('a,b\n1,2\n'),
        'activities/1.gpx': big,
        'atividades/caminhada à tarde.gpx': utf8.encode('<gpx/>'),
      }));
      final z = ZipReader.open(path);
      addTearDown(z.close);
      expect(z.entries.map((e) => e.name),
          ['activities.csv', 'activities/1.gpx', 'atividades/caminhada à tarde.gpx']);
      expect(z.read(z.find('activities/1.gpx')!), big);
      expect(utf8.decode(z.read(z.find('activities.csv')!)), 'a,b\n1,2\n');

      final stored = writeTemp(dir, 'b.zip', zipOf({'x.txt': utf8.encode('oi')}, deflate: false));
      final z2 = ZipReader.open(stored);
      addTearDown(z2.close);
      expect(utf8.decode(z2.read(z2.entries.single)), 'oi');
    });

    test('limite de tamanho por entrada', () {
      final path = writeTemp(dir, 'a.zip', zipOf({'g.gpx': List.filled(5000, 65)}));
      final z = ZipReader.open(path);
      addTearDown(z.close);
      expect(() => z.read(z.entries.single, maxBytes: 1000),
          throwsA(isA<ImportFormatException>()));
    });

    test('nao e ZIP, vazio e truncado', () {
      expect(() => ZipReader.open(writeTemp(dir, 'n.zip', utf8.encode('nao sou zip'))),
          throwsA(isA<ImportFormatException>()));
      expect(() => ZipReader.open(writeTemp(dir, 'v.zip', const [])),
          throwsA(isA<ImportFormatException>()));
      final good = zipOf({'g.gpx': List.filled(5000, 65)});
      expect(() => ZipReader.open(writeTemp(dir, 't.zip', good.sublist(0, good.length - 30))),
          throwsA(isA<ImportFormatException>()));
    });

    test('dados corrompidos dentro da entrada falham so nela (CRC)', () {
      final bytes = zipOf({'a.txt': utf8.encode('aaaa'), 'b.txt': utf8.encode('bbbb')},
          deflate: false);
      // Troca um byte do conteudo de a.txt.
      final i = String.fromCharCodes(bytes).indexOf('aaaa');
      expect(i, isPositive);
      bytes[i] = 'x'.codeUnitAt(0);
      final z = ZipReader.open(writeTemp(dir, 'c.zip', bytes));
      addTearDown(z.close);
      expect(() => z.read(z.find('a.txt')!), throwsA(isA<ImportFormatException>()));
      expect(utf8.decode(z.read(z.find('b.txt')!)), 'bbbb');
    });
  });

  group('ZipWriter', () {
    test('gera ZIP que outro leitor abre, com nome UTF-8', () async {
      final path = '${dir.path}/out.zip';
      final w = ZipWriter.create(path);
      w.add('LEIA-ME.txt', utf8.encode('Ola'));
      w.add('gpx/Pedal em São Paulo.gpx', utf8.encode('<gpx>${'x' * 1000}</gpx>'));
      w.close();
      final decoded = arc.ZipDecoder().decodeBytes(File(path).readAsBytesSync());
      expect(decoded.files.map((f) => f.name), ['LEIA-ME.txt', 'gpx/Pedal em São Paulo.gpx']);
      expect(utf8.decode(decoded.files.last.content as List<int>), startsWith('<gpx>xxx'));
      // E o nosso leitor tambem.
      final z = ZipReader.open(path);
      addTearDown(z.close);
      expect(utf8.decode(z.read(z.find('LEIA-ME.txt')!)), 'Ola');
    });

    test('nomes repetidos ganham sufixo', () {
      final path = '${dir.path}/dup.zip';
      final w = ZipWriter.create(path);
      expect(w.add('a.gpx', [1]), 'a.gpx');
      expect(w.add('a.gpx', [2]), 'a (2).gpx');
      w.close();
    });
  });

  group('CSV', () {
    test('aspas, virgula e quebra de linha dentro do campo, BOM e CRLF', () {
      const text = '﻿Id,Nome,Tipo\r\n1,"Corrida, longa",Run\r\n2,"Linha 1\nLinha 2","Ride ""rapido"""\r\n';
      expect(parseCsv(text), [
        ['Id', 'Nome', 'Tipo'],
        ['1', 'Corrida, longa', 'Run'],
        ['2', 'Linha 1\nLinha 2', 'Ride "rapido"'],
      ]);
    });

    test('ultima linha sem quebra e linhas vazias', () {
      expect(parseCsv('a,b\n\n1,2'), [
        ['a', 'b'],
        ['1', '2'],
      ]);
    });

    test('escape de campo', () {
      expect(csvField('simples'), 'simples');
      expect(csvField('com, virgula'), '"com, virgula"');
      expect(csvField('com "aspas"'), '"com ""aspas"""');
      expect(csvField('=1+1'), "'=1+1", reason: 'evita formula no Excel');
      expect(csvField('\t=1'), "'\t=1");
      expect(csvField('\r=1'), '"\'\r=1"');
    });
  });
}
