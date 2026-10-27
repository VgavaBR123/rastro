// Envio de email da recuperacao de senha. A API depende so da interface
// Mailer; o bin/server.dart escolhe a implementacao pela variavel MAILER:
//  - console (padrao): imprime destinatario e codigo no log. So para
//    desenvolvimento; e o UNICO lugar onde o codigo aparece em log.
//  - smtp: envia por um servidor SMTP (pacote `mailer` do pub.dev),
//    configurado por SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASSWORD,
//    SMTP_FROM e SMTP_SSL.
library;

import 'dart:io' show stdout;

import 'package:mailer/mailer.dart' as m;
import 'package:mailer/smtp_server.dart' as m;

abstract class Mailer {
  /// Envia o codigo de recuperacao [code] para [to], valido por [validFor].
  Future<void> sendPasswordResetCode({
    required String to,
    required String code,
    required Duration validFor,
  });
}

/// Desenvolvimento: escreve o codigo no log do servidor em vez de enviar.
class ConsoleMailer implements Mailer {
  ConsoleMailer({void Function(String linha)? escrever})
      : _escrever = escrever ?? stdout.writeln;

  final void Function(String linha) _escrever;

  @override
  Future<void> sendPasswordResetCode({
    required String to,
    required String code,
    required Duration validFor,
  }) async {
    _escrever('[mailer:console] codigo de recuperacao para $to: $code '
        '(valido por ${validFor.inMinutes} min)');
  }
}

/// Configuracao SMTP lida do ambiente.
class SmtpConfig {
  final String host;
  final int port;
  final String? username;
  final String? password;
  final String from;

  /// true = TLS direto (porta 465). false = STARTTLS; o pacote recusa enviar
  /// se o servidor nao suportar TLS.
  final bool ssl;

  const SmtpConfig({
    required this.host,
    required this.port,
    required this.from,
    this.username,
    this.password,
    this.ssl = false,
  });

  /// Le SMTP_* de [env]. Lanca [StateError] se faltar algo obrigatorio, para
  /// o servidor nao subir com o envio quebrado.
  factory SmtpConfig.fromEnv(Map<String, String> env) {
    String? valor(String k) {
      final String? v = env[k]?.trim();
      return (v == null || v.isEmpty) ? null : v;
    }

    final String? host = valor('SMTP_HOST');
    final String? from = valor('SMTP_FROM');
    if (host == null) throw StateError('MAILER=smtp exige SMTP_HOST');
    if (from == null) throw StateError('MAILER=smtp exige SMTP_FROM');
    final String sslTxt = (valor('SMTP_SSL') ?? 'false').toLowerCase();
    final bool ssl = sslTxt == '1' || sslTxt == 'true';
    final String? portaTxt = valor('SMTP_PORT');
    final int? porta = portaTxt == null ? null : int.tryParse(portaTxt);
    if (portaTxt != null && (porta == null || porta < 1 || porta > 65535)) {
      throw StateError('SMTP_PORT invalida: $portaTxt');
    }
    return SmtpConfig(
      host: host,
      port: porta ?? (ssl ? 465 : 587),
      from: from,
      username: valor('SMTP_USER'),
      password: valor('SMTP_PASSWORD'),
      ssl: ssl,
    );
  }
}

/// Envio real por SMTP. Nao loga o codigo nem as credenciais.
class SmtpMailer implements Mailer {
  SmtpMailer(this.config)
      : _server = m.SmtpServer(
          config.host,
          port: config.port,
          ssl: config.ssl,
          username: config.username,
          password: config.password,
        );

  final SmtpConfig config;
  final m.SmtpServer _server;

  @override
  Future<void> sendPasswordResetCode({
    required String to,
    required String code,
    required Duration validFor,
  }) async {
    final m.Message msg = m.Message()
      ..from = m.Address(config.from)
      ..recipients.add(to)
      ..subject = 'Codigo para redefinir sua senha'
      ..text = 'Seu codigo para redefinir a senha e: $code\n\n'
          'Ele vale por ${validFor.inMinutes} minutos e so pode ser usado uma '
          'vez. Se voce nao pediu a troca de senha, ignore este email.';
    await m.send(msg, _server, timeout: const Duration(seconds: 20));
  }
}
