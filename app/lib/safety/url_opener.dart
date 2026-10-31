// Abre o link publico da posicao (shareUrl) no navegador. So abre https no
// host do NOSSO backend (o de kSyncBaseUrl); http e localhost so em build de
// debug (backend local no emulador). Fica atras de interface para os testes e
// o E2E trocarem.
library;

// ignore_for_file: prefer_initializing_formals

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlOpenResult {
  final bool opened;

  /// Mensagem para a tela quando nao abriu.
  final String? error;
  const UrlOpenResult.opened() : opened = true, error = null;
  const UrlOpenResult.failed(String this.error) : opened = false;
}

abstract interface class UrlOpener {
  Future<UrlOpenResult> open(String url);
}

const Set<String> _kDebugHosts = {'localhost', '127.0.0.1', '10.0.2.2'};

class LauncherUrlOpener implements UrlOpener {
  final String _backendHost;
  final bool _debug;
  final Future<bool> Function(Uri uri) _launch;

  LauncherUrlOpener({required String backendBaseUrl, bool debug = kDebugMode, Future<bool> Function(Uri uri)? launch})
    : _backendHost = Uri.tryParse(backendBaseUrl)?.host ?? '',
      _debug = debug,
      _launch = launch ?? ((u) => launchUrl(u, mode: LaunchMode.externalApplication));

  /// Null se o link pode abrir; senao, o motivo.
  String? check(String url) {
    const bad = 'Este link nao e do Rastro e nao foi aberto.';
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return bad;
    final https = uri.scheme == 'https';
    final http = uri.scheme == 'http';
    if (!https && !(_debug && http)) return bad;
    final hostOk = uri.host == _backendHost || (_debug && _kDebugHosts.contains(uri.host));
    return hostOk ? null : bad;
  }

  @override
  Future<UrlOpenResult> open(String url) async {
    final err = check(url);
    if (err != null) return UrlOpenResult.failed(err);
    try {
      if (await _launch(Uri.parse(url))) return const UrlOpenResult.opened();
    } catch (_) {
      // Sem navegador ou plugin indisponivel.
    }
    return const UrlOpenResult.failed('Nao deu para abrir o link da localizacao.');
  }
}
