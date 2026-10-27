/// Pausa automatica por movimento (acelerometro), para corrida. Clean room a
/// partir de relatorios/03 (duas medias exponenciais, curta x longa, decisao
/// relativa por fator ~3). CONTRATO fixo; implementacao em andamento.
library;

import 'auto_pause.dart';
import 'location_sample.dart';

/// Amostra do acelerometro (m/s^2) com tempo monotonico (ms).
class AccelSample {
  final int monotonicMs;
  final double x;
  final double y;
  final double z;
  const AccelSample(this.monotonicMs, this.x, this.y, this.z);
}

/// Detector que decide parado/em movimento pelo acelerometro. Enquanto nao
/// recebe amostras do sensor (aparelho sem acelerometro, emulador), cai no
/// detector por velocidade [fallback].
class MotionAutoPauseDetector implements AutoPauseDetector {
  final AutoPauseDetector fallback;

  MotionAutoPauseDetector({required this.fallback});

  /// Alimenta o detector com uma amostra do acelerometro.
  void addAccel(AccelSample s) {}

  @override
  bool shouldBePaused(LocationSample sample) => fallback.shouldBePaused(sample);

  @override
  void reset() => fallback.reset();
}
