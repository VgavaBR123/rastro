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
  int _ignoredSteps = 0;

  /// [startMs]: tempo de plano ja andado (retomada depois de um crash).
  PlanClock({int startMs = 0}) : _elapsedMs = startMs;

  int get elapsedMs => _elapsedMs;

  /// Saltos descartados pelo limite de sanidade (relogio de parede).
  int get ignoredSteps => _ignoredSteps;

  /// Observa o instante [nowMs] e o estado da gravacao a partir dele.
  /// Devolve o tempo de plano andado.
  ///
  /// Sem [maxStepMs] (relogio monotonico): um instante que volta e ignorado.
  /// Com [maxStepMs] (relogio de parede, que pode ser ajustado): um passo
  /// negativo ou maior que o limite nao conta, e contado em [ignoredSteps],
  /// e a contagem segue a partir do novo instante.
  int observe(int nowMs, {required bool paused, int? maxStepMs}) {
    final last = _lastNowMs;
    if (last == null) {
      _lastNowMs = nowMs;
    } else {
      final step = nowMs - last;
      final insane = maxStepMs != null && (step < 0 || step > maxStepMs);
      if (insane) {
        _ignoredSteps++;
        _lastNowMs = nowMs;
      } else if (step > 0) {
        if (!_paused) _elapsedMs += step;
        _lastNowMs = nowMs;
      }
    }
    _paused = paused;
    return _elapsedMs;
  }
}
