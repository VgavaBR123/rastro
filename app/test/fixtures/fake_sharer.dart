// Compartilhamento falso: guarda os textos ou falha como a plataforma.
import 'package:flutter/services.dart';
import 'package:strava_estudo_app/platform/activity_sharer.dart';

class FakeActivitySharer implements ActivitySharer {
  final List<String> texts = [];
  bool fail = false;

  @override
  Future<void> shareText(String text) async {
    if (fail) throw PlatformException(code: 'share_failed');
    texts.add(text);
  }
}
