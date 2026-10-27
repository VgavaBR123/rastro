/// Agregado em memoria de uma gravacao em andamento (equivalente ao ActiveActivity
/// do estudo). Costura relogio, pipeline de filtragem, splits, elevacao e pausa
/// automatica. Clean room a partir de relatorios/03-05.
///
/// Deterministico e testavel: recebe LocationSample (com tempo monotonico) e nao
/// le o relogio do sistema. A persistencia incremental (etapa 05) sera plugada
/// por um callback/porta, mantendo este nucleo livre de I/O.
library;

import 'auto_pause.dart';
import 'elevation.dart';
import 'location_sample.dart';
import 'motion_auto_pause.dart';
import 'point_pipeline.dart';
import 'recording_clock.dart';
import 'recording_models.dart';
import 'splits.dart';
import 'waypoint.dart';

/// Snapshot imutavel das metricas correntes (para a UI e persistencia).
class RecordingStats {
  final RecordingState state;
  final double distanceMeters;
  final int elapsedMs;
  final int timerMs;
  final double ascentMeters;
  final double descentMeters;
  final int acceptedPointCount;

  const RecordingStats({
    required this.state,
    required this.distanceMeters,
    required this.elapsedMs,
    required this.timerMs,
    required this.ascentMeters,
    required this.descentMeters,
    required this.acceptedPointCount,
  });

  /// Pace medio (s/m) pelo tempo de cronometro; null se sem distancia.
  double? get avgPaceSecondsPerMeter =>
      distanceMeters > 0 ? (timerMs / 1000.0) / distanceMeters : null;
}

/// Volta (lap) marcada pelo usuario. Comeca onde a anterior terminou (a
/// primeira, no inicio da atividade) e fecha no instante do pedido, em
/// distancia e cronometro.
class LapRecord {
  final int number; // 1-based
  final int startTimerMs;
  final int endTimerMs;
  final int endElapsedMs;
  final double startDistanceMeters;
  final double endDistanceMeters;

  const LapRecord({
    required this.number,
    required this.startTimerMs,
    required this.endTimerMs,
    required this.endElapsedMs,
    required this.startDistanceMeters,
    required this.endDistanceMeters,
  });

  double get distanceMeters => endDistanceMeters - startDistanceMeters;
  int get durationMs => endTimerMs - startTimerMs;

  /// Pace da volta (s/m); null sem distancia ou sem tempo.
  double? get paceSecondsPerMeter => (distanceMeters > 0 && durationMs > 0)
      ? (durationMs / 1000.0) / distanceMeters
      : null;
}

/// Porta de saida para persistir cada ponto aceito (etapa 05). A implementacao
/// concreta (Drift) entra na camada de dados; o dominio so chama.
typedef WaypointSink = void Function(Waypoint waypoint);

class RecordingSession {
  final ActivityType activityType;
  final bool autoPauseEnabled;
  final WaypointSink? onWaypoint;

  final RecordingClock _clock = RecordingClock();
  final PointPipeline _pipeline = PointPipeline();
  final DualSplits _splits = DualSplits();
  final ElevationAccumulator _elevation = ElevationAccumulator();
  late final AutoPauseDetector _autoPause;

  RecordingState _state = RecordingState.idle;
  int _acceptedCount = 0;
  int _lastMonotonicMs = 0;
  final List<LapRecord> _laps = [];

  /// [autoPauseDetector] substitui a estrategia padrao do esporte
  /// ([autoPauseFor]); usado em testes.
  RecordingSession({
    required this.activityType,
    this.autoPauseEnabled = true,
    this.onWaypoint,
    AutoPauseDetector? autoPauseDetector,
  }) {
    _autoPause = autoPauseDetector ?? autoPauseFor(activityType);
  }

  RecordingState get state => _state;
  DualSplits get splits => _splits;

  /// Voltas ja fechadas, em ordem.
  List<LapRecord> get laps => List.unmodifiable(_laps);

  /// True quando a pausa automatica desta sessao decide pelo acelerometro: so
  /// entao vale a pena ligar o sensor.
  bool get usesMotionAutoPause =>
      autoPauseEnabled && _autoPause is MotionAutoPauseDetector;

  void start(int monotonicMs) {
    _state = RecordingState.recording;
    _clock.start(monotonicMs);
    _lastMonotonicMs = monotonicMs;
  }

  /// Reconstroi a sessao de uma gravacao interrompida (app morto ou aparelho
  /// reiniciado) a partir dos pontos ACEITOS ja persistidos, em ordem.
  ///
  /// Splits e elevacao sao refeitos pelo replay dos pontos; distancia e
  /// cronometro continuam do ultimo ponto. [elapsedMs] e o tempo total desde o
  /// inicio da atividade (relogio de parede); o intervalo em que o app ficou
  /// fora conta como pausa, sem somar cronometro nem distancia.
  /// [monotonicMs] e a base monotonica da nova fonte de localizacao.
  ///
  /// [completedLaps] sao as voltas ja salvas: a numeracao continua delas e a
  /// volta corrente comeca no fim da ultima.
  void restore(
    List<Waypoint> acceptedPoints, {
    required int monotonicMs,
    required int elapsedMs,
    List<LapRecord> completedLaps = const [],
  }) {
    var timerMs = 0;
    var distance = 0.0;
    for (final wp in acceptedPoints) {
      _splits.onAcceptedPoint(
        wp.cumulativeDistanceMeters,
        wp.timerTimeMs,
        wp.position,
      );
      final alt = wp.position.altitudeMeters;
      if (alt != null) {
        _elevation.process(
          alt,
          verticalAccuracyMeters: wp.verticalAccuracyMeters,
        );
      }
      timerMs = wp.timerTimeMs;
      distance = wp.cumulativeDistanceMeters;
    }
    _acceptedCount = acceptedPoints.length;
    _pipeline.restoreDistance(distance);
    _clock.restore(
      monotonicMs,
      elapsedMs: elapsedMs < timerMs ? timerMs : elapsedMs,
      timerMs: timerMs,
    );
    _lastMonotonicMs = monotonicMs;
    _laps
      ..clear()
      ..addAll(completedLaps);
    _state = RecordingState.recording;
  }

  /// Fecha a volta corrente no instante [monotonicMs] (ou no ultimo instante
  /// conhecido, se for anterior) e abre a proxima. Devolve a volta fechada, ou
  /// null se a sessao nao esta ativa.
  LapRecord? lap(int monotonicMs) {
    if (_state == RecordingState.idle || _state == RecordingState.finished) {
      return null;
    }
    _advanceClock(monotonicMs);
    final cur = currentLap;
    final closed = LapRecord(
      number: cur.number,
      startTimerMs: cur.startTimerMs,
      endTimerMs: cur.endTimerMs,
      endElapsedMs: _clock.elapsedMs,
      startDistanceMeters: cur.startDistanceMeters,
      endDistanceMeters: cur.endDistanceMeters,
    );
    _laps.add(closed);
    return closed;
  }

  /// Volta corrente (aberta), do fim da anterior ate agora.
  LapRecord get currentLap {
    final prev = _laps.isEmpty ? null : _laps.last;
    return LapRecord(
      number: _laps.length + 1,
      startTimerMs: prev?.endTimerMs ?? 0,
      endTimerMs: _clock.timerMs,
      endElapsedMs: _clock.elapsedMs,
      startDistanceMeters: prev?.endDistanceMeters ?? 0,
      endDistanceMeters: _pipeline.cumulativeDistanceMeters,
    );
  }

  /// Repassa uma amostra do acelerometro ao detector de pausa por movimento
  /// (corrida). Com outro detector, nao faz nada.
  void addAccel(AccelSample sample) {
    final d = _autoPause;
    if (d is MotionAutoPauseDetector) d.addAccel(sample);
  }

  void _advanceClock(int monotonicMs) {
    if (monotonicMs > _lastMonotonicMs) {
      _lastMonotonicMs = monotonicMs;
      _clock.tick(monotonicMs);
    }
  }

  void pauseManual(int monotonicMs) {
    if (_state == RecordingState.finished) return;
    _state = RecordingState.manuallyPaused;
    _clock.pause(monotonicMs);
    _pipeline.resetRecentBuffer();
  }

  void resumeManual(int monotonicMs) {
    if (_state != RecordingState.manuallyPaused) return;
    _state = RecordingState.recording;
    _clock.resume(monotonicMs);
  }

  void finish() {
    _state = RecordingState.finished;
  }

  bool get _isPaused =>
      _state == RecordingState.manuallyPaused ||
      _state == RecordingState.autoPaused;

  /// Processa uma amostra de localizacao. Retorna o Waypoint classificado.
  Waypoint addSample(LocationSample sample) {
    _clock.tick(sample.monotonicMs);
    _lastMonotonicMs = sample.monotonicMs;

    // Pausa automatica (so quando habilitada e nao em pausa manual).
    if (autoPauseEnabled && _state != RecordingState.manuallyPaused) {
      final shouldPause = _autoPause.shouldBePaused(sample);
      if (shouldPause && _state == RecordingState.recording) {
        _state = RecordingState.autoPaused;
        _clock.pause(sample.monotonicMs);
        _pipeline.resetRecentBuffer();
      } else if (!shouldPause && _state == RecordingState.autoPaused) {
        _state = RecordingState.recording;
        _clock.resume(sample.monotonicMs);
      }
    }

    // `manuallyPaused` aqui significa "em qualquer pausa": pontos em pausa (manual
    // ou automatica) nao somam trajeto.
    final wp = _pipeline.process(
      sample,
      manuallyPaused: _isPaused,
      elapsedTimeMs: _clock.elapsedMs,
      timerTimeMs: _clock.timerMs,
    );

    if (wp.classification == WaypointClassification.accept) {
      _acceptedCount++;
      _splits.onAcceptedPoint(
        wp.cumulativeDistanceMeters,
        wp.timerTimeMs,
        wp.position,
      );
      final alt = sample.position.altitudeMeters;
      if (alt != null) {
        _elevation.process(
          alt,
          verticalAccuracyMeters: sample.verticalAccuracyMeters,
        );
      }
    }

    onWaypoint?.call(wp);
    return wp;
  }

  RecordingStats get stats => RecordingStats(
    state: _state,
    distanceMeters: _pipeline.cumulativeDistanceMeters,
    elapsedMs: _clock.elapsedMs,
    timerMs: _clock.timerMs,
    ascentMeters: _elevation.stats.ascentMeters,
    descentMeters: _elevation.stats.descentMeters,
    acceptedPointCount: _acceptedCount,
  );
}
