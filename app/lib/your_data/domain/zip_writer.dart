/// Escritor de ZIP (F07) para a exportacao: grava entrada por entrada direto
/// no arquivo, sem montar o ZIP na memoria. Deflate do proprio Dart e nomes
/// em UTF-8. Escrito a partir da especificacao publica do formato.
///
/// Limite: sem ZIP64 (ate 65535 entradas e 4 GB), muito acima de uma
/// exportacao de GPX de uma pessoa.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'crc32.dart';

class _Central {
  final List<int> name;
  final int method;
  final int crc;
  final int compressed;
  final int size;
  final int offset;
  const _Central(this.name, this.method, this.crc, this.compressed, this.size, this.offset);
}

class ZipWriter {
  final RandomAccessFile _file;
  final List<_Central> _entries = [];
  final Set<String> _names = {};
  final int _dosTime;
  final int _dosDate;
  int _offset = 0;

  ZipWriter._(this._file, DateTime now)
    : _dosTime = (now.hour << 11) | (now.minute << 5) | (now.second ~/ 2),
      _dosDate = ((now.year - 1980).clamp(0, 127) << 9) | (now.month << 5) | now.day;

  /// Cria (ou sobrescreve) o ZIP em [path].
  factory ZipWriter.create(String path, {DateTime? now}) =>
      ZipWriter._(File(path).openSync(mode: FileMode.write), now ?? DateTime.now());

  /// Grava [bytes] como [name]. Nome repetido ganha " (2)", " (3)"... antes da
  /// extensao. Devolve o nome usado.
  String add(String name, List<int> bytes) {
    final unique = _uniqueName(name);
    final nameBytes = utf8.encode(unique);
    final crc = crc32(bytes);
    final deflate = bytes.length > 64;
    final data = deflate ? ZLibEncoder(raw: true).convert(bytes) : bytes;
    if (_offset + data.length > 0xFFFFFFFF || _entries.length >= 0xFFFF) {
      throw StateError('exportacao grande demais para um ZIP sem ZIP64');
    }
    final h = _Bytes()
      ..u32(0x04034b50)
      ..u16(20)
      ..u16(0x0800)
      ..u16(deflate ? 8 : 0)
      ..u16(_dosTime)
      ..u16(_dosDate)
      ..u32(crc)
      ..u32(data.length)
      ..u32(bytes.length)
      ..u16(nameBytes.length)
      ..u16(0)
      ..raw(nameBytes);
    final header = h.bytes();
    _file.writeFromSync(header);
    _file.writeFromSync(data);
    _entries.add(_Central(nameBytes, deflate ? 8 : 0, crc, data.length, bytes.length, _offset));
    _offset += header.length + data.length;
    return unique;
  }

  /// Grava o diretorio central e fecha o arquivo.
  void close() {
    final cdStart = _offset;
    final cd = _Bytes();
    for (final e in _entries) {
      cd
        ..u32(0x02014b50)
        ..u16(20)
        ..u16(20)
        ..u16(0x0800)
        ..u16(e.method)
        ..u16(_dosTime)
        ..u16(_dosDate)
        ..u32(e.crc)
        ..u32(e.compressed)
        ..u32(e.size)
        ..u16(e.name.length)
        ..u16(0)
        ..u16(0)
        ..u16(0)
        ..u16(0)
        ..u32(0)
        ..u32(e.offset)
        ..raw(e.name);
    }
    final cdBytes = cd.bytes();
    _file.writeFromSync(cdBytes);
    final end = _Bytes()
      ..u32(0x06054b50)
      ..u16(0)
      ..u16(0)
      ..u16(_entries.length)
      ..u16(_entries.length)
      ..u32(cdBytes.length)
      ..u32(cdStart)
      ..u16(0);
    _file.writeFromSync(end.bytes());
    _file.closeSync();
  }

  String _uniqueName(String name) {
    if (_names.add(name)) return name;
    final slash = name.lastIndexOf('/');
    final dot = name.lastIndexOf('.');
    final hasExt = dot > slash + 1;
    final base = hasExt ? name.substring(0, dot) : name;
    final ext = hasExt ? name.substring(dot) : '';
    for (var n = 2;; n++) {
      final candidate = '$base ($n)$ext';
      if (_names.add(candidate)) return candidate;
    }
  }
}

class _Bytes {
  final BytesBuilder _b = BytesBuilder();
  void u16(int v) => _b.add([v & 0xFF, (v >> 8) & 0xFF]);
  void u32(int v) =>
      _b.add([v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >> 24) & 0xFF]);
  void raw(List<int> v) => _b.add(v);
  Uint8List bytes() => _b.toBytes();
}
