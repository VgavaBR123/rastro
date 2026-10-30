// Borda do relogio periodico do heartbeat da gravacao (F01). Fica atras de
// interface para os testes dispararem os batimentos na mao (deterministico) e
// para os testes de widget nao deixarem Timer pendente.
library;

import 'dart:async';

abstract class HeartbeatTicker {
  /// Um evento a cada [interval] enquanto houver assinante.
  Stream<void> ticks(Duration interval);
}

/// Timer de verdade (Stream.periodic).
class PeriodicHeartbeatTicker implements HeartbeatTicker {
  const PeriodicHeartbeatTicker();

  @override
  Stream<void> ticks(Duration interval) => Stream<void>.periodic(interval);
}

/// Sem batimentos (testes de widget que nao sobrescrevem o provider).
class NoHeartbeatTicker implements HeartbeatTicker {
  const NoHeartbeatTicker();

  @override
  Stream<void> ticks(Duration interval) => const Stream.empty();
}
