// Borda do nivel de bateria (relatorio 05: registrar o nivel no inicio e no fim
// da atividade, para diagnostico). Implementacao real sobre `battery_plus`.
library;

import 'package:battery_plus/battery_plus.dart';

abstract class BatteryLevelSource {
  /// Nivel em porcento (0-100), ou null quando nao da para ler. Nunca lanca.
  Future<int?> level();
}

class NoBatteryLevelSource implements BatteryLevelSource {
  const NoBatteryLevelSource();

  @override
  Future<int?> level() async => null;
}

class BatteryPlusLevelSource implements BatteryLevelSource {
  final Battery _battery;

  BatteryPlusLevelSource([Battery? battery]) : _battery = battery ?? Battery();

  @override
  Future<int?> level() async {
    try {
      final v = await _battery.batteryLevel;
      return (v >= 0 && v <= 100) ? v : null;
    } catch (_) {
      // Diagnostico nao pode derrubar a gravacao.
      return null;
    }
  }
}
