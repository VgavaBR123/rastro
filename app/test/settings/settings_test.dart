// Testes das configuracoes: persistencia no banco e controller.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/settings/settings_controller.dart';

void main() {
  late RecordingDatabase db;
  setUp(() => db = RecordingDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  test('loadSettings cria a linha padrao (métrico, auto-pause ligados)', () async {
    final s = await db.loadSettings();
    expect(s.useMetric, true);
    expect(s.autoPauseEnabled, true);
  });

  test('saveSettings persiste e sobrevive a nova leitura', () async {
    await db.saveSettings(useMetric: false, autoPauseEnabled: false);
    final s = await db.loadSettings();
    expect(s.useMetric, false);
    expect(s.autoPauseEnabled, false);
  });

  test('controller carrega e persiste alteracoes', () async {
    final c1 = SettingsController(db);
    await c1.load();
    expect(c1.state.useMetric, true);

    await c1.setUseMetric(false);
    expect(c1.state.useMetric, false);

    // Novo controller no mesmo banco deve ler o valor persistido.
    final c2 = SettingsController(db);
    await c2.load();
    expect(c2.state.useMetric, false);
  });

  test('ensureLoaded espera o banco e não relê a cada chamada', () async {
    await db.saveSettings(autoPauseEnabled: false);
    final c = SettingsController(db);
    // Antes de carregar, o estado e o padrao (auto-pause ligado).
    expect(c.state.autoPauseEnabled, true);
    final a = c.ensureLoaded();
    final b = c.ensureLoaded();
    expect(identical(a, b), isTrue);
    await a;
    expect(c.state.autoPauseEnabled, false);
  });
}
