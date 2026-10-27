// Ponto de entrada do backend. Sobe a API shelf sobre o PostgresActivityStore
// (ou em memoria se USE_INMEMORY=1). Configuracao por variaveis de ambiente.
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:strava_estudo_backend/src/activity_store.dart';
import 'package:strava_estudo_backend/src/api.dart';
import 'package:strava_estudo_backend/src/mailer.dart';
import 'package:strava_estudo_backend/src/postgres_store.dart';
import 'package:strava_estudo_backend/src/postgres_user_store.dart';
import 'package:strava_estudo_backend/src/user_store.dart';

String _env(String k, String def) => Platform.environment[k] ?? def;

Future<void> main() async {
  final port = int.parse(_env('PORT', '8080'));

  ActivityStore store;
  UserStore users;
  if (_env('USE_INMEMORY', '0') == '1') {
    store = InMemoryActivityStore();
    users = InMemoryUserStore();
    stdout.writeln('Store: em memoria');
  } else {
    final pg = await PostgresActivityStore.connect(
      host: _env('DB_HOST', 'localhost'),
      port: int.parse(_env('DB_PORT', '5432')),
      database: _env('DB_NAME', 'atividades'),
      username: _env('DB_USER', 'postgres'),
      password: _env('DB_PASSWORD', 'postgres'),
    );
    store = pg;
    users = PostgresUserStore(pg.connection);
    stdout.writeln('Store: Postgres em ${_env('DB_HOST', 'localhost')}');
  }

  // MAILER=console (padrao) imprime o codigo de recuperacao no log; so para
  // desenvolvimento. MAILER=smtp envia de verdade (SMTP_*).
  final String tipoMailer = _env('MAILER', 'console').trim().toLowerCase();
  final Mailer mailer;
  switch (tipoMailer) {
    case 'console':
      mailer = ConsoleMailer();
    case 'smtp':
      final config = SmtpConfig.fromEnv(Platform.environment);
      mailer = SmtpMailer(config);
      stdout.writeln('Mailer: smtp em ${config.host}:${config.port}');
    default:
      throw StateError(
          'MAILER desconhecido: $tipoMailer (use console ou smtp)');
  }
  if (tipoMailer == 'console') {
    stdout.writeln('Mailer: console (codigos de recuperacao vao para o log)');
  }

  // TRUST_PROXY=1 so atras de um proxy que SOBRESCREVE o X-Forwarded-For com o
  // IP real da conexao (o Caddy de deploy/ faz isso). Sem proxy, ligar isto
  // deixaria qualquer cliente escolher o proprio IP e fugir dos limites.
  final bool trustProxy = _env('TRUST_PROXY', '0').trim() == '1';
  stdout.writeln(trustProxy
      ? 'IP do cliente: ultimo endereco do X-Forwarded-For (TRUST_PROXY=1)'
      : 'IP do cliente: conexao direta');

  // logRequests registra so metodo, caminho e status: nunca corpo (senha) nem
  // headers (Authorization).
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(createApi(
        store,
        users,
        mailer: mailer,
        clientIp: extratorDeIp(confiarEmForwardedFor: trustProxy),
      ));

  final server = await io.serve(handler, '0.0.0.0', port);
  stdout.writeln(
      'Backend ouvindo em http://${server.address.host}:${server.port}');
}
