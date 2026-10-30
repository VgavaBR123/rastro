// Estado de UI da gravacao, derivado de RecordingStats do dominio.
library;

import '../domain/gap_monitor.dart';
import '../domain/recording_models.dart';
import '../domain/recording_session.dart';
import '../domain/splits.dart';

/// Split corrente ao vivo (relatorio 04): numero, distancia percorrida no
/// split e pace ao vivo (null enquanto abaixo do piso de tempo).
class LiveSplit {
  final int number;
  final double distanceMeters;
  final double? paceSecondsPerMeter;

  const LiveSplit({
    required this.number,
    required this.distanceMeters,
    this.paceSecondsPerMeter,
  });

  /// Le o split corrente de uma lista de splits (km ou milha).
  factory LiveSplit.of(SplitList list) {
    final cur = list.currentSplit;
    return LiveSplit(
      number: list.completedCount + 1,
      distanceMeters: cur?.distanceMeters ?? 0,
      paceSecondsPerMeter: list.currentLivePaceSecondsPerMeter,
    );
  }
}

/// Volta corrente ao vivo.
class LiveLap {
  final int number;
  final double distanceMeters;
  final int timerMs;

  const LiveLap({
    required this.number,
    required this.distanceMeters,
    required this.timerMs,
  });

  factory LiveLap.of(LapRecord lap) => LiveLap(
    number: lap.number,
    distanceMeters: lap.distanceMeters,
    timerMs: lap.durationMs,
  );
}

class RecordingUiState {
  final RecordingState state;
  final double distanceMeters;
  final int elapsedMs;
  final int timerMs;
  final double ascentMeters;
  final double descentMeters;
  final int points;
  final String? error;

  /// Split corrente em km e em milha; a tela escolhe pela unidade.
  final LiveSplit splitKm;
  final LiveSplit splitMile;

  /// Volta corrente e quantas ja foram fechadas.
  final LiveLap currentLap;
  final int completedLaps;

  /// Gravacao blindada (F01): ultima lacuna detectada, ate o usuario fechar o
  /// aviso. Null = nenhum aviso.
  final RecordingGap? gapNotice;

  /// Gravando ha mais de 30 s sem ponto de GPS.
  final bool gpsSignalLost;

  /// Esporte da gravacao corrente (null antes de comecar).
  final ActivityType? activityType;

  /// Narrador (F03): duracao (cronometro) dos splits ja fechados, em ordem.
  final List<int> splitDurationsKmMs;
  final List<int> splitDurationsMileMs;

  /// Narrador (F03): voltas ja fechadas, em ordem.
  final List<LapRecord> closedLaps;

  const RecordingUiState({
    this.state = RecordingState.idle,
    this.distanceMeters = 0,
    this.elapsedMs = 0,
    this.timerMs = 0,
    this.ascentMeters = 0,
    this.descentMeters = 0,
    this.points = 0,
    this.error,
    this.splitKm = const LiveSplit(number: 1, distanceMeters: 0),
    this.splitMile = const LiveSplit(number: 1, distanceMeters: 0),
    this.currentLap = const LiveLap(number: 1, distanceMeters: 0, timerMs: 0),
    this.completedLaps = 0,
    this.gapNotice,
    this.gpsSignalLost = false,
    this.activityType,
    this.splitDurationsKmMs = const [],
    this.splitDurationsMileMs = const [],
    this.closedLaps = const [],
  });

  bool get isRecording => state == RecordingState.recording;
  bool get isPaused =>
      state == RecordingState.manuallyPaused ||
      state == RecordingState.autoPaused;
  bool get isActive => isRecording || isPaused;

  /// Pace medio (s/m) pelo tempo de cronometro; null se sem distancia.
  double? get avgPaceSecondsPerMeter =>
      distanceMeters > 0 ? (timerMs / 1000.0) / distanceMeters : null;

  /// Split corrente na unidade escolhida.
  LiveSplit split({required bool metric}) => metric ? splitKm : splitMile;

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

  /// Estado completo a partir da sessao: metricas, split e volta correntes.
  factory RecordingUiState.fromSession(
    RecordingSession session, {
    String? error,
    RecordingGap? gapNotice,
    bool gpsSignalLost = false,
  }) {
    final s = session.stats;
    return RecordingUiState(
      state: s.state,
      distanceMeters: s.distanceMeters,
      elapsedMs: s.elapsedMs,
      timerMs: s.timerMs,
      ascentMeters: s.ascentMeters,
      descentMeters: s.descentMeters,
      points: s.acceptedPointCount,
      error: error,
      splitKm: LiveSplit.of(session.splits.kilometers),
      splitMile: LiveSplit.of(session.splits.miles),
      currentLap: LiveLap.of(session.currentLap),
      completedLaps: session.laps.length,
      gapNotice: gapNotice,
      gpsSignalLost: gpsSignalLost,
      activityType: session.activityType,
      splitDurationsKmMs: _durations(session.splits.kilometers),
      splitDurationsMileMs: _durations(session.splits.miles),
      closedLaps: session.laps,
    );
  }

  static List<int> _durations(SplitList list) =>
      List.unmodifiable([for (final s in list.completed) s.durationMs]);

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
        splitKm: splitKm,
        splitMile: splitMile,
        currentLap: currentLap,
        completedLaps: completedLaps,
        gapNotice: gapNotice,
        gpsSignalLost: gpsSignalLost,
        activityType: activityType,
        splitDurationsKmMs: splitDurationsKmMs,
        splitDurationsMileMs: splitDurationsMileMs,
        closedLaps: closedLaps,
      );
}
