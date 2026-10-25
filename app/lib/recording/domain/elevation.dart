/// Acumulador de ganho/perda de elevacao com limiar anti-ruido.
///
/// Clean room a partir de relatorios/04-metricas.md ("Elevacao"). O Strava usa
/// um calculador dedicado que recebe altitude (ja corrigida para o geoide, ver
/// etapa 03) e a precisao vertical de cada ponto. O algoritmo exato de suavizacao
/// nao foi observado; aqui aplicamos um limiar minimo de variacao para nao somar
/// micro-oscilacao do altimetro, e ignoramos pontos de precisao vertical ruim.
class ElevationStats {
  final double ascentMeters;
  final double descentMeters;
  final double? currentAltitudeMeters;

  const ElevationStats({
    this.ascentMeters = 0.0,
    this.descentMeters = 0.0,
    this.currentAltitudeMeters,
  });
}

class ElevationAccumulator {
  /// Variacao minima de altitude (m) para contar como subida/descida.
  final double minDeltaMeters;

  /// Descarta pontos cuja precisao vertical seja pior que este teto (m).
  final double maxVerticalAccuracyMeters;

  double _ascent = 0.0;
  double _descent = 0.0;
  double? _reference; // ultima altitude "confirmada"
  double? _current;

  ElevationAccumulator({
    this.minDeltaMeters = 1.0,
    this.maxVerticalAccuracyMeters = 20.0,
  });

  ElevationStats get stats => ElevationStats(
        ascentMeters: _ascent,
        descentMeters: _descent,
        currentAltitudeMeters: _current,
      );

  /// Processa uma altitude (MSL) com sua precisao vertical opcional.
  ElevationStats process(double altitudeMeters, {double? verticalAccuracyMeters}) {
    _current = altitudeMeters;

    if (verticalAccuracyMeters != null &&
        verticalAccuracyMeters > maxVerticalAccuracyMeters) {
      // Precisao vertical ruim: nao mexe no ganho/perda, so atualiza o atual.
      return stats;
    }

    final ref = _reference;
    if (ref == null) {
      _reference = altitudeMeters;
      return stats;
    }

    final delta = altitudeMeters - ref;
    if (delta.abs() < minDeltaMeters) {
      // Dentro do ruido: mantem a referencia, nao acumula.
      return stats;
    }

    if (delta > 0) {
      _ascent += delta;
    } else {
      _descent += -delta;
    }
    _reference = altitudeMeters;
    return stats;
  }
}
