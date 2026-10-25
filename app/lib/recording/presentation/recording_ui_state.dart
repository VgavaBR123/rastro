// Estado de UI da gravacao, derivado de RecordingStats do dominio.
library;

import '../domain/recording_models.dart';
import '../domain/recording_session.dart';

class RecordingUiState {
  final RecordingState state;
  final double distanceMeters;
  final int elapsedMs;
  final int timerMs;
  final double ascentMeters;
  final double descentMeters;
  final int points;
  final String? error;

  const RecordingUiState({
    this.state = RecordingState.idle,
    this.distanceMeters = 0,
    this.elapsedMs = 0,
    this.timerMs = 0,
    this.ascentMeters = 0,
    this.descentMeters = 0,
    this.points = 0,
    this.error,
  });

  bool get isRecording => state == RecordingState.recording;
  bool get isPaused =>
      state == RecordingState.manuallyPaused || state == RecordingState.autoPaused;
  bool get isActive => isRecording || isPaused;

  /// Pace medio (s/m) pelo tempo de cronometro; null se sem distancia.
  double? get avgPaceSecondsPerMeter =>
      distanceMeters > 0 ? (timerMs / 1000.0) / distanceMeters : null;

  factory RecordingUiState.fromStats(RecordingStats s, {String? error}) =>
      RecordingUiState(
        state: s.state,
        distanceMeters: s.distanceMeters,
        elapsedMs: s.elapsedMs,
        timerMs: s.timerMs,
        ascentMeters: s.ascentMeters,
        descentMeters: s.descentMeters,
        points: s.acceptedPointCount,
        error: error,
      );

  RecordingUiState copyWith({RecordingState? state, String? error}) =>
      RecordingUiState(
        state: state ?? this.state,
        distanceMeters: distanceMeters,
        elapsedMs: elapsedMs,
        timerMs: timerMs,
        ascentMeters: ascentMeters,
        descentMeters: descentMeters,
        points: points,
        error: error,
      );
}
