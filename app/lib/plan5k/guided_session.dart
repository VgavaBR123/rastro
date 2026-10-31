// Sessao guiada do plano 5 km (F06) durante a gravacao. Costura o motor de
// blocos (dominio puro) com a gravacao (voltas, notificacao), a voz (mesma
// fila do Narrador, prioridade alta), a vibracao e o banco.
//
// Tempo do plano: relogio proprio ([PlanClock]) observado a cada tick (1 s) e
// a cada estado da gravacao, com a regra de pausa da gravacao. NAO usa o
// timerMs da gravacao para andar, porque ele so avanca quando chega ponto de
// GPS (com a tela desligada ou GPS fraco o plano travaria).
//
// Retomada apos crash: o plano continua do maior entre o tempo de plano salvo
// (a cada troca de bloco e a cada 15 s) e o tempo em movimento recuperado da
// gravacao. O tempo com o app fora conta como pausa, como na gravacao.
library;

// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../narrator/domain/announcement.dart';
import '../narrator/narrator.dart';
import '../recording/domain/recording_models.dart';
import '../recording/presentation/recording_ui_state.dart';
import '../recording/source/heartbeat_ticker.dart';
import 'domain/guided_engine.dart';
import 'domain/plan_clock.dart';
import 'domain/plan_phrases.dart';
import 'domain/plan_progress.dart';
import 'domain/plan_table.dart';
import 'plan_repository.dart';

/// Vibracao das trocas. Sem pacote novo: HapticFeedback do Flutter.
abstract interface class PlanHaptics {
  Future<void> blockChange();
  Future<void> warning();
}

class SystemPlanHaptics implements PlanHaptics {
  const SystemPlanHaptics();

  @override
  Future<void> blockChange() => _safe(() async {
    await HapticFeedback.heavyImpact();
    await HapticFeedback.vibrate();
  });

  @override
  Future<void> warning() => _safe(HapticFeedback.mediumImpact);

  static Future<void> _safe(Future<void> Function() op) async {
    try {
      await op();
    } catch (_) {
      // Sem vibracao no aparelho (ou sem binding): segue sem.
    }
  }
}

/// Intervalo do tick do plano (contagem regressiva e trocas).
const Duration kPlanTickInterval = Duration(seconds: 1);

/// De quanto em quanto tempo de plano o progresso vai para o banco.
const int kPlanSaveEveryMs = 15000;

/// Chave das falas do plano na fila: uma troca nova substitui um aviso
/// pendente que ainda nao tocou.
const String kPlanAnnouncementKey = 'plan5k';

class GuidedUiState {
  final PlanSession session;
  final int round;
  final GuidedView view;

  /// Resultado quando a gravacao terminou; null durante a sessao.
  final SessionStatus? result;

  const GuidedUiState({
    required this.session,
    required this.round,
    required this.view,
    this.result,
  });

  bool get running => result == null;

  GuidedUiState copyWith({GuidedView? view, SessionStatus? result}) => GuidedUiState(
    session: session,
    round: round,
    view: view ?? this.view,
    result: result ?? this.result,
  );
}

class GuidedSessionController extends StateNotifier<GuidedUiState?> {
  final PlanRepository _repo;
  final Narrator _narrator;
  final bool Function() _voiceOn;
  final PlanHaptics _haptics;
  final int Function() _monoNow;
  final int Function() _wallNow;
  final HeartbeatTicker _ticker;
  final Future<Object?> Function() _closeLap;
  final void Function(String?) _setNotice;
  final String? Function() _activityGuid;
  final RecordingUiState Function() _recording;
  final List<PlanSession> Function() _table;

  GuidedSessionEngine? _engine;
  PlanClock? _clock;
  String? _guid;
  StreamSubscription<void>? _tick;
  Future<void> _chain = Future<void>.value();
  bool _discard = false;
  int _lastSavedMs = 0;
  Completer<SessionStatus?>? _done;

  GuidedSessionController({
    required PlanRepository repo,
    required Narrator narrator,
    required bool Function() voiceOn,
    required PlanHaptics haptics,
    required int Function() monotonicNow,
    required int Function() wallNow,
    required HeartbeatTicker ticker,
    required Future<Object?> Function() closeLap,
    required void Function(String?) setNotice,
    required String? Function() activityGuid,
    required RecordingUiState Function() recording,
    List<PlanSession> Function()? table,
  }) : _repo = repo,
       _narrator = narrator,
       _voiceOn = voiceOn,
       _haptics = haptics,
       _monoNow = monotonicNow,
       _wallNow = wallNow,
       _ticker = ticker,
       _closeLap = closeLap,
       _setNotice = setNotice,
       _activityGuid = activityGuid,
       _recording = recording,
       _table = table ?? (() => kPlan5k),
       super(null);

  /// Ha sessao guiada correndo (gravacao aberta).
  bool get isRunning => _engine != null && (state?.running ?? false);

  /// Completa com o resultado quando a gravacao da sessao termina (null se
  /// foi descartada ou nao havia sessao).
  Future<SessionStatus?> get whenFinished => _done?.future ?? Future.value(null);

  /// Comeca a sessao [session] na gravacao que acabou de iniciar.
  Future<void> begin(PlanSession session, {required int round}) async {
    final guid = _activityGuid();
    if (guid == null || !_recording().isActive) return;
    _setup(session, round, guid, PlanClock());
    _clock!.observe(_monoNow(), paused: _recording().isPaused);
    await _repo.beginSession(
      week: session.week,
      number: session.number,
      round: round,
      plannedMs: session.totalMs,
      guid: guid,
      nowMs: _wallNow(),
    );
    await _run(() => _apply(_engine!.start()));
    _listenTicks();
  }

  /// Gravacao [guid] recuperada apos um crash: se ela era uma sessao guiada
  /// em andamento, o plano continua do ponto salvo. Devolve se retomou.
  Future<bool> resume(String guid) async {
    final r = await _repo.sessionForGuid(guid);
    if (r == null || r.status != SessionStatus.inProgress) return false;
    final rec = _recording();
    if (!rec.isActive) return false;
    final session = _table()[(r.week - 1) * kSessionsPerWeek + (r.number - 1)];
    final startMs = r.movingMs > rec.timerMs ? r.movingMs : rec.timerMs;
    _setup(session, r.round, guid, PlanClock(startMs: startMs));
    _lastSavedMs = startMs;
    _clock!.observe(_monoNow(), paused: rec.isPaused);
    await _run(() => _apply(_engine!.restore(startMs), haptic: false));
    _listenTicks();
    return true;
  }

  void _setup(PlanSession session, int round, String guid, PlanClock clock) {
    _tick?.cancel();
    _engine = GuidedSessionEngine(session);
    _clock = clock;
    _guid = guid;
    _discard = false;
    _lastSavedMs = 0;
    _done = Completer<SessionStatus?>();
    state = GuidedUiState(session: session, round: round, view: _engine!.view());
  }

  void _listenTicks() {
    _tick = _ticker.ticks(kPlanTickInterval).listen((_) => _onTick());
  }

  /// A gravacao vai ser descartada: a sessao nao conta. Chamar antes do stop.
  void abandon() => _discard = true;

  /// Novo estado da gravacao (o provider liga isto ao controller).
  void onRecording(RecordingUiState s) {
    if (!isRunning) return;
    if (s.state == RecordingState.finished) {
      unawaited(_run(_finish));
      return;
    }
    final paused = s.isPaused;
    unawaited(_run(() => _advance(paused)));
  }

  void _onTick() {
    if (!isRunning) return;
    final paused = _recording().isPaused;
    unawaited(_run(() => _advance(paused)));
  }

  /// Serializa o trabalho: voltas e escritas em ordem, um passo por vez.
  Future<void> _run(Future<void> Function() op) {
    final next = _chain.then((_) async {
      try {
        await op();
      } catch (_) {
        // Falha de banco ou de volta nao derruba o plano.
      }
    });
    _chain = next;
    return next;
  }

  Future<void> _advance(bool paused) async {
    final engine = _engine;
    final clock = _clock;
    final guid = _guid;
    if (engine == null || clock == null || guid == null || !isRunning) return;
    final planMs = clock.observe(_monoNow(), paused: paused);
    await _apply(engine.advanceTo(planMs));
    if (planMs - _lastSavedMs >= kPlanSaveEveryMs) {
      _lastSavedMs = planMs;
      await _repo.saveProgress(guid, movingMs: planMs);
    }
  }

  Future<void> _apply(GuidedStep step, {bool haptic = true}) async {
    final engine = _engine;
    final guid = _guid;
    if (engine == null || guid == null) return;
    for (var i = 0; i < step.lapsToClose; i++) {
      await _closeLap();
    }
    final changed = step.blockChanged || step.events.any((e) => e is BlockStarted || e is RunPhaseDone);
    if (step.blockChanged && haptic) {
      unawaited(_haptics.blockChange());
    } else if (step.events.any((e) => e is TenSecondsLeft) && haptic) {
      unawaited(_haptics.warning());
    }
    if (changed) _setNotice(_noticeText(engine.view()));
    if (step.blockChanged) {
      _lastSavedMs = engine.elapsedMs;
      await _repo.saveProgress(guid, movingMs: engine.elapsedMs);
    }
    final texts = [for (final e in step.events) ?planPhrase(e)];
    if (texts.isNotEmpty && _voiceOn()) {
      _narrator.enqueue(
        Announcement(
          texts.join(' '),
          priority: AnnouncementPriority.high,
          key: kPlanAnnouncementKey,
          maxAgeMs: 20000,
        ),
      );
    }
    final s = state;
    if (s != null && mounted) state = s.copyWith(view: engine.view());
  }

  static String _noticeText(GuidedView v) {
    final b = v.block;
    if (b == null) return 'Plano de hoje concluido';
    return 'Plano: ${blockLabel(b.kind)} ${formatPlanDuration(b.durationMs)} '
        '(bloco ${v.index + 1} de ${v.blockCount})';
  }

  Future<void> _finish() async {
    await _tick?.cancel();
    _tick = null;
    final engine = _engine;
    final clock = _clock;
    final guid = _guid;
    final done = _done;
    if (engine == null || clock == null || guid == null) return;
    // O trecho desde o ultimo tick conta se a gravacao estava rodando.
    final planMs = clock.observe(_monoNow(), paused: true);
    _engine = null;
    SessionStatus? status;
    if (_discard) {
      await _repo.discardSession(guid);
      if (mounted) state = null;
    } else {
      status = statusFor(movingMs: planMs, plannedMs: engine.session.totalMs);
      await _repo.finishSession(guid, movingMs: planMs, status: status, nowMs: _wallNow());
      final s = state;
      if (s != null && mounted) {
        state = s.copyWith(view: GuidedView(engine.session, engine.view().index, planMs), result: status);
      }
    }
    if (done != null && !done.isCompleted) done.complete(status);
  }

  /// Fecha o cartao do plano (depois do fechamento da gravacao).
  void clear() {
    if (isRunning) return;
    state = null;
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }
}
