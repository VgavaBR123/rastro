// Preferencias do Narrador (F03) nas configuracoes: padrao, persistencia pelo
// controller e migracao 8 -> 9 sobre arquivo real.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/narrator/domain/narrator_settings.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/settings/settings_controller.dart';

void main() {
  group('em memoria', () {
    late RecordingDatabase db;
    setUp(() => db = RecordingDatabase(NativeDatabase.memory()));
    tearDown(() async => db.close());

    test('schema na versao 9', () {
      expect(db.schemaVersion, greaterThanOrEqualTo(9));
    });

    test('padrao: sem preferencia salva vira o padrao (desligado)', () async {
      final row = await db.loadSettings();
      expect(row.narratorPrefs, isNull);
      final c = SettingsController(db);
      await c.load();
      expect(c.state.narrator, const NarratorSettings());
    });

    test('controller persiste o narrador e outras configuracoes nao apagam', () async {
      final c1 = SettingsController(db);
      await c1.load();
      const prefs = NarratorSettings(enabled: true, timeEveryMinutes: 10, essentialOnly: true);
      await c1.setNarrator(prefs);
      expect(c1.state.narrator, prefs);
      await c1.setUseMetric(false);
      await c1.setWeightKg(70);
      expect(c1.state.narrator, prefs);

      final c2 = SettingsController(db);
      await c2.load();
      expect(c2.state.narrator, prefs);
    });

    test('atalho liga/desliga mexe so no enabled', () async {
      final c = SettingsController(db);
      await c.load();
      await c.setNarrator(const NarratorSettings(timeEveryMinutes: 5));
      await c.setNarratorEnabled(true);
      expect(c.state.narrator.enabled, isTrue);
      expect(c.state.narrator.timeEveryMinutes, 5);
      final again = SettingsController(db);
      await again.load();
      expect(again.state.narrator.enabled, isTrue);
    });

    // Revisao F03: a tela salvava o objeto inteiro sem esperar a carga do
    // banco; antes de carregar, o estado e o padrao e as preferencias salvas
    // eram sobrescritas. updateNarrator espera a carga e muda so o campo.
    test('updateNarrator antes da carga preserva as preferencias salvas', () async {
      final c1 = SettingsController(db);
      await c1.load();
      await c1.setNarrator(const NarratorSettings(enabled: true, timeEveryMinutes: 10));

      final c2 = SettingsController(db); // ainda nao carregou
      await c2.updateNarrator((n) => n.copyWith(essentialOnly: true));
      expect(c2.state.narrator.enabled, isTrue);
      expect(c2.state.narrator.timeEveryMinutes, 10);
      expect(c2.state.narrator.essentialOnly, isTrue);

      final c3 = SettingsController(db);
      await c3.load();
      expect(c3.state.narrator, c2.state.narrator);
    });

    test('JSON corrompido no banco nao quebra a carga', () async {
      await db.customStatement("UPDATE settings_rows SET narrator_prefs = '{oops'");
      await db.loadSettings();
      await db.customStatement("UPDATE settings_rows SET narrator_prefs = '{oops'");
      final c = SettingsController(db);
      await c.load();
      expect(c.state.narrator, const NarratorSettings());
    });
  });

  test('migracao 8 -> 9 cria a coluna sem perder as configuracoes', () async {
    final dir = Directory.systemTemp.createTempSync('rastro_mig9');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/rec.sqlite');

    var fileDb = RecordingDatabase(NativeDatabase(file));
    await fileDb.saveSettings(useMetric: false, hideOnServer: false);
    await fileDb.close();

    fileDb = RecordingDatabase(
      NativeDatabase(
        file,
        setup: (raw) {
          final v = raw.select('PRAGMA user_version').first.values.first;
          if (v != 14) return;
          raw.execute('DROP TABLE safety_local_sessions');
          raw.execute('ALTER TABLE activities DROP COLUMN import_source');
          raw.execute('DROP TABLE plan5k_states');
          raw.execute('DROP TABLE plan5k_sessions');
          raw.execute('ALTER TABLE settings_rows DROP COLUMN plan5k_voice');
          raw.execute('ALTER TABLE settings_rows DROP COLUMN chapter_month_seen');
          // F04 (schema 10) veio depois: tira o que e dele.
          raw.execute('ALTER TABLE activities DROP COLUMN rpe');
          raw.execute('ALTER TABLE activities DROP COLUMN mood');
          raw.execute('ALTER TABLE settings_rows DROP COLUMN gentle_mode');
          raw.execute('ALTER TABLE settings_rows DROP COLUMN narrator_prefs');
          raw.execute('PRAGMA user_version = 8');
        },
      ),
    );
    addTearDown(fileDb.close);

    final row = await fileDb.loadSettings();
    expect(row.useMetric, isFalse);
    expect(row.hideOnServer, isFalse);
    expect(row.narratorPrefs, isNull);
    await fileDb.saveSettings(narratorPrefs: const NarratorSettings(enabled: true).toJsonString());
    expect(
      NarratorSettings.fromJsonString((await fileDb.loadSettings()).narratorPrefs).enabled,
      isTrue,
    );
  });
}
