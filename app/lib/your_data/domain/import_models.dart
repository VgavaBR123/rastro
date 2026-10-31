/// Seus dados (F07): modelos da importacao de arquivos de atividade (FIT, GPX
/// e TCX). Dart puro, sem Flutter: roda no isolate da importacao.
///
/// Os leitores ([parseGpx], [parseTcx], [parseFit]) devolvem um
/// [ParsedActivity] com o que o arquivo traz, sem calcular nada. As metricas
/// saem do nosso pipeline de gravacao (activity_builder.dart).
library;

/// Formato de origem de uma atividade importada. [dbValue] vai para a coluna
/// `import_source` das atividades.
enum ImportFormat {
  fit,
  gpx,
  tcx;

  String get dbValue => name;

  /// Rotulo curto para a UI ("GPX").
  String get label => name.toUpperCase();

  static ImportFormat? fromDb(String? value) {
    for (final f in values) {
      if (f.dbValue == value) return f;
    }
    return null;
  }
}

/// Arquivo mal formado, corrompido ou sem dados suficientes. [message] e um
/// motivo curto, mostrado no resumo da importacao.
class ImportFormatException implements Exception {
  final String message;
  const ImportFormatException(this.message);

  @override
  String toString() => 'ImportFormatException: $message';
}

/// Um ponto lido do arquivo. Tudo e opcional: GPX sem horario, FIT sem
/// posicao (esteira) e TCX sem altitude existem.
class ParsedPoint {
  /// Instante do ponto (epoch ms, UTC).
  final int? timeMs;
  final double? latitude;
  final double? longitude;
  final double? altitudeMeters;

  /// Velocidade informada pelo aparelho (m/s), quando houver.
  final double? speedMetersPerSecond;

  const ParsedPoint({
    this.timeMs,
    this.latitude,
    this.longitude,
    this.altitudeMeters,
    this.speedMetersPerSecond,
  });

  bool get hasPosition =>
      latitude != null &&
      longitude != null &&
      latitude!.isFinite &&
      longitude!.isFinite &&
      latitude!.abs() <= 90 &&
      longitude!.abs() <= 180;
}

/// Trecho com o cronometro parado no aparelho (FIT: eventos de timer).
class TimerPause {
  final int stopMs;
  final int startMs;
  const TimerPause(this.stopMs, this.startMs);
}

/// O que um arquivo de atividade traz.
class ParsedActivity {
  final ImportFormat format;

  /// Esporte como escrito no arquivo ("running", "Biking", "cycling"...).
  /// Null quando o arquivo nao diz.
  final String? sportName;

  /// Nome da atividade no arquivo, quando houver.
  final String? name;

  /// Inicio declarado no arquivo (epoch ms). Null: usa o primeiro ponto.
  final int? startMs;

  final List<ParsedPoint> points;

  /// Tempo em movimento informado pelo aparelho (so o FIT tem:
  /// session.total_timer_time).
  final int? timerMs;

  /// Tempo total informado pelo arquivo (FIT session ou soma das voltas do
  /// TCX). Usado para atividade sem GPS.
  final int? elapsedMs;

  /// Distancia total informada pelo arquivo. Usada para atividade sem GPS.
  final double? distanceMeters;

  /// Pausas do cronometro do aparelho (FIT). Vazio: o tempo em movimento sai
  /// do nosso criterio de movimento.
  final List<TimerPause> timerPauses;

  const ParsedActivity({
    required this.format,
    required this.points,
    this.sportName,
    this.name,
    this.startMs,
    this.timerMs,
    this.elapsedMs,
    this.distanceMeters,
    this.timerPauses = const [],
  });
}
