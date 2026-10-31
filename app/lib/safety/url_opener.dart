// Abre o link publico da posicao (shareUrl) no navegador. Atras de
// interface para os testes e o E2E trocarem.
library;

import 'package:url_launcher/url_launcher.dart';

abstract interface class UrlOpener {
  /// Abre [url] fora do app. Devolve se abriu.
  Future<bool> open(String url);
}

class LauncherUrlOpener implements UrlOpener {
  const LauncherUrlOpener();

  @override
  Future<bool> open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
