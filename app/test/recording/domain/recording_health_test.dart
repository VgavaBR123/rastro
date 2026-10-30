// Saude da gravacao (F01): resumo de lacunas, precisao, descartes e bateria.
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/recording/domain/gap_monitor.dart';
import 'package:strava_estudo_app/recording/domain/recording_health.dart';

void main() {
  test('soma lacunas, media de precisao e bateria gasta', () {
    final h = RecordingHealth.from(
      gaps: const [
        RecordingGap(startMs: 0, endMs: 40000, reason: GapReason.noGpsSignal),
        RecordingGap(
          startMs: 100000,
          endMs: 165000,
          reason: GapReason.processStopped,
        ),
      ],
      horizontalAccuracies: const [4, 6, null, 5],
      discardedPoints: 3,
      startBatteryLevel: 90,
      endBatteryLevel: 82,
    );
    expect(h.gapCount, 2);
    expect(h.gapTotalMs, 105000);
    expect(h.avgHorizontalAccuracyMeters, closeTo(5, 1e-9));
    expect(h.discardedPoints, 3);
    expect(h.batteryUsedPercent, 8);
    expect(h.hasGaps, isTrue);
  });

  test('sem dados: nulos onde nao ha leitura', () {
    final h = RecordingHealth.from(
      gaps: const [],
      horizontalAccuracies: const [null],
      discardedPoints: 0,
      startBatteryLevel: 50,
      endBatteryLevel: null,
    );
    expect(h.gapCount, 0);
    expect(h.gapTotalMs, 0);
    expect(h.hasGaps, isFalse);
    expect(h.avgHorizontalAccuracyMeters, isNull);
    expect(h.batteryUsedPercent, isNull);
  });

  test('carregou durante a atividade: bateria gasta 0', () {
    final h = RecordingHealth.from(
      gaps: const [],
      horizontalAccuracies: const [],
      discardedPoints: 0,
      startBatteryLevel: 40,
      endBatteryLevel: 70,
    );
    expect(h.batteryUsedPercent, 0);
  });

  test('ignora precisoes invalidas (negativas ou nao finitas)', () {
    final h = RecordingHealth.from(
      gaps: const [],
      horizontalAccuracies: const [-1, double.nan, 10],
      discardedPoints: 0,
    );
    expect(h.avgHorizontalAccuracyMeters, 10);
  });

  group('formatGapDuration', () {
    test('segundos, minutos e horas', () {
      expect(formatGapDuration(45000), '45 s');
      expect(formatGapDuration(65000), '1 min 05 s');
      expect(formatGapDuration(120000), '2 min');
      expect(formatGapDuration(3725000), '1 h 02 min');
    });
  });

  test('gravacao sem monitoramento (antiga ou baixada): monitored false', () {
    final antiga = RecordingHealth.from(
      gaps: const [],
      horizontalAccuracies: const [5],
      discardedPoints: 0,
      monitored: false,
    );
    expect(antiga.monitored, isFalse);
    final nova = RecordingHealth.from(
      gaps: const [],
      horizontalAccuracies: const [5],
      discardedPoints: 0,
    );
    expect(nova.monitored, isTrue);
  });
}
