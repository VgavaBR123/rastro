// Fechamento gentil (F04): esforco percebido (RPE de 1 a 10), humor e carga
// do treino. Dart puro.
//
// A carga e a "session RPE" (sRPE): RPE x minutos de cronometro. Da uma
// medida de carga sem relogio nem sensor, so com o que a pessoa sentiu.
library;

/// Faixa valida do esforco percebido.
const int kRpeMin = 1;
const int kRpeMax = 10;

bool isValidRpe(int? rpe) => rpe != null && rpe >= kRpeMin && rpe <= kRpeMax;

/// [rpe] se estiver de 1 a 10; senao null.
int? normalizeRpe(int? rpe) => isValidRpe(rpe) ? rpe : null;

/// Rotulo curto por faixa: 1-2 leve, 3-4 tranquilo, 5-6 moderado, 7-8 forte,
/// 9-10 maximo.
String rpeLabel(int rpe) {
  if (!isValidRpe(rpe)) throw ArgumentError.value(rpe, 'rpe', 'de 1 a 10');
  return switch (rpe) {
    <= 2 => 'Leve',
    <= 4 => 'Tranquilo',
    <= 6 => 'Moderado',
    <= 8 => 'Forte',
    _ => 'Maximo',
  };
}

/// Como a pessoa se sentiu, do melhor para o pior. [dbValue] e o valor
/// guardado no banco e enviado ao servidor (contrato: `x-mood`).
enum Mood {
  great('great', 'Otimo'),
  good('good', 'Bem'),
  ok('ok', 'Normal'),
  tired('tired', 'Cansado'),
  awful('awful', 'Pesado');

  final String dbValue;
  final String label;
  const Mood(this.dbValue, this.label);

  /// Valor do banco; desconhecido ou null vira null.
  static Mood? fromDb(String? v) {
    for (final m in Mood.values) {
      if (m.dbValue == v) return m;
    }
    return null;
  }
}

/// Carga do treino (sRPE) = RPE x minutos de cronometro, arredondada. Null
/// sem RPE valido.
int? trainingLoad({required int? rpe, required int timerMs}) {
  if (!isValidRpe(rpe)) return null;
  final minutes = timerMs > 0 ? timerMs / 60000.0 : 0.0;
  return (rpe! * minutes).round();
}
