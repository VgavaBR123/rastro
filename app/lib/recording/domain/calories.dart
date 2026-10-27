/// Estimativa de calorias de uma atividade (relatorio 05: o cabecalho guarda
/// calorias). CONTRATO fixo; implementacao em andamento.
library;

import 'recording_models.dart';

/// Kcal estimadas, ou null quando nao da para estimar (sem peso, sem tempo).
double? estimateCaloriesKcal({
  required ActivityType type,
  required int timerTimeMs,
  required double distanceMeters,
  required double? weightKg,
}) {
  return null; // stub: implementacao pelo agente de dominio
}
