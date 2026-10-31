// Sessao do Rastro Seguro (F08) durante a gravacao. Cria a sessao no Iniciar,
// manda a ultima posicao conhecida a cada [interval] por um tick proprio (nao
// depende de chegar ponto de GPS: sem ponto novo vai um batimento com
// lat/lon null), le a checagem "esta tudo bem?" das respostas e encerra a
// sessao (arrived) quando a gravacao termina, salva ou descartada.
//
// Sem rede: guarda so a ultima posicao (a que nao saiu) e manda no proximo
// tick. O "arrived" que falhar por rede fica no registro local (banco) e e
// repetido a cada tick, no sync de fundo e na proxima abertura, porque um fim
// que nao chega ao backend vira checagem e alerta falso.
//
// Recuperacao apos crash: [reconcile] le a sessao ativa do backend e religa a
// faixa se ela for da gravacao em andamento. So encerra sessao criada NESTE
// aparelho (registro local) cuja atividade ja terminou: a mesma conta pode
// estar gravando com Rastro Seguro em outro aparelho.
//
// "moving" vem do deslocamento real nas amostras aceitas do ultimo intervalo
// (nao do estado da gravacao), para a regra de parada do backend funcionar
// mesmo com a auto-pausa desligada. "paused" e so a pausa manual.
library;

// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../narrator/domain/announcement.dart';
import '../narrator/narrator.dart';
import '../recording/domain/geo.dart';
import '../recording/domain/location_sample.dart';
import '../recording/domain/recording_models.dart';
import '../recording/presentation/recording_ui_state.dart';
import '../recording/source/heartbeat_ticker.dart';
import 'safety_api.dart';
import 'safety_local_store.dart';
import 'safety_models.dart';

/// Intervalo padrao das posicoes (contrato: a cada 60 s).
const Duration kSafetyPositionInterval = Duration(seconds: 60);

/// Limites do horario previsto (contrato: agora + 5 min ate agora + 12 h).
const int kSafetyMinEtaMs = 5 * 60000;
const int kSafetyMaxEtaMs = 12 * 3600000;

/// Chave das falas do Rastro Seguro na fila do Narrador.
const String kSafetyAnnouncementKey = 'safety';

const String kSafetyCheckPhrase = 'Esta tudo bem? Toque em Estou bem.';

const String kSosPendingText = 'SOS pendente, tentando enviar.';

/// Deslocamento minimo no intervalo para contar como "em movimento".
const double kSafetyMovingMinMeters = 15;

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
bool safetyEtaValid(int etaMs, int nowMs) => etaMs >= nowMs + kSafetyMinEtaMs && etaMs <= nowMs + kSafetyMaxEtaMs;

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

  /// Ja ha sessao ativa da conta em outro aparelho (409). Nada foi
  /// encerrado; [SafetySessionController.takeOver] encerra a outra.
  otherDevice,

  /// A gravacao terminou (descartada) enquanto a sessao era criada: a sessao
  /// foi encerrada na hora.
  cancelled,
}

/// Em movimento: alguma amostra de [window] (aceitas do ultimo intervalo)
/// esta a mais de 15 m (ou da precisao media, se maior) da referencia, que e
/// a ultima amostra antes do intervalo ([anchor]) ou a primeira dele. Sem
/// amostra nova no intervalo: parado.
bool movedInWindow(List<LocationSample> window, {LocationSample? anchor}) {
  if (window.isEmpty) return false;
  final ref = anchor ?? window.first;
  for (final s in window) {
    if (identical(s, ref)) continue;
    final acc = ((ref.horizontalAccuracyMeters ?? 0) + (s.horizontalAccuracyMeters ?? 0)) / 2;
    final limit = acc > kSafetyMovingMinMeters ? acc : kSafetyMovingMinMeters;
    if (haversineMeters(ref.position, s.position) > limit) return true;
  }
  return false;
}

/// Avisos que ficam na gravacao ate a pessoa dispensar.
enum SafetyNotice {
  /// O backend encerrou a sessao (404/409, fim automatico).
  ended,

  /// Todos os contatos sairam: ninguem sera avisado.
  noContacts,

  /// Token revogado (401): os envios nao chegam.
  signedOut,
}

String safetyNoticeText(SafetyNotice n) => switch (n) {
  SafetyNotice.ended => 'Rastro Seguro encerrado. Seus contatos nao estao mais acompanhando.',
  SafetyNotice.noContacts => 'Ninguem vai ser avisado se voce nao responder: seus contatos sairam do Rastro Seguro.',
  SafetyNotice.signedOut => 'Entre de novo: seus contatos nao estao recebendo sua posicao.',
};

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

  /// Aviso persistente (ate [SafetySessionController.dismissNotice]).
  final SafetyNotice? notice;

  /// SOS pedido que ainda nao chegou ao backend.
  final bool sosPending;

  /// Prazo da checagem no relogio deste aparelho: a duracao do servidor
  /// (deadlineMs - startedAt) contada a partir de quando a checagem chegou.
  final int? checkLocalDeadlineMs;

  const SafetyUiState({
    this.session,
    this.offline = false,
    this.busy = false,
    this.message,
    this.lastSentAt,
    this.notice,
    this.sosPending = false,
    this.checkLocalDeadlineMs,
  });

  bool get active => session != null && !session!.ended;
  SafetyCheck? get check => active ? session!.check : null;
  bool get alerted => active && session!.status == SafetyStatus.alerted;

  SafetyUiState copyWith({
    SafetySession? session,
    bool? offline,
    bool? busy,
    String? message,
    bool clearMessage = false,
    int? lastSentAt,
    SafetyNotice? notice,
    bool clearNotice = false,
    bool? sosPending,
    int? checkLocalDeadlineMs,
    bool clearCheckDeadline = false,
  }) => SafetyUiState(
    session: session ?? this.session,
    offline: offline ?? this.offline,
    busy: busy ?? this.busy,
    message: clearMessage ? null : message ?? this.message,
    lastSentAt: lastSentAt ?? this.lastSentAt,
    notice: clearNotice ? null : notice ?? this.notice,
    sosPending: sosPending ?? this.sosPending,
    checkLocalDeadlineMs: clearCheckDeadline ? null : checkLocalDeadlineMs ?? this.checkLocalDeadlineMs,
  );
}

class SafetySessionController extends StateNotifier<SafetyUiState> {
  final SafetyApi _api;
  final SafetyLocalStore _local;
  final HeartbeatTicker _ticker;
  final Duration _interval;
  final int Function() _now;
  final LocationSample? Function() _lastSample;
  final List<LocationSample> Function(int sinceWallMs) _recentAccepted;
  final RecordingUiState Function() _recording;
  final String? Function() _recordingGuid;
  final String? Function() _currentUserId;
  final Narrator _narrator;
  final SafetyHaptics _haptics;

  StreamSubscription<void>? _tick;
  Future<void> _chain = Future<void>.value();

  /// Instante (wallClockMs) da ultima amostra aceita pelo backend.
  int? _sentSampleAt;

  /// Checagem ja anunciada (startedAt), para nao falar de novo a cada tick.
  int? _announcedCheck;
  bool _announcedAlert = false;

  /// Sessao encerrada aqui cujo "arrived" ainda nao chegou ao backend (o
  /// registro local tambem guarda, para o sync de fundo e a proxima abertura).
  String? _pendingArrival;

  bool _sosInFlight = false;
  bool _authLostAnnounced = false;

  SafetySessionController({
    required SafetyApi api,
    required SafetyLocalStore local,
    required HeartbeatTicker ticker,
    Duration interval = kSafetyPositionInterval,
    required int Function() now,
    required LocationSample? Function() lastSample,
    List<LocationSample> Function(int sinceWallMs)? recentAccepted,
    required RecordingUiState Function() recording,
    required String? Function() recordingGuid,
    String? Function()? currentUserId,
    required Narrator narrator,
    SafetyHaptics haptics = const SystemSafetyHaptics(),
  }) : _api = api,
       _local = local,
       _ticker = ticker,
       _interval = interval,
       _now = now,
       _lastSample = lastSample,
       _recentAccepted = recentAccepted ?? ((_) => const []),
       _recording = recording,
       _recordingGuid = recordingGuid,
       _currentUserId = currentUserId ?? (() => null),
       _narrator = narrator,
       _haptics = haptics,
       super(const SafetyUiState());

  String? get sessionId => state.active ? state.session!.id : null;

  /// Cria a sessao para a gravacao [guid] que acabou de iniciar. Nunca
  /// lanca: o resultado diz por que nao ligou (a gravacao segue sem). No 409
  /// (sessao ativa) nada e encerrado, salvo se a ativa foi criada NESTE
  /// aparelho para outra atividade (sobra de um crash daqui).
  Future<SafetyBeginResult> begin({required String guid, required SafetyPlan plan, required int startMs}) async {
    final etaMs = plan.etaFor(startMs);
    if (!safetyEtaValid(etaMs, _now())) return SafetyBeginResult.invalidEta;
    try {
      SafetySession s;
      try {
        s = await _create(guid, etaMs, plan.contactIds);
      } on SafetyException catch (e) {
        if (e.kind != SafetyErrorKind.conflict) rethrow;
        final old = await _api.activeSession();
        if (old == null || old.activityGuid == guid || !await _local.isLocal(old.id)) {
          return SafetyBeginResult.otherDevice;
        }
        await _endRemote(old.id);
        s = await _create(guid, etaMs, plan.contactIds);
      }
      return await _started(s, guid);
    } on SafetyException catch (e) {
      return _beginError(e);
    }
  }

  /// "Encerrar o outro e usar este" (depois do 409 e da confirmacao): encerra
  /// a sessao ativa da conta, de qualquer aparelho, e cria a desta gravacao.
  Future<SafetyBeginResult> takeOver({required String guid, required SafetyPlan plan, required int startMs}) async {
    final etaMs = plan.etaFor(startMs);
    if (!safetyEtaValid(etaMs, _now())) return SafetyBeginResult.invalidEta;
    try {
      final old = await _api.activeSession();
      if (old != null) await _endRemote(old.id);
      return await _started(await _create(guid, etaMs, plan.contactIds), guid);
    } on SafetyException catch (e) {
      return _beginError(e);
    }
  }

  SafetyBeginResult _beginError(SafetyException e) {
    debugPrint('Rastro Seguro nao ligou: $e');
    return switch (e.kind) {
      SafetyErrorKind.network || SafetyErrorKind.server => SafetyBeginResult.offline,
      SafetyErrorKind.unauthorized => SafetyBeginResult.signedOut,
      SafetyErrorKind.conflict => SafetyBeginResult.otherDevice,
      _ => SafetyBeginResult.rejected,
    };
  }

  Future<SafetyBeginResult> _started(SafetySession s, String guid) async {
    await _local.created(sessionId: s.id, activityGuid: guid, ownerUserId: _currentUserId(), nowMs: _now());
    // Descartou (ou a gravacao mudou) enquanto a sessao era criada.
    if (!mounted || !_recording().isActive || _recordingGuid() != guid) {
      await _endRemote(s.id);
      return SafetyBeginResult.cancelled;
    }
    _attach(s);
    unawaited(_run(_report));
    return SafetyBeginResult.started;
  }

  /// Encerra no backend; sem rede, fica pendente no registro local.
  Future<void> _endRemote(String id) async {
    await _local.markPendingArrival(id);
    try {
      await _api.arrived(id);
      await _local.ended(id);
    } on SafetyException catch (e) {
      if (e.kind == SafetyErrorKind.notFound) await _local.ended(id);
    }
  }

  Future<SafetySession> _create(String guid, int etaMs, List<String> ids) =>
      _api.createSession(activityGuid: guid, etaMs: etaMs, contactIds: ids);

  void _attach(SafetySession s) {
    _sentSampleAt = null;
    _announcedCheck = null;
    _announcedAlert = false;
    _pendingArrival = null;
    _authLostAnnounced = false;
    state = SafetyUiState(session: s);
    _apply(s);
    _listenTicks();
  }

  void _listenTicks() {
    _tick?.cancel();
    _tick = _ticker.ticks(_interval).listen((_) => _onTick());
  }

  /// Serializa os envios: uma requisicao por vez, na ordem. O SOS nao passa
  /// por aqui (nao espera um envio preso).
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

  void _onTick() {
    if (state.sosPending) unawaited(_sendSos());
    unawaited(
      _run(() async {
        if (_pendingArrival != null) {
          await _sendArrival();
          return;
        }
        await _report();
      }),
    );
  }

  PositionReport _currentReport({bool forcePosition = false}) {
    final rec = _recording();
    final paused = rec.state == RecordingState.manuallyPaused;
    final at = _now();
    final since = at - _interval.inMilliseconds;
    final recent = _recentAccepted(since - _interval.inMilliseconds);
    final window = [
      for (final s in recent)
        if (s.wallClockMs >= since) s,
    ];
    LocationSample? anchor;
    for (final s in recent) {
      if (s.wallClockMs < since) anchor = s;
    }
    final moving = !paused && movedInWindow(window, anchor: anchor);
    final sample = _lastSample();
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
  /// conta como enviada e sai no proximo tick. 400: a amostra e descartada
  /// (o proximo envio e batimento).
  Future<void> _report({bool forcePosition = false}) async {
    final id = sessionId;
    if (id == null) return;
    final report = _currentReport(forcePosition: forcePosition);
    final sampleAt = report.hasPosition ? report.recordedAtMs : null;
    try {
      final s = await _api.postPosition(id, report);
      if (sampleAt != null) _sentSampleAt = sampleAt;
      if (!mounted) return;
      _authLostAnnounced = false;
      state = state.copyWith(
        session: s,
        offline: false,
        lastSentAt: _now(),
        clearNotice: state.notice == SafetyNotice.signedOut,
      );
      _apply(s);
    } on SafetyException catch (e) {
      if (e.kind == SafetyErrorKind.badRequest && sampleAt != null) _sentSampleAt = sampleAt;
      _onError(e);
    }
  }

  void _say(String text) => _narrator.enqueue(
    Announcement(text, priority: AnnouncementPriority.critical, key: kSafetyAnnouncementKey, maxAgeMs: 60000),
  );

  void _onError(SafetyException e) {
    if (!mounted) return;
    switch (e.kind) {
      case SafetyErrorKind.network || SafetyErrorKind.server:
        state = state.copyWith(offline: true);
      case SafetyErrorKind.unauthorized:
        if (!_authLostAnnounced) {
          _authLostAnnounced = true;
          _say(safetyNoticeText(SafetyNotice.signedOut));
          unawaited(_haptics.alert());
        }
        state = state.copyWith(notice: SafetyNotice.signedOut);
      case SafetyErrorKind.notFound || SafetyErrorKind.conflict:
        // A sessao sumiu ou ja encerrou no backend (fim sozinho em eta + 6 h:
        // 404, ou 409 "sessao encerrada").
        _endedByServer();
      case SafetyErrorKind.badRequest:
        break;
    }
  }

  /// O backend encerrou a sessao sem a pessoa pedir: fala, vibra e deixa o
  /// aviso na gravacao ate ela dispensar.
  void _endedByServer() {
    final id = state.session?.id;
    _stopTicks();
    if (id != null) unawaited(_local.ended(id));
    if (!mounted || state.session == null) return;
    _say(safetyNoticeText(SafetyNotice.ended));
    unawaited(_haptics.alert());
    state = const SafetyUiState(notice: SafetyNotice.ended);
  }

  /// Le a checagem nova: voz critica (mesmo com o Narrador desligado) e
  /// vibracao, uma vez por checagem. O alerta enviado tambem vibra.
  void _apply(SafetySession s) {
    if (s.ended) {
      if (_pendingArrival == null) {
        _endedByServer();
      } else {
        _stopTicks();
      }
      return;
    }
    final check = s.check;
    if (check == null) {
      if (state.checkLocalDeadlineMs != null) state = state.copyWith(clearCheckDeadline: true);
      _announcedCheck = null;
    } else if (_announcedCheck != check.startedAt) {
      _announcedCheck = check.startedAt;
      final span = check.deadlineMs - check.startedAt;
      state = state.copyWith(checkLocalDeadlineMs: _now() + (span > 0 ? span : 0));
      _say(kSafetyCheckPhrase);
      unawaited(_haptics.alert());
    }
    if (s.status == SafetyStatus.alerted && !_announcedAlert) {
      _announcedAlert = true;
      _say('Seus contatos foram avisados. Se estiver tudo bem, toque em Estou bem.');
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

  /// "Mandar minha posicao agora" / "Preciso de ajuda": o SOS sai PRIMEIRO,
  /// fora da fila dos ticks; a posicao vai depois, sem bloquear. Sem rede, o
  /// SOS fica pendente e e repetido a cada tick ate o backend aceitar.
  Future<bool> sos() async {
    if (sessionId == null) return false;
    state = state.copyWith(sosPending: true, message: kSosPendingText);
    return _sendSos();
  }

  Future<bool> _sendSos() async {
    final id = sessionId;
    if (id == null || _sosInFlight || !state.sosPending) return false;
    _sosInFlight = true;
    try {
      final s = await _api.sos(id);
      if (!mounted) return true;
      state = state.copyWith(
        session: s,
        sosPending: false,
        offline: false,
        message: 'Posicao enviada aos seus contatos.',
      );
      _apply(s);
      unawaited(_run(() => _report(forcePosition: true)));
      return true;
    } on SafetyException catch (e) {
      if (e.kind == SafetyErrorKind.network || e.kind == SafetyErrorKind.server) {
        if (mounted) state = state.copyWith(offline: true, message: kSosPendingText);
      } else {
        if (mounted) state = state.copyWith(sosPending: false, message: e.message);
        _onError(e);
      }
      return false;
    } finally {
      _sosInFlight = false;
    }
  }

  Future<bool> _action(Future<SafetySession> Function(String id) call, String offlineMessage, {String? done}) async {
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
        final offline = e.kind == SafetyErrorKind.network || e.kind == SafetyErrorKind.server;
        state = state.copyWith(busy: false, message: offline ? offlineMessage : e.message);
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

  /// Fecha o aviso persistente.
  void dismissNotice() {
    if (state.notice != null) state = state.copyWith(clearNotice: true);
  }

  /// Todos os contatos sairam da sessao (caixa de entrada: safety_no_contacts).
  void onNoContacts(String? id) {
    if (id != null && id != sessionId) return;
    if (!state.active || state.notice == SafetyNotice.noContacts) return;
    _say(safetyNoticeText(SafetyNotice.noContacts));
    unawaited(_haptics.alert());
    state = state.copyWith(notice: SafetyNotice.noContacts);
  }

  /// A gravacao terminou (salva ou descartada): "Cheguei". Tambem e o botao
  /// Cheguei da faixa (encerra so o Rastro Seguro; a gravacao continua).
  Future<void> arrive() async {
    final id = sessionId;
    if (id == null) return;
    _pendingArrival = id;
    state = const SafetyUiState();
    await _run(() async {
      await _local.markPendingArrival(id);
      await _sendArrival();
    });
  }

  Future<void> _sendArrival() async {
    final id = _pendingArrival;
    if (id == null) return;
    try {
      await _api.arrived(id);
      _pendingArrival = null;
      await _local.ended(id);
      _stopTicks();
    } on SafetyException catch (e) {
      if (e.kind == SafetyErrorKind.notFound) {
        _pendingArrival = null;
        await _local.ended(id);
        _stopTicks();
        return;
      }
      // Sem rede: o tick continua e tenta de novo (e o sync de fundo tambem).
      if (_tick == null) _listenTicks();
    }
  }

  /// Novo estado da gravacao (o provider liga isto ao controller).
  void onRecording(RecordingUiState s) {
    if (s.state == RecordingState.finished && state.active) unawaited(arrive());
  }

  /// A caixa de entrada trouxe algo desta sessao (checagem, fim): rele.
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

  /// Recuperacao: manda os "arrived" pendentes desta conta e le a sessao
  /// ativa no backend. Da gravacao em andamento: religa a faixa e o tick.
  /// Criada NESTE aparelho para uma atividade que ja terminou (e nao esta em
  /// [interrupted], esperando a decisao de retomar): encerra. De outro
  /// aparelho: nao mexe. Sem rede ou sem login: nada.
  Future<void> reconcile({Future<bool> Function(String guid)? interrupted}) async {
    await _run(() async {
      // So os desta conta (sem conta conhecida, nao manda: o token de outra
      // conta levaria 404 e apagaria o pendente dela).
      final uid = _currentUserId();
      if (uid != null) await sendPendingArrivals(_api, _local, ownerUserId: uid, except: _pendingArrival);
      if (state.active) return;
      final SafetySession? s;
      try {
        s = await _api.activeSession();
      } on SafetyException {
        return;
      }
      if (s == null || !mounted) return;
      if (_recording().isActive && _recordingGuid() == s.activityGuid) {
        if (!state.active && _pendingArrival != s.id) {
          await _local.created(
            sessionId: s.id,
            activityGuid: s.activityGuid,
            ownerUserId: _currentUserId(),
            nowMs: _now(),
          );
          _attach(s);
        }
        return;
      }
      if (!await _local.isLocal(s.id)) return;
      if (interrupted != null && await interrupted(s.activityGuid)) return;
      await _endRemote(s.id);
    });
  }

  /// A atividade [guid] recuperada foi salva ou descartada sem retomar: a
  /// sessao dela termina (so se foi criada neste aparelho).
  Future<void> endFor(String guid) => _run(() async {
    try {
      final s = await _api.activeSession();
      if (s != null && s.activityGuid == guid && await _local.isLocal(s.id)) await _endRemote(s.id);
    } on SafetyException catch (e) {
      debugPrint('Rastro Seguro: nao encerrou a sessao de $guid: $e');
    }
  });

  /// Antes de sair da conta (o token ainda vale): encerra a sessao em
  /// andamento, manda os pendentes e zera o controller. O que nao sair fica
  /// no registro local com a conta, para o proximo login dela.
  Future<void> beforeSignOut() async {
    if (state.active) await arrive();
    final uid = _currentUserId();
    if (uid != null) await _run(() => sendPendingArrivals(_api, _local, ownerUserId: uid));
    _pendingArrival = null;
    _stopTicks();
    if (mounted) state = const SafetyUiState();
  }

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

/// Manda os "arrived" que ficaram pendentes no registro local (de
/// [ownerUserId], se dado). Usado na abertura, no logout e no sync de fundo.
/// Devolve quantos ainda ficaram pendentes.
Future<int> sendPendingArrivals(SafetyApi api, SafetyLocalStore local, {String? ownerUserId, String? except}) async {
  var left = 0;
  for (final p in await local.pendingArrivals(ownerUserId: ownerUserId)) {
    if (p.sessionId == except) continue;
    try {
      await api.arrived(p.sessionId);
      await local.ended(p.sessionId);
    } on SafetyException catch (e) {
      if (e.kind == SafetyErrorKind.notFound) {
        await local.ended(p.sessionId);
      } else {
        left++;
      }
    }
  }
  return left;
}
