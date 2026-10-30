// Preferencias do Narrador por voz (F03). Valor imutavel, guardado como JSON
// numa coluna das configuracoes (facil de crescer sem nova migracao).
library;

import 'dart:convert';

/// "A cada N km/mi" oferecidos na tela.
const List<int> kNarratorDistanceEveryOptions = [1, 2, 5, 10];

/// "A cada N minutos" oferecidos na tela; 0 = desligado.
const List<int> kNarratorTimeEveryOptions = [0, 5, 10, 15, 30];

class NarratorSettings {
  /// Narrador ligado. Padrao desligado: voz inesperada em publico incomoda.
  final bool enabled;

  /// Gatilho por distancia (km ou milha, pela unidade das Configuracoes).
  final bool distanceTrigger;

  /// Fala a cada N unidades (1, 2, 5 ou 10).
  final int distanceEvery;

  /// Fala a cada N minutos de cronometro; 0 = desligado.
  final int timeEveryMinutes;

  /// Fala ao fechar cada volta.
  final bool lapTrigger;

  /// Inicio, pausa automatica/manual, retomada e fim.
  final bool statusAnnouncements;

  // Conteudo.
  final bool sayTime;
  final bool sayDistance;

  /// Pace medio (corrida/caminhada) ou velocidade media (pedal).
  final bool sayAvgPace;

  /// Pace (ou velocidade) do ultimo split/volta.
  final bool saySplitPace;

  /// Frases calculadas no aparelho ("seu quilometro mais rapido ate agora").
  final bool contextPhrases;

  /// Frases curtas: so a marca e a metrica principal.
  final bool essentialOnly;

  const NarratorSettings({
    this.enabled = false,
    this.distanceTrigger = true,
    this.distanceEvery = 1,
    this.timeEveryMinutes = 0,
    this.lapTrigger = true,
    this.statusAnnouncements = true,
    this.sayTime = true,
    this.sayDistance = true,
    this.sayAvgPace = true,
    this.saySplitPace = true,
    this.contextPhrases = true,
    this.essentialOnly = false,
  });

  NarratorSettings copyWith({
    bool? enabled,
    bool? distanceTrigger,
    int? distanceEvery,
    int? timeEveryMinutes,
    bool? lapTrigger,
    bool? statusAnnouncements,
    bool? sayTime,
    bool? sayDistance,
    bool? sayAvgPace,
    bool? saySplitPace,
    bool? contextPhrases,
    bool? essentialOnly,
  }) => NarratorSettings(
    enabled: enabled ?? this.enabled,
    distanceTrigger: distanceTrigger ?? this.distanceTrigger,
    distanceEvery: distanceEvery ?? this.distanceEvery,
    timeEveryMinutes: timeEveryMinutes ?? this.timeEveryMinutes,
    lapTrigger: lapTrigger ?? this.lapTrigger,
    statusAnnouncements: statusAnnouncements ?? this.statusAnnouncements,
    sayTime: sayTime ?? this.sayTime,
    sayDistance: sayDistance ?? this.sayDistance,
    sayAvgPace: sayAvgPace ?? this.sayAvgPace,
    saySplitPace: saySplitPace ?? this.saySplitPace,
    contextPhrases: contextPhrases ?? this.contextPhrases,
    essentialOnly: essentialOnly ?? this.essentialOnly,
  );

  Map<String, Object> toJson() => {
    'enabled': enabled,
    'distanceTrigger': distanceTrigger,
    'distanceEvery': distanceEvery,
    'timeEveryMinutes': timeEveryMinutes,
    'lapTrigger': lapTrigger,
    'statusAnnouncements': statusAnnouncements,
    'sayTime': sayTime,
    'sayDistance': sayDistance,
    'sayAvgPace': sayAvgPace,
    'saySplitPace': saySplitPace,
    'contextPhrases': contextPhrases,
    'essentialOnly': essentialOnly,
  };

  String toJsonString() => jsonEncode(toJson());

  /// Le o JSON salvo. Nulo, invalido, campo faltando ou fora das opcoes cai
  /// no padrao daquele campo (nunca quebra a abertura das configuracoes).
  factory NarratorSettings.fromJsonString(String? raw) {
    const d = NarratorSettings();
    if (raw == null) return d;
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return d;
    }
    if (decoded is! Map) return d;
    bool b(String k, bool def) {
      final v = decoded is Map ? decoded[k] : null;
      return v is bool ? v : def;
    }

    int pick(String k, List<int> options, int def) {
      final v = decoded is Map ? decoded[k] : null;
      return v is int && options.contains(v) ? v : def;
    }

    return NarratorSettings(
      enabled: b('enabled', d.enabled),
      distanceTrigger: b('distanceTrigger', d.distanceTrigger),
      distanceEvery: pick('distanceEvery', kNarratorDistanceEveryOptions, d.distanceEvery),
      timeEveryMinutes: pick('timeEveryMinutes', kNarratorTimeEveryOptions, d.timeEveryMinutes),
      lapTrigger: b('lapTrigger', d.lapTrigger),
      statusAnnouncements: b('statusAnnouncements', d.statusAnnouncements),
      sayTime: b('sayTime', d.sayTime),
      sayDistance: b('sayDistance', d.sayDistance),
      sayAvgPace: b('sayAvgPace', d.sayAvgPace),
      saySplitPace: b('saySplitPace', d.saySplitPace),
      contextPhrases: b('contextPhrases', d.contextPhrases),
      essentialOnly: b('essentialOnly', d.essentialOnly),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NarratorSettings &&
      other.enabled == enabled &&
      other.distanceTrigger == distanceTrigger &&
      other.distanceEvery == distanceEvery &&
      other.timeEveryMinutes == timeEveryMinutes &&
      other.lapTrigger == lapTrigger &&
      other.statusAnnouncements == statusAnnouncements &&
      other.sayTime == sayTime &&
      other.sayDistance == sayDistance &&
      other.sayAvgPace == sayAvgPace &&
      other.saySplitPace == saySplitPace &&
      other.contextPhrases == contextPhrases &&
      other.essentialOnly == essentialOnly;

  @override
  int get hashCode => Object.hash(
    enabled,
    distanceTrigger,
    distanceEvery,
    timeEveryMinutes,
    lapTrigger,
    statusAnnouncements,
    sayTime,
    sayDistance,
    sayAvgPace,
    saySplitPace,
    contextPhrases,
    essentialOnly,
  );

  @override
  String toString() => 'NarratorSettings(${toJsonString()})';
}
