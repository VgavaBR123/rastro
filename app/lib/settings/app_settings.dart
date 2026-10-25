// Configuracoes do app (imutavel), independentes da camada de banco.
library;

class AppSettings {
  final bool useMetric;
  final bool autoPauseEnabled;

  const AppSettings({this.useMetric = true, this.autoPauseEnabled = true});

  AppSettings copyWith({bool? useMetric, bool? autoPauseEnabled}) => AppSettings(
        useMetric: useMetric ?? this.useMetric,
        autoPauseEnabled: autoPauseEnabled ?? this.autoPauseEnabled,
      );
}
