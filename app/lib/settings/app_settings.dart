// Configuracoes do app (imutavel), independentes da camada de banco.
library;

class AppSettings {
  final bool useMetric;
  final bool autoPauseEnabled;

  /// Peso em kg para estimar calorias; null = nao informado.
  final double? weightKg;

  const AppSettings({
    this.useMetric = true,
    this.autoPauseEnabled = true,
    this.weightKg,
  });

  AppSettings copyWith({bool? useMetric, bool? autoPauseEnabled}) => AppSettings(
        useMetric: useMetric ?? this.useMetric,
        autoPauseEnabled: autoPauseEnabled ?? this.autoPauseEnabled,
        weightKg: weightKg,
      );

  /// Troca o peso (null apaga).
  AppSettings withWeightKg(double? value) => AppSettings(
        useMetric: useMetric,
        autoPauseEnabled: autoPauseEnabled,
        weightKg: value,
      );
}
