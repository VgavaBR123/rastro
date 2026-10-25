// Ponto de entrada do backend. Sobe a API shelf sobre o PostgresActivityStore
// (ou em memoria se USE_INMEMORY=1). Configuracao por variaveis de ambiente.
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:strava_estudo_backend/src/activity_store.dart';
import 'package:strava_estudo_backend/src/api.dart';
import 'package:strava_estudo_backend/src/postgres_store.dart';

String _env(String k, String def) => Platform.environment[k] ?? def;

Future<void> main() async {
  final port = int.parse(_env('PORT', '8080'));

  ActivityStore store;
  if (_env('USE_INMEMORY', '0') == '1') {
    store = InMemoryActivityStore();
    stdout.writeln('Store: em memoria');
  } else {
    store = await PostgresActivityStore.connect(
      host: _env('DB_HOST', 'localhost'),
      port: int.parse(_env('DB_PORT', '5432')),
      database: _env('DB_NAME', 'atividades'),
      username: _env('DB_USER', 'postgres'),
      password: _env('DB_PASSWORD', 'postgres'),
    );
    stdout.writeln('Store: Postgres em ${_env('DB_HOST', 'localhost')}');
  }

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(createApi(store));

  final server = await io.serve(handler, '0.0.0.0', port);
  stdout.writeln('Backend ouvindo em http://${server.address.host}:${server.port}');
}
