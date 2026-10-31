/// Leitor de ZIP por partes (F07), com dart:io e o inflate do proprio Dart.
///
/// Escrito a partir da especificacao publica do formato (APPNOTE do PKWARE):
/// le so o diretorio central no fim do arquivo e, para cada entrada pedida, o
/// trecho dela, em blocos. Uma exportacao de conta de 1 a 2 GB nunca e
/// carregada inteira na memoria; so uma atividade por vez (com teto
/// [kMaxEntryBytes]).
///
/// Suporta entradas sem compressao (0) e deflate (8), nomes UTF-8 e ZIP64.
/// Sincrono de proposito: roda no isolate da importacao.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'crc32.dart';
import 'import_models.dart';

/// Teto de uma entrada descomprimida (um arquivo de atividade). Arquivos de
/// atividade tem de KB a poucos MB; acima disso e lixo ou ataque (zip bomb).
const int kMaxEntryBytes = 96 * 1024 * 1024;

const int _chunk = 64 * 1024;

class ZipEntry {
  final String name;
  final int method;
  final int crc;
  final int compressedSize;
  final int size;
  final int localHeaderOffset;

  const ZipEntry({
    required this.name,
    required this.method,
    required this.crc,
    required this.compressedSize,
    required this.size,
    required this.localHeaderOffset,
  });
}

Never _fail(String m) => throw ImportFormatException(m);

class ZipReader {
  final RandomAccessFile _file;
  final List<ZipEntry> entries;

  ZipReader._(this._file, this.entries);

  /// Abre [path] e le o diretorio central. Lanca [ImportFormatException] se
  /// nao for ZIP ou estiver truncado.
  factory ZipReader.open(String path) {
    final file = File(path).openSync();
    try {
      return ZipReader._(file, _readDirectory(file));
    } on Object {
      file.closeSync();
      rethrow;
    }
  }

  ZipEntry? find(String name) {
    for (final e in entries) {
      if (e.name == name) return e;
    }
    return null;
  }

  /// Conteudo descomprimido de [entry], conferido pelo CRC.
  Uint8List read(ZipEntry entry, {int maxBytes = kMaxEntryBytes}) {
    if (entry.size > maxBytes) _fail('arquivo grande demais');
    _file.setPositionSync(entry.localHeaderOffset);
    final local = _file.readSync(30);
    if (local.length < 30 || _u32(local, 0) != 0x04034b50) {
      _fail('ZIP corrompido (cabecalho local)');
    }
    final dataStart =
        entry.localHeaderOffset + 30 + _u16(local, 26) + _u16(local, 28);
    _file.setPositionSync(dataStart);

    final out = BytesBuilder(copy: false);
    final crc = Crc32();
    void collect(List<int> chunk) {
      if (out.length + chunk.length > maxBytes) _fail('arquivo grande demais');
      crc.add(chunk);
      out.add(chunk);
    }

    var left = entry.compressedSize;
    if (entry.method == 0) {
      while (left > 0) {
        final part = _file.readSync(left < _chunk ? left : _chunk);
        if (part.isEmpty) _fail('ZIP truncado');
        collect(part);
        left -= part.length;
      }
    } else if (entry.method == 8) {
      final sink = _CallbackSink(collect);
      final inflate = ZLibDecoder(raw: true).startChunkedConversion(sink);
      try {
        while (left > 0) {
          final part = _file.readSync(left < _chunk ? left : _chunk);
          if (part.isEmpty) _fail('ZIP truncado');
          inflate.add(part);
          left -= part.length;
        }
        inflate.close();
      } on FormatException {
        _fail('dados corrompidos no ZIP');
      } on FileSystemException {
        _fail('dados corrompidos no ZIP');
      }
    } else {
      _fail('compressao do ZIP nao suportada');
    }
    final bytes = out.takeBytes();
    if (bytes.length != entry.size || crc.value != entry.crc) {
      _fail('dados corrompidos no ZIP (CRC)');
    }
    return bytes;
  }

  void close() => _file.closeSync();
}

class _CallbackSink implements Sink<List<int>> {
  final void Function(List<int>) onData;
  _CallbackSink(this.onData);
  @override
  void add(List<int> data) => onData(data);
  @override
  void close() {}
}

int _u16(List<int> b, int o) => b[o] | (b[o + 1] << 8);
int _u32(List<int> b, int o) =>
    b[o] | (b[o + 1] << 8) | (b[o + 2] << 16) | (b[o + 3] << 24);
int _u64(List<int> b, int o) => _u32(b, o) + (_u32(b, o + 4) << 32);

List<ZipEntry> _readDirectory(RandomAccessFile file) {
  final length = file.lengthSync();
  if (length < 22) _fail('arquivo ZIP vazio ou invalido');
  final tailLen = length < 65557 ? length : 65557;
  file.setPositionSync(length - tailLen);
  final tail = file.readSync(tailLen);
  var eocd = -1;
  for (var i = tail.length - 22; i >= 0; i--) {
    if (tail[i] == 0x50 && _u32(tail, i) == 0x06054b50) {
      eocd = i;
      break;
    }
  }
  if (eocd < 0) _fail('nao e um ZIP (ou esta truncado)');
  final eocdPos = length - tailLen + eocd;
  var count = _u16(tail, eocd + 10);
  var cdSize = _u32(tail, eocd + 12);
  var cdOffset = _u32(tail, eocd + 16);

  if (count == 0xFFFF || cdSize == 0xFFFFFFFF || cdOffset == 0xFFFFFFFF) {
    // ZIP64: o localizador fica 20 bytes antes do fim do diretorio.
    if (eocdPos < 20) _fail('ZIP64 invalido');
    file.setPositionSync(eocdPos - 20);
    final loc = file.readSync(20);
    if (_u32(loc, 0) != 0x07064b50) _fail('ZIP64 invalido');
    file.setPositionSync(_u64(loc, 8));
    final z = file.readSync(56);
    if (z.length < 56 || _u32(z, 0) != 0x06064b50) _fail('ZIP64 invalido');
    count = _u64(z, 32);
    cdSize = _u64(z, 40);
    cdOffset = _u64(z, 48);
  }
  if (cdOffset + cdSize > length) _fail('ZIP truncado');

  file.setPositionSync(cdOffset);
  final cd = file.readSync(cdSize);
  if (cd.length < cdSize) _fail('ZIP truncado');
  final entries = <ZipEntry>[];
  var p = 0;
  for (var n = 0; n < count; n++) {
    if (p + 46 > cd.length || _u32(cd, p) != 0x02014b50) {
      _fail('ZIP corrompido (diretorio central)');
    }
    final flags = _u16(cd, p + 8);
    final method = _u16(cd, p + 10);
    final crc = _u32(cd, p + 16);
    var comp = _u32(cd, p + 20);
    var size = _u32(cd, p + 24);
    final nameLen = _u16(cd, p + 28);
    final extraLen = _u16(cd, p + 30);
    final commentLen = _u16(cd, p + 32);
    var offset = _u32(cd, p + 42);
    final nameStart = p + 46;
    if (nameStart + nameLen + extraLen > cd.length) {
      _fail('ZIP corrompido (diretorio central)');
    }
    final nameBytes = cd.sublist(nameStart, nameStart + nameLen);
    final name = _decodeName(nameBytes, utf8Flag: (flags & 0x800) != 0);

    // Extra ZIP64 (0x0001): os campos que valem 0xFFFFFFFF, nesta ordem.
    var e = nameStart + nameLen;
    final extraEnd = e + extraLen;
    while (e + 4 <= extraEnd) {
      final id = _u16(cd, e);
      final len = _u16(cd, e + 2);
      if (id == 0x0001) {
        var q = e + 4;
        if (size == 0xFFFFFFFF && q + 8 <= e + 4 + len) {
          size = _u64(cd, q);
          q += 8;
        }
        if (comp == 0xFFFFFFFF && q + 8 <= e + 4 + len) {
          comp = _u64(cd, q);
          q += 8;
        }
        if (offset == 0xFFFFFFFF && q + 8 <= e + 4 + len) {
          offset = _u64(cd, q);
        }
      }
      e += 4 + len;
    }
    p = extraEnd + commentLen;
    if (name.endsWith('/')) continue;
    entries.add(ZipEntry(
      name: name,
      method: method,
      crc: crc,
      compressedSize: comp,
      size: size,
      localHeaderOffset: offset,
    ));
  }
  return entries;
}

String _decodeName(List<int> bytes, {required bool utf8Flag}) {
  try {
    return utf8.decode(bytes);
  } on FormatException {
    // Sem UTF-8 valido: nome antigo (CP437/latin1); o latin1 nao falha.
    return utf8Flag ? utf8.decode(bytes, allowMalformed: true) : latin1.decode(bytes);
  }
}
