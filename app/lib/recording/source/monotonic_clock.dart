// Relogio monotonico compartilhado pelas bordas de sensores (GPS e
// acelerometro). As duas fontes carimbam as amostras na chegada com o MESMO
// relogio, para o dominio comparar tempos de GPS e de acelerometro na mesma
// base (relatorio 03: deltas de tempo sempre monotonicos).
library;

class MonotonicClock {
  final Stopwatch _stopwatch = Stopwatch();

  /// Milissegundos desde o ultimo [restart] (0 se nunca iniciado).
  int get nowMs => _stopwatch.elapsedMilliseconds;

  /// Zera e inicia a contagem. A fonte de GPS chama ao abrir o stream: a base
  /// monotonica da sessao comeca em 0 no inicio (ou na retomada) da gravacao.
  void restart() {
    _stopwatch
      ..reset()
      ..start();
  }
}
