/// Deteccao de pausa automatica. Clean room a partir de relatorios/03
/// (a pausa automatica e separada por esporte: corrida por movimento, pedal por
/// velocidade de GPS). Aqui modelamos a interface e uma estrategia por velocidade;
/// a estrategia por acelerometro (corrida) depende de sensor e fica na borda.
library;

import 'location_sample.dart';
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

  SpeedAutoPauseDetector({
    this.pauseThresholdMps = 0.5,
    this.resumeThresholdMps = 1.0,
    this.minPausedMs = 3000,
  });

  @override
  bool shouldBePaused(LocationSample s) {
    final v = s.speedMetersPerSecond ?? 0.0;
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
      return SpeedAutoPauseDetector(pauseThresholdMps: 1.0, resumeThresholdMps: 2.0);
    case ActivityType.run:
    case ActivityType.walk:
      // Por ora, velocidade; a versao por acelerometro entra quando a borda
      // nativa expuser o sensor (ver etapa 03 e roadmap).
      return SpeedAutoPauseDetector(pauseThresholdMps: 0.4, resumeThresholdMps: 0.8);
  }
}
