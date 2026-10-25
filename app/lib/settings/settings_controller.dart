// Controller das configuracoes: carrega do banco e persiste alteracoes.
library;

import 'package:flutter_riverpod/legacy.dart';

import '../persistence/database.dart';
import 'app_settings.dart';

class SettingsController extends StateNotifier<AppSettings> {
  final RecordingDatabase _db;

  SettingsController(this._db) : super(const AppSettings());

  Future<void> load() async {
    final row = await _db.loadSettings();
    state = AppSettings(
      useMetric: row.useMetric,
      autoPauseEnabled: row.autoPauseEnabled,
    );
  }

  Future<void> setUseMetric(bool value) async {
    state = state.copyWith(useMetric: value);
    await _db.saveSettings(useMetric: value);
  }

  Future<void> setAutoPauseEnabled(bool value) async {
    state = state.copyWith(autoPauseEnabled: value);
    await _db.saveSettings(autoPauseEnabled: value);
  }
}
