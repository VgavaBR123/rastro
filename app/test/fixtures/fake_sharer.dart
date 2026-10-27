// Compartilhamento falso: guarda os textos e imagens ou falha como a plataforma.
import 'package:flutter/services.dart';
import 'package:strava_estudo_app/platform/activity_sharer.dart';

class FakeActivitySharer implements ActivitySharer {
  final List<String> texts = [];
  final List<({String path, String? text})> images = [];
  bool fail = false;

  @override
  Future<void> shareText(String text) async {
    if (fail) throw PlatformException(code: 'share_failed');
    texts.add(text);
  }

  @override
  Future<void> shareImage(String path, {String? text}) async {
    if (fail) throw PlatformException(code: 'share_failed');
    images.add((path: path, text: text));
  }
}
