// Configuracoes do app (imutavel), independentes da camada de banco.
library;

import '../narrator/domain/narrator_settings.dart';

class AppSettings {
  final bool useMetric;
  final bool autoPauseEnabled;

  /// Peso em kg para estimar calorias; null = nao informado.
  final double? weightKg;

  /// Checklist "Gravacao confiavel" ja mostrado antes da primeira gravacao.
  final bool reliabilityChecklistSeen;

  /// Privacidade (F02): o upload sai sem as pontas ocultas. Padrao ligado.
  final bool hideOnServer;

  /// Narrador por voz (F03).
  final NarratorSettings narrator;

  const AppSettings({
    this.useMetric = true,
    this.autoPauseEnabled = true,
    this.weightKg,
    this.reliabilityChecklistSeen = false,
    this.hideOnServer = true,
    this.narrator = const NarratorSettings(),
  });

  AppSettings copyWith({
    bool? useMetric,
    bool? autoPauseEnabled,
    bool? reliabilityChecklistSeen,
    bool? hideOnServer,
    NarratorSettings? narrator,
  }) => AppSettings(
    useMetric: useMetric ?? this.useMetric,
    autoPauseEnabled: autoPauseEnabled ?? this.autoPauseEnabled,
    weightKg: weightKg,
    reliabilityChecklistSeen:
        reliabilityChecklistSeen ?? this.reliabilityChecklistSeen,
    hideOnServer: hideOnServer ?? this.hideOnServer,
    narrator: narrator ?? this.narrator,
  );

  /// Troca o peso (null apaga).
  AppSettings withWeightKg(double? value) => AppSettings(
    useMetric: useMetric,
    autoPauseEnabled: autoPauseEnabled,
    weightKg: value,
    reliabilityChecklistSeen: reliabilityChecklistSeen,
    hideOnServer: hideOnServer,
    narrator: narrator,
  );
}
