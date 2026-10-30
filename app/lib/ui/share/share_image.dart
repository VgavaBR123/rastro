// Grava um RepaintBoundary como PNG para a folha de compartilhamento. Usado
// pela imagem da atividade e pela do capitulo (F05).
library;

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Desenha o que esta sob [boundaryKey] a [pixelRatio] e grava em
/// `<dir>/<fileName>.png`. Uma imagem por vez na pasta: as anteriores sao
/// apagadas. Devolve o caminho.
Future<String> writeShareImage({
  required GlobalKey boundaryKey,
  required Directory dir,
  required String fileName,
  required double pixelRatio,
}) async {
  final boundary =
      boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: pixelRatio);
  final ByteData? bytes;
  try {
    bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  } finally {
    image.dispose();
  }
  if (bytes == null) throw StateError('falha ao codificar a imagem');

  if (await dir.exists()) {
    await for (final old in dir.list()) {
      if (old is File) await old.delete();
    }
  } else {
    await dir.create(recursive: true);
  }
  final file = File('${dir.path}/$fileName.png');
  await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
  return file.path;
}
