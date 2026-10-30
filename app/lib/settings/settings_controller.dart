// Controller das configuracoes: carrega do banco e persiste alteracoes.
library;

import 'package:flutter_riverpod/legacy.dart';

import 'package:drift/drift.dart' show Value;

import '../narrator/domain/narrator_settings.dart';
import '../persistence/database.dart';
import 'app_settings.dart';

class SettingsController extends StateNotifier<AppSettings> {
  final RecordingDatabase _db;

  SettingsController(this._db) : super(const AppSettings());

  Future<void>? _loaded;

  /// Garante que as configuracoes ja vieram do banco. Ate isso, o estado e o
  /// PADRAO (auto-pausa ligada, sem peso): quem decide algo com elas na
  /// abertura do app (ex.: iniciar uma gravacao) precisa esperar isto.
  /// Carrega uma vez so; chamadas seguintes devolvem o mesmo Future.
  Future<void> ensureLoaded() => _loaded ??= load();

  Future<void> load() async {
    final row = await _db.loadSettings();
    state = AppSettings(
      useMetric: row.useMetric,
      autoPauseEnabled: row.autoPauseEnabled,
      weightKg: row.weightKg,
      reliabilityChecklistSeen: row.reliabilityChecklistSeen,
      hideOnServer: row.hideOnServer,
      narrator: NarratorSettings.fromJsonString(row.narratorPrefs),
      gentleMode: row.gentleMode,
    );
  }

  /// Peso em kg (null apaga). Valores fora de 20..400 sao recusados.
  Future<bool> setWeightKg(double? value) async {
    if (value != null && (value < 20 || value > 400)) return false;
    state = state.withWeightKg(value);
    await _db.saveSettings(weightKg: Value(value));
    return true;
  }

  Future<void> setUseMetric(bool value) async {
    state = state.copyWith(useMetric: value);
    await _db.saveSettings(useMetric: value);
  }

  Future<void> setAutoPauseEnabled(bool value) async {
    state = state.copyWith(autoPauseEnabled: value);
    await _db.saveSettings(autoPauseEnabled: value);
  }

  /// O checklist "Gravacao confiavel" ja foi mostrado (F01).
  Future<void> markReliabilityChecklistSeen() async {
    state = state.copyWith(reliabilityChecklistSeen: true);
    await _db.saveSettings(reliabilityChecklistSeen: true);
  }

  /// Privacidade (F02): cortar as pontas ocultas tambem no upload.
  Future<void> setHideOnServer(bool value) async {
    state = state.copyWith(hideOnServer: value);
    await _db.saveSettings(hideOnServer: value);
  }

  /// Narrador por voz (F03): todas as preferencias de uma vez.
  Future<void> setNarrator(NarratorSettings value) async {
    state = state.copyWith(narrator: value);
    await _db.saveSettings(narratorPrefs: value.toJsonString());
  }

  /// Muda as preferencias do Narrador a partir das que estao salvas: espera a
  /// carga do banco antes, para nao sobrescrever com o padrao.
  Future<void> updateNarrator(
    NarratorSettings Function(NarratorSettings current) change,
  ) async {
    await ensureLoaded();
    await setNarrator(change(state.narrator));
  }

  /// Atalho liga/desliga do Narrador (tela Gravar).
  Future<void> setNarratorEnabled(bool value) =>
      updateNarrator((n) => n.copyWith(enabled: value));

  /// Modo Gentil (F04): esconde pace e velocidade em todo o app.
  Future<void> setGentleMode(bool value) async {
    state = state.copyWith(gentleMode: value);
    await _db.saveSettings(gentleMode: value);
  }
}
