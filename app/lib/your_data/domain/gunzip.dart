/// gzip descomprimido por partes com teto (F07): um .gz pequeno que expande
/// para gigabytes (gzip bomb) para no teto, sem alocar o resultado inteiro.
/// Os isolates dividem o heap do app: estourar a memoria aqui derrubaria o app.
library;

import 'dart:io';
import 'dart:typed_data';

import 'import_models.dart';

const int _chunk = 64 * 1024;

class _LimitSink implements Sink<List<int>> {
  final int maxBytes;
  final BytesBuilder out = BytesBuilder(copy: false);
  _LimitSink(this.maxBytes);

  @override
  void add(List<int> data) {
    if (out.length + data.length > maxBytes) {
      throw const ImportFormatException('arquivo grande demais');
    }
    out.add(data);
  }

  @override
  void close() {}
}

/// Conteudo de [data] (gzip) com no maximo [maxBytes]. Lanca
/// [ImportFormatException] se passar do teto ou se o gzip estiver corrompido.
Uint8List gunzipLimited(List<int> input, {required int maxBytes}) {
  final data = input is Uint8List ? input : Uint8List.fromList(input);
  final sink = _LimitSink(maxBytes);
  final decoder = GZipCodec().decoder.startChunkedConversion(sink);
  try {
    for (var i = 0; i < data.length; i += _chunk) {
      final end = i + _chunk < data.length ? i + _chunk : data.length;
      decoder.add(Uint8List.sublistView(data, i, end));
    }
    decoder.close();
  } on ImportFormatException {
    rethrow;
  } on FormatException {
    throw const ImportFormatException('arquivo .gz corrompido');
  } on FileSystemException {
    throw const ImportFormatException('arquivo .gz corrompido');
  }
  return sink.out.takeBytes();
}
