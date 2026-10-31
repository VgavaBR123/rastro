// Sessao do Rastro Seguro (F08) durante a gravacao. Cria a sessao no Iniciar,
// manda a ultima posicao conhecida a cada [interval] por um tick proprio (nao
// depende de chegar ponto de GPS: sem ponto novo vai um batimento com
// lat/lon null), le a checagem "esta tudo bem?" das respostas e encerra a
// sessao (arrived) quando a gravacao termina, salva ou descartada.
//
// Sem rede: guarda so a ultima posicao (a que nao saiu) e manda no proximo
// tick. O "arrived" que falhar por rede e repetido a cada tick, porque um
// fim que nao chega ao backend vira checagem e alerta falso.
//
// Recuperacao apos crash: [reconcile] le a sessao ativa do backend e religa a
// faixa se ela for da gravacao em andamento; se for de uma atividade que ja
// terminou (e nao esta esperando a decisao de retomar), encerra.
library;

// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../narrator/domain/announcement.dart';
import '../narrator/narrator.dart';
import '../recording/domain/location_sample.dart';
import '../recording/domain/recording_models.dart';
import '../recording/presentation/recording_ui_state.dart';
import '../recording/source/heartbeat_ticker.dart';
import 'safety_api.dart';
import 'safety_models.dart';

/// Intervalo padrao das posicoes (contrato: a cada 60 s).
const Duration kSafetyPositionInterval = Duration(seconds: 60);

/// Limites do horario previsto (contrato: agora + 5 min ate agora + 12 h).
const int kSafetyMinEtaMs = 5 * 60000;
const int kSafetyMaxEtaMs = 12 * 3600000;

/// Chave das falas do Rastro Seguro na fila do Narrador.
const String kSafetyAnnouncementKey = 'safety';

const String kSafetyCheckPhrase = 'Esta tudo bem? Toque em Estou bem.';

/// Vibracao da checagem. Sem pacote novo: HapticFeedback do Flutter.
abstract interface class SafetyHaptics {
  Future<void> alert();
}

class SystemSafetyHaptics implements SafetyHaptics {
  const SystemSafetyHaptics();

  @override
  Future<void> alert() async {
    try {
      await HapticFeedback.heavyImpact();
      await HapticFeedback.vibrate();
      await Future<void>.delayed(const Duration(milliseconds: 250));
      await HapticFeedback.vibrate();
    } catch (_) {
      // Sem vibracao no aparelho: segue sem.
    }
  }
}

/// Escolha feita na tela Gravar antes de iniciar: contatos e chegada.
class SafetyPlan {
  final List<TrustedContact> contacts;

  /// Atalho (30, 45, 60, 90 min) contado a partir do Iniciar.
  final int? minutes;

  /// Horario escolhido no seletor (epoch ms).
  final int? etaAtMs;

  const SafetyPlan({required this.contacts, this.minutes, this.etaAtMs})
    : assert((minutes == null) != (etaAtMs == null));

  List<String> get contactIds => [for (final c in contacts) c.id];

  int etaFor(int startMs) => etaAtMs ?? startMs + minutes! * 60000;
}

/// Horario valido para o contrato, a partir de [nowMs].
bool safetyEtaValid(int etaMs, int nowMs) =>
    etaMs >= nowMs + kSafetyMinEtaMs && etaMs <= nowMs + kSafetyMaxEtaMs;

enum SafetyBeginResult {
  started,

  /// Sem login (ou sessao expirada).
  signedOut,

  /// Sem rede ou servidor fora.
  offline,

  /// Horario fora de 5 min a 12 h (o tempo passou na tela Gravar).
  invalidEta,

  /// O backend recusou (contato nao aceito, por exemplo).
  rejected,
}

class SafetyUiState {
  final SafetySession? session;

  /// Ultimo envio falhou por falta de rede (a posicao sai no proximo tick).
  final bool offline;

  /// Acao da faixa ou do aviso em andamento.
  final bool busy;

  /// Aviso curto para a tela (ex.: estender falhou sem rede).
  final String? message;

  /// Ultimo envio aceito pelo backend (epoch ms).
  final int? lastSentAt;

  const SafetyUiState({this.session, this.offline = false, this.busy = false, this.message, this.lastSentAt});

  bool get active => session != null && !session!.ended;
  SafetyCheck? get check => active ? session!.check : null;
  bool get alerted => active && session!.status == SafetyStatus.alerted;

  SafetyUiState copyWith({
    SafetySession? session,
    bool clearSession = false,
    bool? offline,
    bool? busy,
    String? message,
    bool clearMessage = false,
    int? lastSentAt,
  }) => SafetyUiState(
    session: clearSession ? null : session ?? this.session,
    offline: offline ?? this.offline,
    busy: busy ?? this.busy,
    message: clearMessage ? null : message ?? this.message,
    lastSentAt: lastSentAt ?? this.lastSentAt,
  );
}

class SafetySessionController extends StateNotifier<SafetyUiState> {
  final SafetyApi _api;
  final HeartbeatTicker _ticker;
  final Duration _interval;
  final int Function() _now;
  final LocationSample? Function() _lastSample;
  final RecordingUiState Function() _recording;
  final String? Function() _recordingGuid;
  final Narrator _narrator;
  final SafetyHaptics _haptics;

  StreamSubscription<void>? _tick;
  Future<void> _chain = Future<void>.value();

  /// Instante (wallClockMs) da ultima amostra aceita pelo backend.
  int? _sentSampleAt;

  /// Checagem ja anunciada (startedAt), para nao falar de novo a cada tick.
  int? _announcedCheck;
  bool _announcedAlert = false;

  /// Sessao encerrada aqui cujo "arrived" ainda nao chegou ao backend.
  String? _pendingArrival;

  SafetySessionController({
    required SafetyApi api,
    required HeartbeatTicker ticker,
    Duration interval = kSafetyPositionInterval,
    required int Function() now,
    required LocationSample? Function() lastSample,
    required RecordingUiState Function() recording,
    required String? Function() recordingGuid,
    required Narrator narrator,
    SafetyHaptics haptics = const SystemSafetyHaptics(),
  }) : _api = api,
       _ticker = ticker,
       _interval = interval,
       _now = now,
       _lastSample = lastSample,
       _recording = recording,
       _recordingGuid = recordingGuid,
       _narrator = narrator,
       _haptics = haptics,
       super(const SafetyUiState());

  String? get sessionId => state.active ? state.session!.id : null;

  /// Cria a sessao para a gravacao [guid] que acabou de iniciar. Nunca
  /// lanca: o resultado diz por que nao ligou (a gravacao segue sem).
  Future<SafetyBeginResult> begin({required String guid, required SafetyPlan plan, required int startMs}) async {
    final etaMs = plan.etaFor(startMs);
    if (!safetyEtaValid(etaMs, _now())) return SafetyBeginResult.invalidEta;
    try {
      SafetySession s;
      try {
        s = await _create(guid, etaMs, plan.contactIds);
      } on SafetyException catch (e) {
        if (e.kind != SafetyErrorKind.conflict) rethrow;
        // Sessao antiga presa no backend (app morto sem arrived): encerra e
        // tenta de novo uma vez.
        final old = await _api.activeSession();
        if (old != null) await _api.arrived(old.id);
        s = await _create(guid, etaMs, plan.contactIds);
      }
      _attach(s);
      unawaited(_run(_report));
      return SafetyBeginResult.started;
    } on SafetyException catch (e) {
      debugPrint('Rastro Seguro nao ligou: $e');
      return switch (e.kind) {
        SafetyErrorKind.network => SafetyBeginResult.offline,
        SafetyErrorKind.unauthorized => SafetyBeginResult.signedOut,
        _ => SafetyBeginResult.rejected,
      };
    }
  }

  Future<SafetySession> _create(String guid, int etaMs, List<String> ids) =>
      _api.createSession(activityGuid: guid, etaMs: etaMs, contactIds: ids);

  void _attach(SafetySession s) {
    _sentSampleAt = null;
    _announcedCheck = null;
    _announcedAlert = false;
    _pendingArrival = null;
    state = SafetyUiState(session: s);
    _apply(s);
    _listenTicks();
  }

  void _listenTicks() {
    _tick?.cancel();
    _tick = _ticker.ticks(_interval).listen((_) => unawaited(_run(_onTick)));
  }

  /// Serializa os envios: uma requisicao por vez, na ordem.
  Future<void> _run(Future<void> Function() op) {
    final next = _chain.then((_) async {
      try {
        await op();
      } catch (e) {
        debugPrint('Rastro Seguro: passo falhou: $e');
      }
    });
    _chain = next;
    return next;
  }

  Future<void> _onTick() async {
    if (_pendingArrival != null) {
      await _sendArrival();
      return;
    }
    await _report();
  }

  PositionReport _currentReport({bool forcePosition = false}) {
    final rec = _recording();
    final paused = rec.state == RecordingState.manuallyPaused;
    final moving = rec.state == RecordingState.recording;
    final sample = _lastSample();
    final at = _now();
    if (sample != null && (forcePosition || sample.wallClockMs != _sentSampleAt)) {
      return PositionReport(
        lat: sample.position.latitude,
        lon: sample.position.longitude,
        accuracyM: sample.horizontalAccuracyMeters,
        recordedAtMs: sample.wallClockMs,
        moving: moving,
        paused: paused,
      );
    }
    return PositionReport.heartbeat(recordedAtMs: at, moving: moving, paused: paused);
  }

  /// Manda a ultima posicao (ou o batimento). Falha de rede: a amostra nao
  /// conta como enviada e sai no proximo tick.
  Future<void> _report({bool forcePosition = false}) async {
    final id = sessionId;
    if (id == null) return;
    final report = _currentReport(forcePosition: forcePosition);
    final sampleAt = report.hasPosition ? report.recordedAtMs : null;
    try {
      final s = await _api.postPosition(id, report);
      if (sampleAt != null) _sentSampleAt = sampleAt;
      if (!mounted) return;
      state = state.copyWith(session: s, offline: false, lastSentAt: _now());
      _apply(s);
    } on SafetyException catch (e) {
      _onError(e);
    }
  }

  void _onError(SafetyException e) {
    if (!mounted) return;
    if (e.kind == SafetyErrorKind.network) {
      state = state.copyWith(offline: true);
    } else if (e.kind == SafetyErrorKind.notFound) {
      // A sessao sumiu no backend (encerrou sozinha em eta + 6 h).
      _stopTicks();
      state = const SafetyUiState();
    }
  }

  /// Le a checagem nova: voz critica (mesmo com o Narrador desligado) e
  /// vibracao, uma vez por checagem. O alerta enviado tambem vibra.
  void _apply(SafetySession s) {
    if (s.ended) {
      _stopTicks();
      if (mounted) state = const SafetyUiState();
      return;
    }
    final check = s.check;
    if (check != null && _announcedCheck != check.startedAt) {
      _announcedCheck = check.startedAt;
      _narrator.enqueue(
        const Announcement(
          kSafetyCheckPhrase,
          priority: AnnouncementPriority.critical,
          key: kSafetyAnnouncementKey,
          maxAgeMs: 60000,
        ),
      );
      unawaited(_haptics.alert());
    }
    if (s.status == SafetyStatus.alerted && !_announcedAlert) {
      _announcedAlert = true;
      _narrator.enqueue(
        const Announcement(
          'Seus contatos foram avisados. Se estiver tudo bem, toque em Estou bem.',
          priority: AnnouncementPriority.critical,
          key: kSafetyAnnouncementKey,
          maxAgeMs: 60000,
        ),
      );
      unawaited(_haptics.alert());
    } else if (s.status != SafetyStatus.alerted) {
      _announcedAlert = false;
    }
  }

  /// "Estou bem": zera a checagem (e, depois de alertado, avisa os contatos).
  Future<bool> ok() => _action((id) => _api.ok(id), 'Sem rede: nao deu para avisar que esta tudo bem. Tente de novo.');

  /// Estende o horario previsto em [minutes] (tambem zera a checagem).
  Future<bool> extend(int minutes) =>
      _action((id) => _api.extend(id, minutes), 'Sem rede: o horario nao foi estendido. Tente de novo.');

  /// "Mandar minha posicao agora": manda a posicao atual e o SOS aos
  /// contatos. Nao encerra a sessao.
  Future<bool> sos() => _action((id) async {
    await _api.postPosition(id, _currentReport(forcePosition: true));
    return _api.sos(id);
  }, 'Sem rede: a posicao nao foi enviada. Tente de novo.', done: 'Posicao enviada aos seus contatos.');

  Future<bool> _action(
    Future<SafetySession> Function(String id) call,
    String offlineMessage, {
    String? done,
  }) async {
    final id = sessionId;
    if (id == null || state.busy) return false;
    state = state.copyWith(busy: true, clearMessage: true);
    var ok = false;
    await _run(() async {
      try {
        final s = await call(id);
        ok = true;
        if (!mounted) return;
        state = state.copyWith(session: s, busy: false, offline: false, message: done);
        _apply(s);
      } on SafetyException catch (e) {
        if (!mounted) return;
        state = state.copyWith(
          busy: false,
          message: e.kind == SafetyErrorKind.network ? offlineMessage : e.message,
        );
        _onError(e);
      }
    });
    if (mounted && state.busy) state = state.copyWith(busy: false);
    return ok;
  }

  /// Fecha o aviso curto.
  void clearMessage() {
    if (state.message != null) state = state.copyWith(clearMessage: true);
  }

  /// A gravacao terminou (salva ou descartada): "Cheguei". Tambem e o botao
  /// Cheguei da faixa (encerra so o Rastro Seguro; a gravacao continua).
  Future<void> arrive() async {
    final id = sessionId;
    if (id == null) return;
    _pendingArrival = id;
    state = const SafetyUiState();
    await _run(_sendArrival);
  }

  Future<void> _sendArrival() async {
    final id = _pendingArrival;
    if (id == null) return;
    try {
      await _api.arrived(id);
      _pendingArrival = null;
      _stopTicks();
    } on SafetyException catch (e) {
      if (e.kind == SafetyErrorKind.notFound) {
        _pendingArrival = null;
        _stopTicks();
        return;
      }
      // Sem rede: o tick continua e tenta de novo.
      if (_tick == null) _listenTicks();
    }
  }

  /// Novo estado da gravacao (o provider liga isto ao controller).
  void onRecording(RecordingUiState s) {
    if (s.state == RecordingState.finished && state.active) unawaited(arrive());
  }

  /// A caixa de entrada trouxe uma checagem desta sessao: rele a sessao.
  Future<void> onInboxCheck(String? sessionIdFromInbox) async {
    final id = sessionId;
    if (id == null || (sessionIdFromInbox != null && sessionIdFromInbox != id)) return;
    await _run(() async {
      try {
        final s = await _api.session(id);
        if (!mounted) return;
        state = state.copyWith(session: s);
        _apply(s);
      } on SafetyException catch (e) {
        _onError(e);
      }
    });
  }

  /// Recuperacao: le a sessao ativa no backend. Da gravacao em andamento:
  /// religa a faixa e o tick. De uma atividade que ja terminou (e nao esta
  /// em [interrupted], esperando a decisao de retomar): encerra. Sem rede ou
  /// sem login: nada.
  Future<void> reconcile({Future<bool> Function(String guid)? interrupted}) async {
    if (state.active && _pendingArrival == null) return;
    await _run(() async {
      final SafetySession? s;
      try {
        s = await _api.activeSession();
      } on SafetyException {
        return;
      }
      if (s == null || !mounted) return;
      final guid = _recordingGuid();
      if (_recording().isActive && guid == s.activityGuid) {
        if (!state.active) _attach(s);
        return;
      }
      if (interrupted != null && await interrupted(s.activityGuid)) return;
      try {
        await _api.arrived(s.id);
      } on SafetyException catch (e) {
        debugPrint('Rastro Seguro: sessao antiga nao encerrou: $e');
      }
    });
  }

  /// A atividade [guid] recuperada foi salva ou descartada sem retomar: a
  /// sessao dela termina.
  Future<void> endFor(String guid) => _run(() async {
    try {
      final s = await _api.activeSession();
      if (s != null && s.activityGuid == guid) await _api.arrived(s.id);
    } on SafetyException catch (e) {
      debugPrint('Rastro Seguro: nao encerrou a sessao de $guid: $e');
    }
  });

  /// Espera os envios em andamento (testes).
  Future<void> idle() => _chain;

  void _stopTicks() {
    _tick?.cancel();
    _tick = null;
  }

  @override
  void dispose() {
    _stopTicks();
    super.dispose();
  }
}
