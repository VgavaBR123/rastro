// Envio de push plugavel. A caixa de entrada (tabela notifications) sempre
// recebe; o push e um extra para o aparelho tocar na hora. O bin/server.dart
// escolhe a implementacao: LogPushSender (padrao) ou FcmPushSender (com
// FIREBASE_SERVICE_ACCOUNT definido; ver fcm_push_sender.dart).
library;

import 'dart:io' show stdout;

/// Uma notificacao a caminho de um aparelho.
class PushMessage {
  const PushMessage({
    required this.token,
    required this.platform,
    required this.notificationId,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
  });

  final String token;
  final String platform;
  final String notificationId;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
}

enum PushResult {
  /// Entregue ao provedor.
  sent,

  /// O provedor disse que o token nao vale mais: o chamador apaga o token.
  invalidToken,

  /// Falha passageira (rede, 5xx, credencial); o token fica.
  failed,
}

abstract class PushSender {
  Future<PushResult> send(PushMessage message);
}

/// Padrao (desenvolvimento, testes, sem Firebase): so registra no log, sem o
/// token inteiro nem o corpo (pode ter nome de pessoa).
class LogPushSender implements PushSender {
  LogPushSender({void Function(String linha)? escrever})
      : _escrever = escrever ?? stdout.writeln;

  final void Function(String linha) _escrever;

  @override
  Future<PushResult> send(PushMessage m) async {
    final String inicio =
        m.token.length <= 8 ? m.token : '${m.token.substring(0, 8)}...';
    _escrever('[push:log] ${m.type} ${m.notificationId} -> '
        '${m.platform} $inicio');
    return PushResult.sent;
  }
}
