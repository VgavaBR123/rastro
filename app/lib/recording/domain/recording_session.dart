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

  RecordingSession({
    required this.activityType,
    this.autoPauseEnabled = true,
    this.onWaypoint,
  }) {
    _autoPause = autoPauseFor(activityType);
  }

  RecordingState get state => _state;
  DualSplits get splits => _splits;

  void start(int monotonicMs) {
    _state = RecordingState.recording;
    _clock.start(monotonicMs);
  }

  /// Reconstroi a sessao de uma gravacao interrompida (app morto ou aparelho
  /// reiniciado) a partir dos pontos ACEITOS ja persistidos, em ordem.
  ///
  /// Splits e elevacao sao refeitos pelo replay dos pontos; distancia e
  /// cronometro continuam do ultimo ponto. [elapsedMs] e o tempo total desde o
  /// inicio da atividade (relogio de parede); o intervalo em que o app ficou
  /// fora conta como pausa, sem somar cronometro nem distancia.
  /// [monotonicMs] e a base monotonica da nova fonte de localizacao.
  void restore(
    List<Waypoint> acceptedPoints, {
    required int monotonicMs,
    required int elapsedMs,
  }) {
    var timerMs = 0;
    var distance = 0.0;
    for (final wp in acceptedPoints) {
      _splits.onAcceptedPoint(wp.cumulativeDistanceMeters, wp.timerTimeMs, wp.position);
      final alt = wp.position.altitudeMeters;
      if (alt != null) {
        _elevation.process(alt, verticalAccuracyMeters: wp.verticalAccuracyMeters);
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
    _state = RecordingState.recording;
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
      _splits.onAcceptedPoint(wp.cumulativeDistanceMeters, wp.timerTimeMs, wp.position);
      final alt = sample.position.altitudeMeters;
      if (alt != null) {
        _elevation.process(alt, verticalAccuracyMeters: sample.verticalAccuracyMeters);
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
