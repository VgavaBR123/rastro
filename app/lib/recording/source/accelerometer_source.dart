// Borda do acelerometro, usada pela pausa automatica da corrida (relatorio 03:
// deteccao por movimento com duas medias exponenciais). Interface fina para o
// controller; a implementacao real usa o plugin `sensors_plus`.
library;

import 'dart:async';

import 'package:sensors_plus/sensors_plus.dart';

import '../domain/motion_auto_pause.dart';
import 'monotonic_clock.dart';

/// Periodo de amostragem pedido ao sensor: 50 ms (~20 Hz). Suficiente para
/// separar passada de repouso sem gastar bateria como a taxa de jogo.
const Duration kAccelSamplingPeriod = Duration(milliseconds: 50);

abstract class AccelerometerSource {
  /// Amostras do acelerometro (m/s^2, com gravidade) carimbadas no relogio
  /// monotonico da gravacao. Cancelar a assinatura desliga o sensor.
  Stream<AccelSample> samples();
}

/// Fonte vazia (testes, plataformas sem sensor).
class NoAccelerometerSource implements AccelerometerSource {
  const NoAccelerometerSource();

  @override
  Stream<AccelSample> samples() => const Stream.empty();
}

class SensorsPlusAccelerometerSource implements AccelerometerSource {
  final MonotonicClock clock;

  SensorsPlusAccelerometerSource(this.clock);

  @override
  Stream<AccelSample> samples() {
    // O carimbo e o relogio monotonico na chegada, igual a fonte de GPS, para
    // as duas ficarem na mesma base. O timestamp do evento nao e usado porque
    // esta em outra base de tempo.
    return accelerometerEventStream(samplingPeriod: kAccelSamplingPeriod)
        .map((e) => AccelSample(clock.nowMs, e.x, e.y, e.z))
        // Aparelho sem acelerometro: o stream da erro; a pausa por movimento cai
        // no detector por velocidade, entao so encerramos o fluxo.
        .handleError((Object _) {});
  }
}
