/// Fila de itens da importacao (F07): arquivos soltos (.fit, .gpx, .tcx e as
/// versoes .gz) e o ZIP da exportacao de conta (activities.csv + pasta
/// activities/). Cada [next] le, descomprime, interpreta e monta UMA
/// atividade; o banco fica com quem consome (ImportService).
///
/// [IsolateImportFeed] roda a [LocalImportFeed] num isolate separado: a
/// leitura e o pipeline nao disputam a thread da interface. O protocolo e
/// "puxado" (um pedido, um item), entao so uma atividade por vez fica na
/// memoria e fechar no meio para tudo.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'domain/activity_builder.dart';
import 'domain/content_hash.dart';
import 'domain/csv.dart';
import 'domain/fit_reader.dart';
import 'domain/gpx_reader.dart';
import 'domain/import_models.dart';
import 'domain/tcx_reader.dart';
import 'domain/zip_reader.dart';

/// Rotulo, no resumo, das linhas do activities.csv sem arquivo (atividade
/// manual, sem pontos nem arquivo para ler).
const String kNoFileLabel = 'sem arquivo';

/// Extensoes aceitas (em minusculas), alem de .zip.
const List<String> kImportExtensions = [
  '.fit', '.fit.gz', '.gpx', '.gpx.gz', '.tcx', '.tcx.gz',
];

/// Um passo da importacao. [source] e o nome curto do arquivo.
sealed class ImportStep {
  final String source;
  const ImportStep(this.source);
}

class ImportStepActivity extends ImportStep {
  final ImportedActivity activity;
  const ImportStepActivity(super.source, this.activity);
}

class ImportStepSkipped extends ImportStep {
  final String label;
  const ImportStepSkipped(super.source, this.label);
}

class ImportStepError extends ImportStep {
  final String reason;
  const ImportStepError(super.source, this.reason);
}

abstract class ImportFeed {
  /// Quantos itens a fila tem (para a barra de progresso).
  int get total;

  /// Proximo passo, ou null quando acabou (ou depois de [close]).
  Future<ImportStep?> next();

  Future<void> close();
}

/// Extensao aceita de [name] ('.gpx.gz'...), ou null.
String? importExtension(String name) {
  final lower = name.toLowerCase();
  for (final ext in kImportExtensions) {
    if (lower.endsWith(ext)) return ext;
  }
  return null;
}

// --- Itens ---

sealed class _Item {
  const _Item();
}

class _LooseFile extends _Item {
  final String path;
  const _LooseFile(this.path);
}

class _ZipFile extends _Item {
  final ZipReader zip;
  final ZipEntry entry;
  final String? csvName;
  final String? csvType;
  const _ZipFile(this.zip, this.entry, {this.csvName, this.csvType});
}

class _Ready extends _Item {
  final ImportStep step;
  const _Ready(this.step);
}

/// Linha do activities.csv.
class _CsvRow {
  final String? name;
  final String? type;
  final String file;
  const _CsvRow(this.name, this.type, this.file);
}

const List<String> _colFile = ['filename', 'nome do arquivo', 'arquivo'];
const List<String> _colType = ['activity type', 'tipo de atividade', 'tipo da atividade', 'tipo'];
const List<String> _colName = ['activity name', 'nome da atividade', 'nome'];

int _column(List<String> header, List<String> names) {
  final norm = [for (final h in header) h.trim().toLowerCase()];
  for (final n in names) {
    final i = norm.indexOf(n);
    if (i >= 0) return i;
  }
  return -1;
}

List<_CsvRow>? _readCsv(String text) {
  final rows = parseCsv(text);
  if (rows.isEmpty) return null;
  final header = rows.first;
  final iFile = _column(header, _colFile);
  if (iFile < 0) return null;
  final iType = _column(header, _colType);
  final iName = _column(header, _colName);
  String? at(List<String> r, int i) => i >= 0 && i < r.length ? r[i] : null;
  return [
    for (final r in rows.skip(1))
      _CsvRow(at(r, iName), at(r, iType), (at(r, iFile) ?? '').trim().replaceAll('\\', '/')),
  ];
}

/// Fila no isolate atual. Use [open]; feche com [close].
class LocalImportFeed implements ImportFeed {
  final List<_Item> _items;
  final List<ZipReader> _zips;
  int _next = 0;
  bool _closed = false;

  LocalImportFeed._(this._items, this._zips);

  /// Abre [paths] (ZIPs tem o diretorio central lido agora) e monta a fila.
  static Future<LocalImportFeed> open(List<String> paths) async {
    final items = <_Item>[];
    final zips = <ZipReader>[];
    for (final path in paths) {
      final base = p.basename(path);
      if (base.toLowerCase().endsWith('.zip')) {
        try {
          final zip = ZipReader.open(path);
          zips.add(zip);
          items.addAll(_zipItems(zip));
        } on ImportFormatException catch (e) {
          items.add(_Ready(ImportStepError(base, e.message)));
        } on FileSystemException {
          items.add(_Ready(ImportStepError(base, 'nao foi possivel abrir')));
        }
      } else {
        items.add(_LooseFile(path));
      }
    }
    return LocalImportFeed._(items, zips);
  }

  static List<_Item> _zipItems(ZipReader zip) {
    ZipEntry? csvEntry;
    for (final e in zip.entries) {
      if (p.posix.basename(e.name).toLowerCase() != 'activities.csv') continue;
      if (csvEntry == null || e.name.length < csvEntry.name.length) csvEntry = e;
    }
    List<_CsvRow>? rows;
    var prefix = '';
    if (csvEntry != null) {
      try {
        rows = _readCsv(utf8.decode(zip.read(csvEntry), allowMalformed: true));
        final dir = p.posix.dirname(csvEntry.name);
        prefix = dir == '.' ? '' : '$dir/';
      } on ImportFormatException {
        rows = null;
      }
    }
    final activityEntries = [
      for (final e in zip.entries)
        if (importExtension(e.name) != null && !e.name.startsWith('__MACOSX/')) e,
    ];
    if (rows == null) {
      return [for (final e in activityEntries) _ZipFile(zip, e)];
    }
    final byName = {for (final e in activityEntries) e.name: e};
    final used = <String>{};
    final items = <_Item>[];
    for (final r in rows) {
      if (r.file.isEmpty) {
        items.add(_Ready(ImportStepSkipped(r.name?.trim() ?? '', kNoFileLabel)));
        continue;
      }
      final entry = byName['$prefix${r.file}'] ?? byName[r.file];
      if (entry == null) {
        items.add(_Ready(ImportStepError(r.file, 'citado no CSV, mas nao esta no ZIP')));
        continue;
      }
      used.add(entry.name);
      items.add(_ZipFile(zip, entry, csvName: r.name, csvType: r.type));
    }
    for (final e in activityEntries) {
      if (!used.contains(e.name)) items.add(_ZipFile(zip, e));
    }
    return items;
  }

  @override
  int get total => _items.length;

  @override
  Future<ImportStep?> next() async {
    if (_closed || _next >= _items.length) return null;
    final item = _items[_next++];
    return switch (item) {
      _Ready(:final step) => step,
      _LooseFile(:final path) => _guard(p.basename(path), () {
        final f = File(path);
        if (f.lengthSync() > kMaxEntryBytes) {
          throw const ImportFormatException('arquivo grande demais');
        }
        return f.readAsBytesSync();
      }),
      _ZipFile(:final zip, :final entry, :final csvName, :final csvType) => _guard(
        _shortZipName(entry.name),
        () => zip.read(entry),
        sportOverride: csvType,
        nameOverride: csvName,
      ),
    };
  }

  /// Nome da entrada a partir da pasta activities/ (ou o nome inteiro).
  static String _shortZipName(String name) {
    final i = name.indexOf('activities/');
    return i >= 0 ? name.substring(i) : name;
  }

  ImportStep _guard(
    String source,
    Uint8List Function() load, {
    String? sportOverride,
    String? nameOverride,
  }) {
    try {
      final ext = importExtension(source);
      if (ext == null) throw const ImportFormatException('formato nao suportado');
      var bytes = load();
      if (bytes.isEmpty) throw const ImportFormatException('arquivo vazio');
      if (ext.endsWith('.gz')) {
        try {
          bytes = Uint8List.fromList(gzip.decode(bytes));
        } on FormatException {
          throw const ImportFormatException('arquivo .gz corrompido');
        } on FileSystemException {
          throw const ImportFormatException('arquivo .gz corrompido');
        }
        if (bytes.length > kMaxEntryBytes) {
          throw const ImportFormatException('arquivo grande demais');
        }
        if (bytes.isEmpty) throw const ImportFormatException('arquivo vazio');
      }
      final parsed = switch (ext.replaceAll('.gz', '')) {
        '.fit' => parseFit(bytes),
        '.gpx' => parseGpx(_text(bytes)),
        _ => parseTcx(_text(bytes)),
      };
      final result = buildImportedActivity(
        parsed,
        hash: contentHash(bytes),
        sportOverride: sportOverride,
        nameOverride: nameOverride,
      );
      return switch (result) {
        BuiltActivity(:final activity) => ImportStepActivity(source, activity),
        SkippedSport(:final label) => ImportStepSkipped(source, label),
      };
    } on ImportFormatException catch (e) {
      return ImportStepError(source, e.message);
    } on FileSystemException {
      return ImportStepError(source, 'nao foi possivel ler');
    } on Object {
      return ImportStepError(source, 'arquivo mal formado');
    }
  }

  /// Texto XML: UTF-8 (com ou sem BOM) e sem espacos antes da declaracao,
  /// que alguns aparelhos deixam e o XML nao aceita.
  static String _text(Uint8List bytes) =>
      utf8.decode(bytes, allowMalformed: true).replaceFirst('﻿', '').trimLeft();

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    for (final z in _zips) {
      z.close();
    }
  }
}

// --- Isolate ---

/// [LocalImportFeed] rodando num isolate separado.
class IsolateImportFeed implements ImportFeed {
  final Isolate _isolate;
  final ReceivePort _port;
  final StreamIterator<Object?> _replies;
  final SendPort _commands;
  @override
  final int total;
  bool _closed = false;

  IsolateImportFeed._(this._isolate, this._port, this._replies, this._commands, this.total);

  static Future<IsolateImportFeed> open(List<String> paths) async {
    final port = ReceivePort();
    final isolate = await Isolate.spawn(_worker, (port.sendPort, paths));
    final replies = StreamIterator<Object?>(port);
    Future<Object?> reply() async {
      if (!await replies.moveNext()) throw StateError('isolate da importacao parou');
      return replies.current;
    }

    final commands = await reply() as SendPort;
    final total = await reply() as int;
    return IsolateImportFeed._(isolate, port, replies, commands, total);
  }

  @override
  Future<ImportStep?> next() async {
    if (_closed) return null;
    _commands.send('next');
    if (!await _replies.moveNext()) return null;
    if (_closed) return null;
    return _replies.current as ImportStep?;
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _commands.send('close');
    _isolate.kill(priority: Isolate.beforeNextEvent);
    await _replies.cancel();
    _port.close();
  }

  static Future<void> _worker((SendPort, List<String>) args) async {
    final (out, paths) = args;
    final commands = ReceivePort();
    out.send(commands.sendPort);
    final feed = await LocalImportFeed.open(paths);
    out.send(feed.total);
    await for (final cmd in commands) {
      if (cmd == 'next') {
        out.send(await feed.next());
      } else {
        await feed.close();
        commands.close();
      }
    }
  }
}
