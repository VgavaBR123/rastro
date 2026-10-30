// Frases do Narrador (F03): texto natural em portugues por evento, conforme
// as preferencias (gatilhos, conteudo, so o essencial) e o esporte.
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/narrator/domain/announcement.dart';
import 'package:strava_estudo_app/narrator/domain/narration_composer.dart';
import 'package:strava_estudo_app/narrator/domain/narration_event.dart';
import 'package:strava_estudo_app/narrator/domain/narrator_settings.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';

NarrationTotals totals({
  double distance = 1000,
  int timerMs = 332000,
  ActivityType type = ActivityType.run,
  bool metric = true,
}) => NarrationTotals(
  type: type,
  distanceMeters: distance,
  timerMs: timerMs,
  metric: metric,
);

void main() {
  const on = NarratorSettings(enabled: true);
  const composer = NarrationComposer();

  group('split', () {
    test('primeiro km: exemplo do spec (sem pace medio repetido)', () {
      final a = composer.compose(
        SplitClosed(number: 1, durationMs: 332000, previousDurationsMs: const [], totals: totals()),
        on,
      )!;
      expect(
        a.text,
        'Um quilômetro. Tempo cinco minutos e trinta e dois segundos. '
        'Pace do quilômetro cinco e trinta e dois.',
      );
      expect(a.priority, AnnouncementPriority.normal);
    });

    test('segundo km com pace medio e km mais rapido ate agora', () {
      final a = composer.compose(
        SplitClosed(
          number: 2,
          durationMs: 320000,
          previousDurationsMs: const [332000],
          totals: totals(distance: 2000, timerMs: 652000),
        ),
        on,
      )!;
      expect(
        a.text,
        'Dois quilômetros. Tempo dez minutos e cinquenta e dois segundos. '
        'Pace médio cinco e vinte e seis. Pace do quilômetro cinco e vinte. '
        'Seu quilômetro mais rápido até agora.',
      );
    });

    test('mais rapido que o anterior, mas nao o melhor', () {
      final a = composer.compose(
        SplitClosed(
          number: 3,
          durationMs: 310000,
          previousDurationsMs: const [300000, 320000],
          totals: totals(distance: 3000, timerMs: 930000),
        ),
        on.copyWith(sayTime: false, sayAvgPace: false, saySplitPace: false),
      )!;
      expect(a.text, 'Três quilômetros. Dez segundos mais rápido que o anterior.');
    });

    test('sem frases de contexto', () {
      final a = composer.compose(
        SplitClosed(
          number: 2,
          durationMs: 300000,
          previousDurationsMs: const [332000],
          totals: totals(distance: 2000, timerMs: 632000),
        ),
        on.copyWith(contextPhrases: false, sayTime: false, sayAvgPace: false),
      )!;
      expect(a.text, 'Dois quilômetros. Pace do quilômetro cinco minutos.');
    });

    test('so o essencial: marca e pace do split', () {
      final a = composer.compose(
        SplitClosed(
          number: 2,
          durationMs: 320000,
          previousDurationsMs: const [332000],
          totals: totals(distance: 2000, timerMs: 652000),
        ),
        on.copyWith(essentialOnly: true),
      )!;
      expect(a.text, 'Dois quilômetros. Pace cinco e vinte.');
    });

    test('milha no feminino', () {
      final a = composer.compose(
        SplitClosed(
          number: 1,
          durationMs: 480000,
          previousDurationsMs: const [],
          totals: totals(distance: 1609.344, timerMs: 480000, metric: false),
        ),
        on.copyWith(sayTime: false),
      )!;
      expect(a.text, 'Uma milha. Pace da milha oito minutos.');
    });

    test('pedal fala velocidade em vez de pace', () {
      final a = composer.compose(
        SplitClosed(
          number: 2,
          durationMs: 120000,
          previousDurationsMs: const [150000],
          totals: totals(distance: 2000, timerMs: 270000, type: ActivityType.ride),
        ),
        on.copyWith(sayTime: false, contextPhrases: false),
      )!;
      expect(
        a.text,
        'Dois quilômetros. Velocidade média vinte e seis vírgula sete quilômetros por hora. '
        'Velocidade no quilômetro trinta quilômetros por hora.',
      );
    });

    test('gatilho de distancia desligado silencia o split', () {
      final e = SplitClosed(number: 1, durationMs: 1, previousDurationsMs: const [], totals: totals());
      expect(composer.compose(e, on.copyWith(distanceTrigger: false)), isNull);
    });

    test('a cada 5 km fala so os multiplos', () {
      SplitClosed e(int n) => SplitClosed(
        number: n,
        durationMs: 300000,
        previousDurationsMs: List.filled(n - 1, 300000),
        totals: totals(distance: n * 1000.0, timerMs: n * 300000),
      );
      final s = on.copyWith(distanceEvery: 5);
      expect(composer.compose(e(4), s), isNull);
      expect(composer.compose(e(5), s)!.text, startsWith('Cinco quilômetros.'));
    });
  });

  group('volta', () {
    test('volta com tempo, distancia, pace e melhor volta', () {
      final a = composer.compose(
        LapClosed(
          lap: const LapMark(number: 2, durationMs: 80000, distanceMeters: 400),
          previous: const [LapMark(number: 1, durationMs: 90000, distanceMeters: 400)],
          totals: totals(distance: 800, timerMs: 170000),
        ),
        on,
      )!;
      expect(
        a.text,
        'Volta dois. Tempo da volta um minuto e vinte segundos. '
        'Distância da volta quatrocentos metros. Pace da volta três e vinte. '
        'Sua volta mais rápida até agora.',
      );
    });

    test('so o essencial', () {
      final a = composer.compose(
        LapClosed(
          lap: const LapMark(number: 1, durationMs: 80000, distanceMeters: 400),
          previous: const [],
          totals: totals(),
        ),
        on.copyWith(essentialOnly: true),
      )!;
      expect(a.text, 'Volta um. Um minuto e vinte segundos.');
    });

    test('gatilho de volta desligado', () {
      final e = LapClosed(
        lap: const LapMark(number: 1, durationMs: 1, distanceMeters: 1),
        previous: const [],
        totals: totals(),
      );
      expect(composer.compose(e, on.copyWith(lapTrigger: false)), isNull);
    });
  });

  group('tempo', () {
    test('marca de tempo com distancia e pace medio, prioridade baixa', () {
      final a = composer.compose(
        TimeMark(markMs: 1800000, totals: totals(distance: 5200, timerMs: 1800500)),
        on,
      )!;
      expect(
        a.text,
        'Trinta minutos. Distância cinco vírgula dois quilômetros. '
        'Pace médio cinco e quarenta e seis.',
      );
      expect(a.priority, AnnouncementPriority.low);
      expect(a.maxAgeMs, isNotNull);
    });

    test('so o essencial', () {
      final a = composer.compose(
        TimeMark(markMs: 600000, totals: totals(distance: 2000, timerMs: 600000)),
        on.copyWith(essentialOnly: true),
      )!;
      expect(a.text, 'Dez minutos. Dois quilômetros.');
    });
  });

  group('estado', () {
    test('inicio por esporte e retomada apos crash', () {
      String t(ActivityType type, {bool resumed = false}) => composer
          .compose(RecordingStarted(resumed: resumed, totals: totals(type: type)), on)!
          .text;
      expect(t(ActivityType.run), 'Corrida iniciada.');
      expect(t(ActivityType.ride), 'Pedal iniciado.');
      expect(t(ActivityType.walk), 'Caminhada iniciada.');
      expect(t(ActivityType.run, resumed: true), 'Gravação retomada.');
    });

    test('pausas e retomada sao prioridade alta e se substituem', () {
      final p = composer.compose(AutoPaused(totals: totals()), on)!;
      expect(p.text, 'Pausa automática.');
      expect(p.priority, AnnouncementPriority.high);
      final m = composer.compose(ManuallyPaused(totals: totals()), on)!;
      expect(m.text, 'Gravação pausada.');
      final r = composer.compose(Resumed(fromAutoPause: true, totals: totals()), on)!;
      expect(r.text, 'Gravação retomada.');
      expect({p.key, m.key, r.key}, hasLength(1));
    });

    test('fim com resumo', () {
      final a = composer.compose(
        RecordingFinished(totals: totals(distance: 5000, timerMs: 1500000)),
        on,
      )!;
      expect(
        a.text,
        'Corrida encerrada. Distância cinco quilômetros. Tempo vinte e cinco minutos. '
        'Pace médio cinco minutos.',
      );
      expect(a.priority, AnnouncementPriority.high);
    });

    test('fim no essencial', () {
      final a = composer.compose(
        RecordingFinished(totals: totals(distance: 5000, timerMs: 1500000)),
        on.copyWith(essentialOnly: true),
      )!;
      expect(a.text, 'Corrida encerrada. Cinco quilômetros em vinte e cinco minutos.');
    });

    test('anuncios de estado desligados', () {
      final s = on.copyWith(statusAnnouncements: false);
      expect(composer.compose(AutoPaused(totals: totals()), s), isNull);
      expect(composer.compose(RecordingStarted(resumed: false, totals: totals()), s), isNull);
      expect(composer.compose(RecordingFinished(totals: totals()), s), isNull);
    });
  });

  test('exemplo para o botao ouvir exemplo segue as preferencias', () {
    final full = composer.sample(on, metric: true);
    expect(full.text, startsWith('Dois quilômetros.'));
    expect(full.text, contains('Pace do quilômetro'));
    final essential = composer.sample(on.copyWith(essentialOnly: true), metric: false);
    expect(essential.text, startsWith('Duas milhas.'));
    // Chave propria: trocar o exemplo nao mexe num split real na fila.
    expect(full.key, NarrationKeys.sample);
    expect(full.key, isNot(NarrationKeys.split));
  });
}
