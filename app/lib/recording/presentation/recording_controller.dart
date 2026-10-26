// Controller da gravacao (Riverpod StateNotifier). Costura a borda de localizacao
// (LocationSource), o dominio (RecordingSession) e a persistencia incremental
// (RecordingRepository). Clean room a partir dos relatorios 03-05.
library;

// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';

import '../../persistence/recording_repository.dart';
import '../domain/geo.dart';
import '../domain/location_sample.dart';
import '../domain/recording_models.dart';
import '../domain/recording_session.dart';
import '../domain/waypoint.dart';
import '../source/location_source.dart';
import 'recording_ui_state.dart';

/// A cada quantos pontos aceitos descarregamos o lote no banco.
const int kWaypointFlushBatch = 10;

class RecordingController extends StateNotifier<RecordingUiState> {
  final LocationSource _source;
  final RecordingRepository _repo;
  final int Function() _now; // epoch ms (injetavel para testes)

  /// Conta logada no inicio da gravacao (dona da atividade), ou null.
  final String? Function() _currentUserId;

  RecordingSession? _session;
  StreamSubscription<LocationSample>? _sub;
  String? _guid;
  final List<Waypoint> _batch = [];
  final List<GeoPoint> _route = [];
  int _lastMonotonicMs = 0;

  /// Pontos aceitos ate agora, para desenhar a rota (polyline).
  List<GeoPoint> get route => List.unmodifiable(_route);

  RecordingController({
    required LocationSource source,
    required RecordingRepository repo,
    int Function()? now,
    String? Function()? currentUserId,
  })  : _source = source,
        _repo = repo,
        _now = now ?? (() => DateTime.now().millisecondsSinceEpoch),
        _currentUserId = currentUserId ?? (() => null),
        super(const RecordingUiState());

  String? get activityGuid => _guid;

  Future<void> start(ActivityType type, {bool autoPauseEnabled = true}) async {
    if (state.isActive) return;
    if (!await _ensurePermission()) return;
    final guid = 'act_${_now()}';
    final session = _beginSession(guid, type, autoPauseEnabled);

    await _repo.startActivity(
      guid: guid,
      type: type,
      startTimestampMs: _now(),
      autoPauseEnabled: autoPauseEnabled,
      ownerUserId: _currentUserId(),
    );

    session.start(0); // base monotonica; a fonte conta a partir do inicio
    _listen();
  }

  /// Continua uma atividade que ficou sem finalizar (app morto, reboot). O
  /// estado e reconstruido dos pontos salvos; o tempo fora conta como pausa.
  Future<void> resumeInterrupted(InterruptedActivity interrupted) async {
    if (state.isActive) return;
    if (!await _ensurePermission()) return;
    final a = interrupted.activity;
    final session = _beginSession(a.guid, a.activityType, a.autoPauseEnabled);
    _route.addAll(interrupted.acceptedPoints.map((w) => w.position));

    await _repo.resumeActivity(a.guid);

    session.restore(
      interrupted.acceptedPoints,
      monotonicMs: 0, // a nova fonte conta a partir de agora
      elapsedMs: _now() - a.startTimestampMs,
    );
    _listen();
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
    final session = RecordingSession(
      activityType: type,
      autoPauseEnabled: autoPauseEnabled,
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
    _sub = _source.positions().listen(_onSample, onError: _onError);
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
  }

  void _onError(Object error, StackTrace _) {
    state = state.copyWith(error: 'Erro na localizacao: $error');
  }

  void pause() {
    _session?.pauseManual(_lastMonotonicMs);
    _emit();
  }

  void resume() {
    _session?.resumeManual(_lastMonotonicMs);
    _emit();
  }

  Future<void> stop() async {
    final session = _session;
    final guid = _guid;
    await _sub?.cancel();
    _sub = null;
    if (session == null || guid == null) return;
    session.finish();
    await _flush();
    final st = session.stats;
    await _repo.finish(
      guid,
      _now(),
      distanceMeters: st.distanceMeters,
      timerTimeMs: st.timerMs,
    );
    _emit();
    _session = null;
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
    state = RecordingUiState.fromStats(session.stats, error: state.error);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
