/// Deteccao de pausa automatica. Clean room a partir de relatorios/03
/// (a pausa automatica e separada por esporte: corrida por movimento, pedal por
/// velocidade de GPS). Aqui ficam a interface e a estrategia por velocidade; a
/// estrategia por acelerometro (corrida) esta em motion_auto_pause.dart e
/// recebe as amostras do sensor pela borda nativa.
library;

import 'geo.dart';
import 'location_sample.dart';
import 'motion_auto_pause.dart';
import 'recording_models.dart';

abstract class AutoPauseDetector {
  /// Atualiza com a amostra mais recente e devolve true se deve estar pausado.
  bool shouldBePaused(LocationSample sample);
  void reset();
}

/// Pausa automatica por velocidade de GPS (adequada a pedal).
/// Pausa quando a velocidade fica abaixo de [resumeThresholdMps] por um tempo,
/// e retoma quando sobe acima de [resumeThresholdMps]. Usa histerese simples.
class SpeedAutoPauseDetector implements AutoPauseDetector {
  final double pauseThresholdMps;
  final double resumeThresholdMps;
  final int minPausedMs;

  bool _paused = false;
  int? _belowSinceMs;

  /// Ultima posicao vista, para derivar velocidade quando o provedor nao a
  /// informa.
  GeoPoint? _lastPosition;
  int? _lastMonotonicMs;

  SpeedAutoPauseDetector({
    this.pauseThresholdMps = 0.5,
    this.resumeThresholdMps = 1.0,
    this.minPausedMs = 3000,
  });

  /// Velocidade a usar na decisao, ou null quando nao da para saber.
  ///
  /// O provedor nem sempre informa velocidade (ver location_sample.dart: o
  /// modelo distingue "nao informou" de "informou zero"). Tratar ausencia como
  /// zero pausaria a gravacao com o usuario em movimento, entao derivamos a
  /// velocidade do deslocamento desde a amostra anterior; sem amostra anterior,
  /// a resposta e "desconhecida".
  double? _effectiveSpeed(LocationSample s) {
    final double? reported = s.speedMetersPerSecond;
    if (reported != null) return reported;

    final GeoPoint? lastPos = _lastPosition;
    final int? lastMs = _lastMonotonicMs;
    if (lastPos == null || lastMs == null) return null;

    final double dt = (s.monotonicMs - lastMs) / 1000.0;
    if (dt <= 0) return null;
    return haversineMeters(lastPos, s.position) / dt;
  }

  @override
  bool shouldBePaused(LocationSample s) {
    final double? speed = _effectiveSpeed(s);
    _lastPosition = s.position;
    _lastMonotonicMs = s.monotonicMs;

    // Sem informacao de velocidade nao mudamos de estado: na duvida, continua
    // como esta (e nunca pausa quem pode estar se movendo).
    if (speed == null) return _paused;

    final double v = speed;
    if (!_paused) {
      if (v < pauseThresholdMps) {
        _belowSinceMs ??= s.monotonicMs;
        if (s.monotonicMs - _belowSinceMs! >= minPausedMs) {
          _paused = true;
        }
      } else {
        _belowSinceMs = null;
      }
    } else {
      if (v >= resumeThresholdMps) {
        _paused = false;
        _belowSinceMs = null;
      }
    }
    return _paused;
  }

  @override
  void reset() {
    _paused = false;
    _belowSinceMs = null;
  }
}

/// Fabrica a estrategia conforme o esporte (etapa 03).
AutoPauseDetector autoPauseFor(ActivityType type) {
  switch (type) {
    case ActivityType.ride:
      return SpeedAutoPauseDetector(
        pauseThresholdMps: 1.0,
        resumeThresholdMps: 2.0,
      );
    case ActivityType.run:
      // Corrida: acelerometro. Sem sensor (ou enquanto ele nao chega), o
      // mesmo detector por velocidade que a corrida usava antes.
      return MotionAutoPauseDetector(
        fallback: SpeedAutoPauseDetector(
          pauseThresholdMps: 0.4,
          resumeThresholdMps: 0.8,
        ),
      );
    case ActivityType.walk:
      return SpeedAutoPauseDetector(
        pauseThresholdMps: 0.4,
        resumeThresholdMps: 0.8,
      );
  }
}
