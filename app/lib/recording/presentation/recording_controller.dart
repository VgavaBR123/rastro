// Controller da gravacao (Riverpod StateNotifier). Costura a borda de localizacao
// (LocationSource), o acelerometro, o servico em primeiro plano com a
// notificacao, o dominio (RecordingSession) e a persistencia incremental
// (RecordingRepository). Clean room a partir dos relatorios 03-05.
library;

// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';

import '../../core/format/activity_labels.dart';
import '../../core/format/measures.dart';
import '../../persistence/recording_repository.dart';
import '../domain/auto_pause.dart';
import '../domain/calories.dart';
import '../domain/geo.dart';
import '../domain/location_sample.dart';
import '../domain/motion_auto_pause.dart';
import '../domain/recording_models.dart';
import '../domain/recording_session.dart';
import '../domain/waypoint.dart';
import '../service/recording_service.dart';
import '../source/accelerometer_source.dart';
import '../source/battery_level_source.dart';
import '../source/location_source.dart';
import 'recording_ui_state.dart';

/// A cada quantos pontos aceitos descarregamos o lote no banco.
const int kWaypointFlushBatch = 10;

/// Intervalo minimo entre atualizacoes do texto da notificacao (tempo
/// monotonico das amostras). Mudanca de estado (pausa) atualiza na hora.
const int kNotificationUpdateIntervalMs = 3000;

class RecordingController extends StateNotifier<RecordingUiState> {
  final LocationSource _source;
  final RecordingRepository _repo;
  final RecordingService _service;
  final AccelerometerSource _accel;
  final BatteryLevelSource _battery;
  final int Function() _now; // epoch ms (injetavel para testes)

  /// Conta logada no inicio da gravacao (dona da atividade), ou null.
  final String? Function() _currentUserId;

  /// Peso das configuracoes (kg), para estimar calorias no fim.
  final double? Function() _weightKg;

  /// Unidade das configuracoes, para o texto da notificacao.
  final bool Function() _useMetric;

  /// Estrategia de pausa automatica por esporte (padrao: a do dominio).
  final AutoPauseDetector Function(ActivityType)? _autoPauseFactory;

  RecordingSession? _session;
  StreamSubscription<LocationSample>? _sub;
  StreamSubscription<AccelSample>? _accelSub;
  StreamSubscription<RecordingCommand>? _commandSub;
  String? _guid;
  final List<Waypoint> _batch = [];
  final List<GeoPoint> _route = [];
  int _lastMonotonicMs = 0;
  int? _lastNotifiedMonotonicMs;
  bool? _lastNotifiedPaused;

  /// Pontos aceitos ate agora, para desenhar a rota (polyline).
  List<GeoPoint> get route => List.unmodifiable(_route);

  RecordingController({
    required LocationSource source,
    required RecordingRepository repo,
    RecordingService service = const NoopRecordingService(),
    AccelerometerSource accelerometer = const NoAccelerometerSource(),
    BatteryLevelSource battery = const NoBatteryLevelSource(),
    int Function()? now,
    String? Function()? currentUserId,
    double? Function()? weightKg,
    bool Function()? useMetric,
    AutoPauseDetector Function(ActivityType)? autoPauseFactory,
  }) : _source = source,
       _repo = repo,
       _service = service,
       _accel = accelerometer,
       _battery = battery,
       _now = now ?? (() => DateTime.now().millisecondsSinceEpoch),
       _currentUserId = currentUserId ?? (() => null),
       _weightKg = weightKg ?? (() => null),
       _useMetric = useMetric ?? (() => true),
       _autoPauseFactory = autoPauseFactory,
       super(const RecordingUiState());

  String? get activityGuid => _guid;

  Future<void> start(ActivityType type, {bool autoPauseEnabled = true}) async {
    if (state.isActive) return;
    if (!await _ensurePermission()) return;
    final startBattery = await _battery.level();
    final guid = 'act_${_now()}';
    final session = _beginSession(guid, type, autoPauseEnabled);

    await _repo.startActivity(
      guid: guid,
      type: type,
      startTimestampMs: _now(),
      autoPauseEnabled: autoPauseEnabled,
      startBatteryLevel: startBattery,
      ownerUserId: _currentUserId(),
    );

    session.start(0); // base monotonica; a fonte conta a partir do inicio
    _listen();
    await _service.start(_notification(session));
  }

  /// Continua uma atividade que ficou sem finalizar (app morto, reboot). O
  /// estado e reconstruido dos pontos salvos; o tempo fora conta como pausa.
  /// As voltas ja salvas continuam valendo e a numeracao segue delas.
  Future<void> resumeInterrupted(InterruptedActivity interrupted) async {
    if (state.isActive) return;
    if (!await _ensurePermission()) return;
    final a = interrupted.activity;
    final session = _beginSession(a.guid, a.activityType, a.autoPauseEnabled);
    _route.addAll(interrupted.acceptedPoints.map((w) => w.position));

    await _repo.resumeActivity(a.guid);
    final savedLaps = await _repo.laps(a.guid);

    session.restore(
      interrupted.acceptedPoints,
      monotonicMs: 0, // a nova fonte conta a partir de agora
      elapsedMs: _now() - a.startTimestampMs,
      completedLaps: [
        for (final l in savedLaps)
          LapRecord(
            number: l.number,
            startTimerMs: l.startTimerMs,
            endTimerMs: l.endTimerMs,
            endElapsedMs: l.endElapsedMs,
            startDistanceMeters: l.startDistanceMeters,
            endDistanceMeters: l.endDistanceMeters,
          ),
      ],
    );
    _listen();
    await _service.start(_notification(session));
  }

  Future<bool> _ensurePermission() async {
    final ok = await _source.ensurePermission();
    if (!ok) state = state.copyWith(error: 'Permissao de localizacao negada');
    return ok;
  }

  RecordingSession _beginSession(
    String guid,
    ActivityType type,
    bool autoPauseEnabled,
  ) {
    _guid = guid;
    _batch.clear();
    _route.clear();
    _lastMonotonicMs = 0;
    _lastNotifiedMonotonicMs = null;
    _lastNotifiedPaused = null;
    final session = RecordingSession(
      activityType: type,
      autoPauseEnabled: autoPauseEnabled,
      autoPauseDetector: _autoPauseFactory?.call(type),
      onWaypoint: (w) {
        if (w.classification == WaypointClassification.accept) {
          _batch.add(w);
          _route.add(w.position);
        }
      },
    );
    _session = session;
    return session;
  }

  void _listen() {
    // O GPS primeiro: ao assinar, a fonte zera o relogio monotonico
    // compartilhado com o acelerometro.
    _sub = _source.positions().listen(_onSample, onError: _onError);
    final session = _session;
    // Sensor ligado so quando a pausa automatica decide por movimento.
    if (session != null && session.usesMotionAutoPause) {
      _accelSub = _accel.samples().listen(_onAccel, onError: (Object _) {});
    }
    _commandSub = _service.commands.listen(_onCommand);
    _emit();
  }

  Future<void> _onSample(LocationSample s) async {
    final session = _session;
    if (session == null) return;
    _lastMonotonicMs = s.monotonicMs;
    session.addSample(s);
    if (_batch.length >= kWaypointFlushBatch) {
      await _flush();
    }
    _emit();
    _maybeNotify();
  }

  void _onAccel(AccelSample s) => _session?.addAccel(s);

  void _onError(Object error, StackTrace _) {
    state = state.copyWith(error: 'Erro na localizacao: $error');
  }

  /// Acoes vindas da notificacao: mesmo caminho dos botoes da tela.
  Future<void> _onCommand(RecordingCommand cmd) async {
    switch (cmd) {
      case RecordingCommand.pause:
        pause();
      case RecordingCommand.resume:
        resume();
      case RecordingCommand.lap:
        await lap();
      case RecordingCommand.stop:
        await stop();
    }
  }

  void pause() {
    _session?.pauseManual(_lastMonotonicMs);
    _emit();
    _maybeNotify(force: true);
  }

  void resume() {
    _session?.resumeManual(_lastMonotonicMs);
    _emit();
    _maybeNotify(force: true);
  }

  /// Fecha a volta corrente e a persiste. Devolve a volta fechada, ou null se
  /// nao ha gravacao ativa.
  Future<LapRecord?> lap() async {
    final session = _session;
    final guid = _guid;
    if (session == null || guid == null) return null;
    final closed = session.lap(_lastMonotonicMs);
    if (closed == null) return null;
    _emit();
    await _repo.saveLap(
      guid,
      number: closed.number,
      startTimerMs: closed.startTimerMs,
      endTimerMs: closed.endTimerMs,
      endElapsedMs: closed.endElapsedMs,
      startDistanceMeters: closed.startDistanceMeters,
      endDistanceMeters: closed.endDistanceMeters,
    );
    return closed;
  }

  Future<void> stop() async {
    final session = _session;
    final guid = _guid;
    await _cancelSubscriptions();
    if (session == null || guid == null) return;
    // Evita reentrada (ex.: Encerrar na tela e na notificacao ao mesmo tempo).
    _session = null;
    await _service.stop();
    session.finish();
    await _flush();
    final st = session.stats;
    final endBattery = await _battery.level();
    final calories = estimateCaloriesKcal(
      type: session.activityType,
      timerTimeMs: st.timerMs,
      distanceMeters: st.distanceMeters,
      weightKg: _weightKg(),
    );
    await _repo.finish(
      guid,
      _now(),
      endBattery: endBattery,
      distanceMeters: st.distanceMeters,
      timerTimeMs: st.timerMs,
      calories: calories,
    );
    state = RecordingUiState.fromSession(session, error: state.error);
  }

  Future<void> _cancelSubscriptions() async {
    await _sub?.cancel();
    _sub = null;
    await _accelSub?.cancel();
    _accelSub = null;
    await _commandSub?.cancel();
    _commandSub = null;
  }

  Future<void> _flush() async {
    if (_guid == null || _batch.isEmpty) return;
    final toWrite = List<Waypoint>.from(_batch);
    _batch.clear();
    await _repo.appendWaypoints(_guid!, toWrite);
  }

  void _emit() {
    final session = _session;
    if (session == null) return;
    state = RecordingUiState.fromSession(session, error: state.error);
  }

  RecordingNotification _notification(RecordingSession session) {
    final st = session.stats;
    final paused =
        st.state == RecordingState.manuallyPaused ||
        st.state == RecordingState.autoPaused;
    final label = activityTypeLabel(session.activityType);
    return RecordingNotification(
      title: paused ? '$label pausada' : '$label em andamento',
      text:
          '${formatDistance(st.distanceMeters, metric: _useMetric())}'
          '  -  ${formatDuration(st.timerMs)}',
      paused: paused,
    );
  }

  /// Atualiza a notificacao no maximo a cada [kNotificationUpdateIntervalMs],
  /// ou na hora quando a pausa muda ([force] ou estado diferente).
  void _maybeNotify({bool force = false}) {
    final session = _session;
    if (session == null) return;
    final n = _notification(session);
    final last = _lastNotifiedMonotonicMs;
    final due =
        last == null ||
        _lastMonotonicMs - last >= kNotificationUpdateIntervalMs;
    if (!force && !due && n.paused == _lastNotifiedPaused) return;
    _lastNotifiedMonotonicMs = _lastMonotonicMs;
    _lastNotifiedPaused = n.paused;
    unawaited(_service.update(n));
  }

  @override
  void dispose() {
    _sub?.cancel();
    _accelSub?.cancel();
    _commandSub?.cancel();
    super.dispose();
  }
}
