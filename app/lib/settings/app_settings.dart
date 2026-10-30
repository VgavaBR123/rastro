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

  /// Modo Gentil (F04): esconde pace e velocidade. Padrao desligado.
  final bool gentleMode;

  /// Plano 5 km (F06): "Voz do plano", independente do Narrador. Padrao
  /// ligada.
  final bool plan5kVoice;

  const AppSettings({
    this.useMetric = true,
    this.autoPauseEnabled = true,
    this.weightKg,
    this.reliabilityChecklistSeen = false,
    this.hideOnServer = true,
    this.narrator = const NarratorSettings(),
    this.gentleMode = false,
    this.plan5kVoice = true,
  });

  AppSettings copyWith({
    bool? useMetric,
    bool? autoPauseEnabled,
    bool? reliabilityChecklistSeen,
    bool? hideOnServer,
    NarratorSettings? narrator,
    bool? gentleMode,
    bool? plan5kVoice,
  }) => AppSettings(
    useMetric: useMetric ?? this.useMetric,
    autoPauseEnabled: autoPauseEnabled ?? this.autoPauseEnabled,
    weightKg: weightKg,
    reliabilityChecklistSeen:
        reliabilityChecklistSeen ?? this.reliabilityChecklistSeen,
    hideOnServer: hideOnServer ?? this.hideOnServer,
    narrator: narrator ?? this.narrator,
    gentleMode: gentleMode ?? this.gentleMode,
    plan5kVoice: plan5kVoice ?? this.plan5kVoice,
  );

  /// Troca o peso (null apaga).
  AppSettings withWeightKg(double? value) => AppSettings(
    useMetric: useMetric,
    autoPauseEnabled: autoPauseEnabled,
    weightKg: value,
    reliabilityChecklistSeen: reliabilityChecklistSeen,
    hideOnServer: hideOnServer,
    narrator: narrator,
    gentleMode: gentleMode,
    plan5kVoice: plan5kVoice,
  );
}
