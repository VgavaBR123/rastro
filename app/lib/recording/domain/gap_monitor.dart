/// Gravacao blindada (F01): deteccao de lacunas na gravacao.
///
/// Durante a gravacao (nao pausada) o controller manda um batimento a cada
/// ~5 s ([GapMonitor.onTick]) e avisa a chegada de cada ponto de GPS
/// ([GapMonitor.onPoint]). Mais de [kGapThresholdMs] sem batimento significa
/// que o processo ficou parado (encerrado ou congelado pelo sistema); mais de
/// [kGapThresholdMs] sem ponto, com o processo vivo, significa sem sinal de
/// GPS. Dart puro e deterministico: o tempo (ms de parede) vem de quem chama.
library;

/// Intervalo maximo sem batimento/ponto antes de virar lacuna.
const int kGapThresholdMs = 30000;

/// Intervalo alvo entre batimentos persistidos.
const Duration kHeartbeatInterval = Duration(seconds: 5);

/// Motivo provavel de uma lacuna. Persistido por indice: novos valores sempre
/// no fim.
enum GapReason {
  /// O app parou de rodar (encerrado ou congelado pelo sistema).
  processStopped,

  /// O app estava vivo, mas sem posicao do GPS.
  noGpsSignal,
}

/// Texto curto do motivo, para a UI.
String gapReasonLabel(GapReason r) => switch (r) {
  GapReason.processStopped => 'app encerrado ou parado pelo sistema',
  GapReason.noGpsSignal => 'sem sinal de GPS',
};

/// Trecho da gravacao sem dados (ms de parede).
class RecordingGap {
  final int startMs;
  final int endMs;
  final GapReason reason;

  const RecordingGap({
    required this.startMs,
    required this.endMs,
    required this.reason,
  });

  int get durationMs => endMs - startMs;

  @override
  bool operator ==(Object other) =>
      other is RecordingGap &&
      other.startMs == startMs &&
      other.endMs == endMs &&
      other.reason == reason;

  @override
  int get hashCode => Object.hash(startMs, endMs, reason);

  @override
  String toString() => 'RecordingGap($startMs..$endMs, $reason)';
}

class GapMonitor {
  final int thresholdMs;

  GapMonitor({this.thresholdMs = kGapThresholdMs});

  bool _started = false;
  bool _paused = false;
  int _lastBeatMs = 0;
  int _lastPointMs = 0;

  /// Comeca (ou recomeca, numa retomada) a vigiar a partir de [nowMs].
  void start(int nowMs) {
    _started = true;
    _paused = false;
    _lastBeatMs = nowMs;
    _lastPointMs = nowMs;
  }

  bool get _active => _started && !_paused;

  /// Liga ou desliga a pausa (manual ou automatica). Ao sair da pausa a
  /// contagem recomeca de [nowMs]: o tempo pausado nunca e lacuna.
  void setPaused(bool paused, int nowMs) {
    if (paused == _paused) return;
    _paused = paused;
    if (!paused) {
      _lastBeatMs = nowMs;
      _lastPointMs = nowMs;
    }
  }

  /// Batimento periodico. Devolve a lacuna de processo, se houve.
  RecordingGap? onTick(int nowMs) {
    if (!_active) return null;
    return _checkProcess(nowMs);
  }

  /// Chegada de um ponto. Devolve a lacuna (de processo ou de GPS), se houve.
  RecordingGap? onPoint(int nowMs) {
    if (!_active) return null;
    final process = _checkProcess(nowMs);
    if (process != null) {
      _lastPointMs = nowMs;
      return process;
    }
    RecordingGap? gps;
    if (nowMs - _lastPointMs > thresholdMs) {
      gps = RecordingGap(
        startMs: _lastPointMs,
        endMs: nowMs,
        reason: GapReason.noGpsSignal,
      );
    }
    _lastPointMs = nowMs;
    return gps;
  }

  /// Mais de [thresholdMs] sem ponto, gravando: o GPS esta mudo agora.
  bool gpsSilent(int nowMs) => _active && nowMs - _lastPointMs > thresholdMs;

  /// Fecha a lacuna de GPS ainda aberta em [nowMs] (encerrar ou pausar com o
  /// GPS mudo), para que o trecho sem dados nao suma do relatorio. Devolve
  /// null se nao ha lacuna aberta; depois de fechar, a contagem recomeca.
  RecordingGap? closeOpenGap(int nowMs) {
    if (!gpsSilent(nowMs)) return null;
    final gap = RecordingGap(
      startMs: _lastPointMs,
      endMs: nowMs,
      reason: GapReason.noGpsSignal,
    );
    _lastPointMs = nowMs;
    return gap;
  }

  RecordingGap? _checkProcess(int nowMs) {
    RecordingGap? gap;
    if (nowMs - _lastBeatMs > thresholdMs) {
      gap = RecordingGap(
        startMs: _lastBeatMs,
        endMs: nowMs,
        reason: GapReason.processStopped,
      );
      // A falta de pontos nesse trecho e culpa do processo, nao do GPS.
      if (_lastPointMs < nowMs) _lastPointMs = nowMs;
    }
    _lastBeatMs = nowMs;
    return gap;
  }
}

/// Lacuna entre o ultimo batimento salvo antes de o app morrer e a retomada
/// em [nowMs]. Sem lacuna se estava pausado, sem batimento conhecido, ou se a
/// volta foi em ate [thresholdMs].
RecordingGap? gapAfterRestart({
  required int? lastBeatMs,
  required bool paused,
  required int nowMs,
  int thresholdMs = kGapThresholdMs,
}) {
  if (lastBeatMs == null || paused) return null;
  if (nowMs - lastBeatMs <= thresholdMs) return null;
  return RecordingGap(
    startMs: lastBeatMs,
    endMs: nowMs,
    reason: GapReason.processStopped,
  );
}
