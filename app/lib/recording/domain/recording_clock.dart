/// Relogio da gravacao: separa tempo total (decorrido) de tempo de cronometro
/// (movimento, que exclui pausas). Clean room a partir de relatorios/03 e 04
/// (distincao elapsedTime x timerTime).
///
/// O relogio recebe timestamps monotonicos (ms) de fora, para ser deterministico
/// e testavel (nao le o relogio do sistema sozinho).
class RecordingClock {
  int? _startMonotonicMs;
  int _accumulatedPauseMs = 0;
  int? _pauseStartedMonotonicMs;
  int _lastMonotonicMs = 0;

  bool get isRunning => _startMonotonicMs != null;
  bool get isPaused => _pauseStartedMonotonicMs != null;

  void start(int monotonicMs) {
    _startMonotonicMs = monotonicMs;
    _lastMonotonicMs = monotonicMs;
    _accumulatedPauseMs = 0;
    _pauseStartedMonotonicMs = null;
  }

  void pause(int monotonicMs) {
    if (!isRunning || isPaused) return;
    _pauseStartedMonotonicMs = monotonicMs;
    _lastMonotonicMs = monotonicMs;
  }

  void resume(int monotonicMs) {
    if (!isRunning || !isPaused) return;
    _accumulatedPauseMs += monotonicMs - _pauseStartedMonotonicMs!;
    _pauseStartedMonotonicMs = null;
    _lastMonotonicMs = monotonicMs;
  }

  /// Avanca o relogio para o instante atual (chamado a cada amostra/tick).
  void tick(int monotonicMs) {
    _lastMonotonicMs = monotonicMs;
  }

  /// Tempo total desde o inicio, em ms (inclui pausas).
  int get elapsedMs {
    if (_startMonotonicMs == null) return 0;
    return _lastMonotonicMs - _startMonotonicMs!;
  }

  /// Tempo de cronometro, em ms (exclui o tempo pausado).
  int get timerMs {
    if (_startMonotonicMs == null) return 0;
    final pauseSoFar = _accumulatedPauseMs +
        (isPaused ? (_lastMonotonicMs - _pauseStartedMonotonicMs!) : 0);
    return (_lastMonotonicMs - _startMonotonicMs!) - pauseSoFar;
  }
}
