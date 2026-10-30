// Modo Gentil (F04) no Narrador: as frases nunca falam pace, velocidade nem
// "mais rapido"; ficam o tempo e a distancia.
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/narrator/domain/narration_composer.dart';
import 'package:strava_estudo_app/narrator/domain/narration_event.dart';
import 'package:strava_estudo_app/narrator/domain/narrator_settings.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';

NarrationTotals totals({
  double distance = 2000,
  int timerMs = 652000,
  ActivityType type = ActivityType.run,
}) => NarrationTotals(type: type, distanceMeters: distance, timerMs: timerMs, metric: true);

void expectNoRate(String text) {
  final t = text.toLowerCase();
  for (final w in ['pace', 'velocidade', 'rápid', 'por hora', 'média', 'médio']) {
    expect(t, isNot(contains(w)), reason: '"$text" fala de ritmo ($w)');
  }
}

void main() {
  const on = NarratorSettings(enabled: true);
  const composer = NarrationComposer();

  final split = SplitClosed(
    number: 2,
    durationMs: 320000,
    previousDurationsMs: const [332000],
    totals: totals(),
  );

  test('split: so marca e tempo', () {
    final a = composer.compose(split, on, gentle: true)!;
    expectNoRate(a.text);
    expect(a.text, 'Dois quilômetros. Tempo dez minutos e cinquenta e dois segundos.');
  });

  test('split no modo so o essencial: tempo no lugar do pace', () {
    final a = composer.compose(split, on.copyWith(essentialOnly: true), gentle: true)!;
    expect(a.text, 'Dois quilômetros. Tempo dez minutos e cinquenta e dois segundos.');
  });

  test('pedal tambem sem velocidade', () {
    final ride = SplitClosed(
      number: 1,
      durationMs: 120000,
      previousDurationsMs: const [],
      totals: totals(distance: 1000, timerMs: 120000, type: ActivityType.ride),
    );
    expectNoRate(composer.compose(ride, on, gentle: true)!.text);
    expectNoRate(
      composer.compose(ride, on.copyWith(essentialOnly: true), gentle: true)!.text,
    );
  });

  test('volta: tempo e distancia, sem pace nem "mais rapida"', () {
    final lap = LapClosed(
      lap: const LapMark(number: 2, durationMs: 100000, distanceMeters: 400),
      previous: const [LapMark(number: 1, durationMs: 120000, distanceMeters: 400)],
      totals: totals(),
    );
    final a = composer.compose(lap, on, gentle: true)!;
    expectNoRate(a.text);
    expect(a.text, contains('Tempo da volta'));
    expect(a.text, contains('Distância da volta'));
  });

  test('marca de tempo e fim sem medio', () {
    final t = composer.compose(TimeMark(markMs: 600000, totals: totals()), on, gentle: true)!;
    expectNoRate(t.text);
    expect(t.text, contains('Distância'));
    final f = composer.compose(RecordingFinished(totals: totals()), on, gentle: true)!;
    expectNoRate(f.text);
    expect(f.text, startsWith('Corrida encerrada.'));
    expect(f.text, contains('Tempo'));
  });

  test('exemplo das Configuracoes respeita o Modo Gentil', () {
    expectNoRate(composer.sample(on, metric: true, gentle: true).text);
  });

  test('sem o Modo Gentil nada muda', () {
    expect(composer.compose(split, on)!.text, contains('Pace'));
  });
}
