// Reconexao com o Postgres: o banco derruba as conexoes do servidor e o
// store volta a funcionar sozinho. So roda com PG_TEST_PORT (ex.: 5433).
import 'dart:io';
import 'dart:math';

import 'package:postgres/postgres.dart';
import 'package:strava_estudo_backend/src/postgres_store.dart';
import 'package:test/test.dart';

void main() {
  final String? porta = Platform.environment['PG_TEST_PORT'];

  test('conexoes derrubadas pelo banco: o store reconecta', () async {
    final String app = 'rastro-teste-${Random().nextInt(1 << 30)}';
    final store = await PostgresActivityStore.connect(
        host: 'localhost',
        port: int.parse(porta!),
        database: 'atividades',
        username: 'postgres',
        password: 'postgres',
        applicationName: app);
    addTearDown(store.close);
    expect(await store.ping(), isTrue);

    final admin = await Connection.open(
        Endpoint(
            host: 'localhost',
            port: int.parse(porta),
            database: 'atividades',
            username: 'postgres',
            password: 'postgres'),
        settings: const ConnectionSettings(sslMode: SslMode.disable));
    addTearDown(admin.close);
    final derrubadas = await admin.execute(
        Sql.named('SELECT pg_terminate_backend(pid) FROM pg_stat_activity '
            'WHERE application_name = @app'),
        parameters: {'app': app});
    expect(derrubadas, isNotEmpty);

    // A primeira chamada pode encontrar a conexao morta; a seguinte ja usa
    // uma nova. Nenhuma pode ficar presa para sempre.
    var funcionou = false;
    for (var i = 0; i < 3 && !funcionou; i++) {
      try {
        funcionou = await store.ping().timeout(const Duration(seconds: 5));
      } catch (_) {}
    }
    expect(funcionou, isTrue);
  }, skip: porta == null ? 'sem PG_TEST_PORT' : false);
}
