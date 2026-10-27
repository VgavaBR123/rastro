import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/core/format/activity_share_text.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';

void main() {
  test('corrida em km: titulo, esporte, distancia, tempo e pace', () {
    expect(
      activityShareText(
        title: 'Longao',
        type: ActivityType.run,
        distanceMeters: 5000,
        timerMs: 1500000,
        metric: true,
      ),
      'Longao\nCorrida | 5.00 km | 25:00 | 5:00 /km',
    );
  });

  test('caminhada em milhas usa pace por milha', () {
    expect(
      activityShareText(
        title: 'Passeio',
        type: ActivityType.walk,
        distanceMeters: 1609.344,
        timerMs: 600000,
        metric: false,
      ),
      'Passeio\nCaminhada | 1.00 mi | 10:00 | 10:00 /mi',
    );
  });

  test('pedal usa velocidade', () {
    expect(
      activityShareText(
        title: 'Pedal da tarde',
        type: ActivityType.ride,
        distanceMeters: 20000,
        timerMs: 3600000,
        metric: true,
      ),
      'Pedal da tarde\nPedal | 20.00 km | 1:00:00 | 20.0 km/h',
    );
  });
}
