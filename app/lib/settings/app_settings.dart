// Configuracoes do app (imutavel), independentes da camada de banco.
library;

class AppSettings {
  final bool useMetric;
  final bool autoPauseEnabled;

  /// Peso em kg para estimar calorias; null = nao informado.
  final double? weightKg;

  /// Checklist "Gravacao confiavel" ja mostrado antes da primeira gravacao.
  final bool reliabilityChecklistSeen;

  const AppSettings({
    this.useMetric = true,
    this.autoPauseEnabled = true,
    this.weightKg,
    this.reliabilityChecklistSeen = false,
  });

  AppSettings copyWith({
    bool? useMetric,
    bool? autoPauseEnabled,
    bool? reliabilityChecklistSeen,
  }) => AppSettings(
    useMetric: useMetric ?? this.useMetric,
    autoPauseEnabled: autoPauseEnabled ?? this.autoPauseEnabled,
    weightKg: weightKg,
    reliabilityChecklistSeen:
        reliabilityChecklistSeen ?? this.reliabilityChecklistSeen,
  );

  /// Troca o peso (null apaga).
  AppSettings withWeightKg(double? value) => AppSettings(
    useMetric: useMetric,
    autoPauseEnabled: autoPauseEnabled,
    weightKg: value,
    reliabilityChecklistSeen: reliabilityChecklistSeen,
  );
}
