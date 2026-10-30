// Testes das configuracoes: persistencia no banco e controller.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/settings/settings_controller.dart';

void main() {
  late RecordingDatabase db;
  setUp(() => db = RecordingDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  test('loadSettings cria a linha padrao (metrico, auto-pause ligados)', () async {
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

  test('ensureLoaded espera o banco e nao relê a cada chamada', () async {
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

  test('checklist de confiabilidade: marca visto e persiste (F01)', () async {
    final c1 = SettingsController(db);
    await c1.load();
    expect(c1.state.reliabilityChecklistSeen, isFalse);
    await c1.markReliabilityChecklistSeen();
    expect(c1.state.reliabilityChecklistSeen, isTrue);
    // Trocar outra configuracao nao apaga a marca.
    await c1.setUseMetric(false);
    expect(c1.state.reliabilityChecklistSeen, isTrue);

    final c2 = SettingsController(db);
    await c2.load();
    expect(c2.state.reliabilityChecklistSeen, isTrue);
  });

  test('leituras e gravacoes simultaneas nao estouram a linha unica', () async {
    await Future.wait([
      db.loadSettings(),
      db.saveSettings(reliabilityChecklistSeen: true),
      db.loadSettings(),
    ]);
    expect((await db.loadSettings()).reliabilityChecklistSeen, isTrue);
  });

  test('ocultar tambem no servidor: padrao ligado, desliga e persiste (F02)', () async {
    final c1 = SettingsController(db);
    await c1.load();
    expect(c1.state.hideOnServer, isTrue);
    await c1.setHideOnServer(false);
    expect(c1.state.hideOnServer, isFalse);
    // Outras alteracoes nao religam.
    await c1.setUseMetric(false);
    expect(c1.state.hideOnServer, isFalse);
    final c2 = SettingsController(db);
    await c2.load();
    expect(c2.state.hideOnServer, isFalse);
  });

  test('voz do plano 5 km: padrao ligada, desliga e persiste (F06)', () async {
    final c1 = SettingsController(db);
    await c1.load();
    expect(c1.state.plan5kVoice, isTrue);
    await c1.setPlan5kVoice(false);
    expect(c1.state.plan5kVoice, isFalse);
    // Independente do Narrador geral e mantida pelas outras alteracoes.
    await c1.setNarratorEnabled(true);
    await c1.setWeightKg(70);
    expect(c1.state.plan5kVoice, isFalse);
    final c2 = SettingsController(db);
    await c2.load();
    expect(c2.state.plan5kVoice, isFalse);
    expect(c2.state.narrator.enabled, isTrue);
  });
}
