// Motor da sessao guiada do plano 5 km (F06). Dart puro: recebe o tempo do
// plano (ms, ja descontadas as pausas) e devolve o que fazer: quantas voltas
// fechar e o que avisar. Quem chama fala, vibra e fecha as voltas.
//
// Regras:
// - Cada troca de bloco fecha uma volta da gravacao (os blocos ficam gravados
//   como voltas). O fim do desaquecimento tambem fecha a ultima.
// - Salto grande entre duas chamadas (app suspenso, tick atrasado): fecha UMA
//   volta so, com o trecho todo (a gravacao nao fecha volta no passado, entao
//   N voltas sairiam N-1 com 0 s), e conta os blocos pulados em
//   [GuidedStep.skippedBlocks]. Fala SO o bloco atual; avisos que ficaram para
//   tras (10 s, metade) sao descartados em silencio.
// - "Faltam 10 segundos" antes de cada troca (nao antes do fim do
//   desaquecimento, que nao tem proximo bloco), so em blocos com mais de 20 s.
// - Metade da sessao avisada uma vez.
library;

import 'plan_table.dart';

sealed class GuidedEvent {
  const GuidedEvent();
}

/// Comecou (ou, com [resumed], continuou depois de uma retomada) o bloco
/// [index]. Nao e emitido para o desaquecimento (ver [RunPhaseDone]).
class BlockStarted extends GuidedEvent {
  final int index;
  final PlanBlock block;

  /// Ultima corrida de uma sessao com mais de uma.
  final bool lastRun;

  /// Continuacao apos recuperar a gravacao.
  final bool resumed;

  /// Quanto falta do bloco.
  final int remainingMs;

  const BlockStarted({
    required this.index,
    required this.block,
    required this.lastRun,
    required this.remainingMs,
    this.resumed = false,
  });
}

/// Faltam 10 s para trocar para [next].
class TenSecondsLeft extends GuidedEvent {
  final PlanBlock next;
  const TenSecondsLeft(this.next);
}

class Halfway extends GuidedEvent {
  const Halfway();
}

/// Acabaram as corridas: comecou o desaquecimento.
class RunPhaseDone extends GuidedEvent {
  final int remainingMs;
  final bool resumed;
  const RunPhaseDone({required this.remainingMs, this.resumed = false});
}

/// Acabou o ultimo bloco.
class SessionCompleted extends GuidedEvent {
  const SessionCompleted();
}

class GuidedStep {
  /// 0 ou 1: voltas a fechar neste passo.
  final int lapsToClose;
  final List<GuidedEvent> events;

  /// Trocas de bloco alem da primeira neste passo (salto grande), que ficam
  /// dentro da mesma volta.
  final int skippedBlocks;
  const GuidedStep(this.lapsToClose, this.events, {this.skippedBlocks = 0});

  static const none = GuidedStep(0, []);

  bool get blockChanged => lapsToClose > 0;
}

/// Estado para a tela: bloco atual, quanto falta, o proximo e o progresso.
class GuidedView {
  final PlanSession session;
  final int index;
  final int elapsedMs;

  const GuidedView(this.session, this.index, this.elapsedMs);

  int get blockCount => session.blocks.length;
  bool get completed => index >= blockCount;
  PlanBlock? get block => completed ? null : session.blocks[index];
  PlanBlock? get next => index + 1 < blockCount ? session.blocks[index + 1] : null;

  int get remainingMs {
    if (completed) return 0;
    var end = 0;
    for (var i = 0; i <= index; i++) {
      end += session.blocks[i].durationMs;
    }
    final r = end - elapsedMs;
    return r < 0 ? 0 : r;
  }

  double get progress {
    final total = session.totalMs;
    if (total <= 0) return 1;
    final p = elapsedMs / total;
    return p > 1 ? 1 : p;
  }
}

const int kTenSecondsMs = 10000;

class GuidedSessionEngine {
  final PlanSession session;
  late final List<int> _ends;
  late final int _lastRunIndex;
  late final int _runCount;

  int _index = 0;
  int _t = 0;
  bool _halfwayDone = false;
  bool _warned = false;

  GuidedSessionEngine(this.session) {
    var acc = 0;
    _ends = [for (final b in session.blocks) acc += b.durationMs];
    _lastRunIndex = session.blocks.lastIndexWhere((b) => b.kind.isRun);
    _runCount = session.blocks.where((b) => b.kind.isRun).length;
  }

  bool get isCompleted => _index >= session.blocks.length;
  int get elapsedMs => _t;
  int get _halfMs => session.totalMs ~/ 2;

  GuidedView view() => GuidedView(session, _index, _t);

  int _indexAt(int t) {
    for (var i = 0; i < _ends.length; i++) {
      if (t < _ends[i]) return i;
    }
    return _ends.length;
  }

  int _remaining(int index, int t) => _ends[index] - t;

  /// Inicio da sessao (tempo 0).
  GuidedStep start() {
    _index = 0;
    _t = 0;
    _halfwayDone = false;
    _warned = false;
    return GuidedStep(0, [_enter(0, 0)]);
  }

  /// Continua de [planMs] (gravacao recuperada): nada do que ja passou e
  /// repetido, nenhuma volta e fechada; anuncia so o bloco atual.
  GuidedStep restore(int planMs) {
    _t = planMs < 0 ? 0 : planMs;
    _index = _indexAt(_t);
    _halfwayDone = _t >= _halfMs;
    _warned = !isCompleted && _remaining(_index, _t) <= kTenSecondsMs;
    if (isCompleted) return GuidedStep.none;
    return GuidedStep(0, [_enter(_index, _t, resumed: true)]);
  }

  GuidedEvent _enter(int index, int t, {bool resumed = false}) {
    final block = session.blocks[index];
    final remaining = _remaining(index, t);
    if (block.kind == BlockKind.cooldown) {
      return RunPhaseDone(remainingMs: remaining, resumed: resumed);
    }
    return BlockStarted(
      index: index,
      block: block,
      lastRun: index == _lastRunIndex && _runCount > 1,
      remainingMs: remaining,
      resumed: resumed,
    );
  }

  /// Avanca ate [planMs]. Tempo igual ou menor que o ultimo nao faz nada.
  GuidedStep advanceTo(int planMs) {
    if (planMs <= _t || isCompleted) {
      if (planMs > _t) _t = planMs;
      return GuidedStep.none;
    }
    final prevT = _t;
    _t = planMs;
    final newIndex = _indexAt(planMs);
    final crossed = newIndex - _index;
    final halfCrossed = !_halfwayDone && prevT < _halfMs && planMs >= _halfMs;
    if (halfCrossed) _halfwayDone = true;

    if (crossed > 0) {
      _index = newIndex;
      _warned = !isCompleted && _remaining(_index, planMs) <= kTenSecondsMs;
      final events = <GuidedEvent>[
        isCompleted ? const SessionCompleted() : _enter(newIndex, planMs),
        if (crossed == 1 && halfCrossed && !isCompleted) const Halfway(),
      ];
      return GuidedStep(1, events, skippedBlocks: crossed - 1);
    }

    final events = <GuidedEvent>[];
    final block = session.blocks[_index];
    final hasNext = _index + 1 < session.blocks.length;
    final warnAt = _ends[_index] - kTenSecondsMs;
    if (!_warned &&
        hasNext &&
        block.durationMs > 2 * kTenSecondsMs &&
        prevT < warnAt &&
        planMs >= warnAt) {
      _warned = true;
      events.add(TenSecondsLeft(session.blocks[_index + 1]));
    }
    if (halfCrossed) events.add(const Halfway());
    return GuidedStep(0, events);
  }
}
