// Relogio do plano (F06). Dart puro: o instante monotonico vem de fora.
//
// Por que um relogio proprio: o tempo em movimento da gravacao
// (RecordingSession.stats.timerMs) so avanca quando chega ponto de GPS. Com a
// tela desligada ou o GPS fraco os pontos param e o plano travaria entre um e
// outro. Aqui o tempo anda pelo relogio monotonico de um tick periodico, com a
// MESMA regra de pausa da gravacao: o intervalo entre duas observacoes conta
// se a gravacao estava rodando (nem pausa manual, nem pausa automatica) no
// inicio dele.
library;

class PlanClock {
  int _elapsedMs;
  int? _lastNowMs;
  bool _paused = true;

  /// [startMs]: tempo de plano ja andado (retomada depois de um crash).
  PlanClock({int startMs = 0}) : _elapsedMs = startMs;

  int get elapsedMs => _elapsedMs;

  /// Observa o instante [nowMs] (monotonico) e o estado da gravacao a partir
  /// dele. Devolve o tempo de plano andado. Um instante que volta e ignorado
  /// (nunca desconta).
  int observe(int nowMs, {required bool paused}) {
    final last = _lastNowMs;
    if (last == null || nowMs > last) {
      if (last != null && !_paused) _elapsedMs += nowMs - last;
      _lastNowMs = nowMs;
    }
    _paused = paused;
    return _elapsedMs;
  }
}
