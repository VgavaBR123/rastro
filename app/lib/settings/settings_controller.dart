// Controller das configuracoes: carrega do banco e persiste alteracoes.
library;

import 'package:flutter_riverpod/legacy.dart';

import 'package:drift/drift.dart' show Value;

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
}
