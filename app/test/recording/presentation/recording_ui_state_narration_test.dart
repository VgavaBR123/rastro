// O estado de UI leva o que o Narrador (F03) precisa: esporte, duracao dos
// splits fechados (km e milha) e as voltas fechadas.
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/location_sample.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/domain/recording_session.dart';
import 'package:strava_estudo_app/recording/presentation/recording_ui_state.dart';

/// Reta no equador a ~4 m/s, uma amostra por segundo.
List<LocationSample> straight(int count, {int startS = 0}) => [
  for (var i = startS; i < startS + count; i++)
    LocationSample(
      position: GeoPoint(latitude: 0, longitude: 0.000036 * i),
      wallClockMs: 1000 * i,
      monotonicMs: 1000 * i,
      horizontalAccuracyMeters: 5,
      speedMetersPerSecond: 4,
    ),
];

void main() {
  test('estado padrao: sem esporte, sem splits e sem voltas', () {
    const s = RecordingUiState();
    expect(s.activityType, isNull);
    expect(s.splitDurationsKmMs, isEmpty);
    expect(s.splitDurationsMileMs, isEmpty);
    expect(s.closedLaps, isEmpty);
  });

  test('fromSession expoe splits fechados e voltas', () {
    final session = RecordingSession(activityType: ActivityType.run, autoPauseEnabled: false)
      ..start(0);
    for (final p in straight(200)) {
      session.addSample(p);
    }
    session.lap(199000);
    for (final p in straight(150, startS: 200)) {
      session.addSample(p);
    }
    final ui = RecordingUiState.fromSession(session);
    expect(ui.activityType, ActivityType.run);
    expect(ui.distanceMeters, greaterThan(1000));
    expect(ui.splitDurationsKmMs, hasLength(1));
    expect(ui.splitDurationsKmMs.single, inInclusiveRange(240000, 260000));
    expect(ui.splitDurationsMileMs, isEmpty);
    expect(ui.closedLaps, hasLength(1));
    expect(ui.closedLaps.single.number, 1);
    // copyWith preserva.
    final copy = ui.copyWith(error: 'x');
    expect(copy.activityType, ActivityType.run);
    expect(copy.splitDurationsKmMs, ui.splitDurationsKmMs);
    expect(copy.closedLaps, ui.closedLaps);
  });
}
