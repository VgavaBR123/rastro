// Deteccao de eventos da gravacao para o Narrador (F03): compara fotos
// sucessivas do estado e devolve inicio, splits, voltas, marcas de tempo,
// pausas, retomada e fim.
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/narrator/domain/narration_event.dart';
import 'package:strava_estudo_app/narrator/domain/narration_event_detector.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';

NarrationSnapshot snap({
  RecordingState state = RecordingState.recording,
  double distance = 0,
  int timerMs = 0,
  List<int> splits = const [],
  List<LapMark> laps = const [],
  bool metric = true,
  ActivityType type = ActivityType.run,
}) => NarrationSnapshot(
  state: state,
  type: type,
  distanceMeters: distance,
  timerMs: timerMs,
  splitDurationsMs: splits,
  laps: laps,
  metric: metric,
);

void main() {
  late NarrationEventDetector d;
  setUp(() => d = NarrationEventDetector());

  test('primeira foto gravando do zero: inicio novo', () {
    final e = d.onSnapshot(snap());
    expect(e, hasLength(1));
    final started = e.single as RecordingStarted;
    expect(started.resumed, isFalse);
    expect(started.totals.type, ActivityType.run);
  });

  test('ocioso nao gera nada', () {
    expect(d.onSnapshot(snap(state: RecordingState.idle)), isEmpty);
  });

  test('retomada apos crash: anuncia retomada e nao repete splits antigos', () {
    final e = d.onSnapshot(snap(distance: 2500, timerMs: 800000, splits: [300000, 310000]));
    expect(e.single, isA<RecordingStarted>());
    expect((e.single as RecordingStarted).resumed, isTrue);
    expect(d.onSnapshot(snap(distance: 2600, timerMs: 830000, splits: [300000, 310000])), isEmpty);
  });

  test('split fechado traz o split e os anteriores', () {
    d.onSnapshot(snap());
    final e = d.onSnapshot(snap(distance: 1005, timerMs: 332000, splits: [332000]));
    final split = e.single as SplitClosed;
    expect(split.number, 1);
    expect(split.durationMs, 332000);
    expect(split.previousDurationsMs, isEmpty);
    expect(split.totals.distanceMeters, 1005);
    expect(split.totals.timerMs, 332000);
  });

  test('dois splits no mesmo update (sinal voltou): dois eventos em ordem', () {
    d.onSnapshot(snap(distance: 900, timerMs: 300000));
    final e = d.onSnapshot(snap(distance: 2100, timerMs: 700000, splits: [330000, 340000]));
    expect(e.map((x) => (x as SplitClosed).number), [1, 2]);
    expect((e[1] as SplitClosed).previousDurationsMs, [330000]);
  });

  test('volta fechada', () {
    d.onSnapshot(snap());
    const lap = LapMark(number: 1, durationMs: 80000, distanceMeters: 400);
    final e = d.onSnapshot(snap(distance: 400, timerMs: 80000, laps: [lap]));
    final closed = e.single as LapClosed;
    expect(closed.lap, lap);
    expect(closed.previous, isEmpty);
  });

  test('pausa automatica, manual e retomada', () {
    d.onSnapshot(snap());
    expect(d.onSnapshot(snap(state: RecordingState.autoPaused)).single, isA<AutoPaused>());
    final r = d.onSnapshot(snap()).single as Resumed;
    expect(r.fromAutoPause, isTrue);
    expect(d.onSnapshot(snap(state: RecordingState.manuallyPaused)).single, isA<ManuallyPaused>());
    expect((d.onSnapshot(snap()).single as Resumed).fromAutoPause, isFalse);
  });

  test('auto-pausa virando pausa manual anuncia a manual', () {
    d.onSnapshot(snap());
    d.onSnapshot(snap(state: RecordingState.autoPaused));
    expect(d.onSnapshot(snap(state: RecordingState.manuallyPaused)).single, isA<ManuallyPaused>());
  });

  test('marca de tempo a cada N minutos, so gravando', () {
    d.onSnapshot(snap(), timeEveryMinutes: 5);
    expect(d.onSnapshot(snap(timerMs: 299000), timeEveryMinutes: 5), isEmpty);
    final e = d.onSnapshot(snap(timerMs: 300400, distance: 1200), timeEveryMinutes: 5);
    final mark = e.single as TimeMark;
    expect(mark.markMs, 300000);
    expect(mark.totals.distanceMeters, 1200);
    // Nao repete a mesma marca.
    expect(d.onSnapshot(snap(timerMs: 301000), timeEveryMinutes: 5), isEmpty);
    // Pausado nao fala a marca; ao voltar, fala a que passou.
    expect(
      d.onSnapshot(snap(state: RecordingState.autoPaused, timerMs: 600100), timeEveryMinutes: 5),
      [isA<AutoPaused>()],
    );
    final back = d.onSnapshot(snap(timerMs: 600200), timeEveryMinutes: 5);
    expect(back.whereType<TimeMark>().single.markMs, 600000);
  });

  test('salto de varias marcas fala so a ultima', () {
    d.onSnapshot(snap(), timeEveryMinutes: 5);
    final e = d.onSnapshot(snap(timerMs: 1000000), timeEveryMinutes: 5);
    expect((e.single as TimeMark).markMs, 900000);
  });

  test('gatilho de tempo desligado nao gera marca', () {
    d.onSnapshot(snap());
    expect(d.onSnapshot(snap(timerMs: 3600000)), isEmpty);
  });

  test('ligar o gatilho de tempo no meio conta da proxima marca', () {
    d.onSnapshot(snap());
    d.onSnapshot(snap(timerMs: 620000));
    expect(d.onSnapshot(snap(timerMs: 630000), timeEveryMinutes: 10), isEmpty);
    expect(d.onSnapshot(snap(timerMs: 1200000), timeEveryMinutes: 10).single, isA<TimeMark>());
  });

  test('fim da gravacao com os totais', () {
    d.onSnapshot(snap());
    final e = d.onSnapshot(snap(state: RecordingState.finished, distance: 5000, timerMs: 1500000));
    final f = e.single as RecordingFinished;
    expect(f.totals.distanceMeters, 5000);
    // Nova gravacao depois do fim comeca do zero.
    expect(d.onSnapshot(snap()).single, isA<RecordingStarted>());
  });

  test('troca de unidade no meio nao despeja os splits da outra unidade', () {
    d.onSnapshot(snap(distance: 3300, timerMs: 900000, splits: [1, 2, 3]));
    expect(
      d.onSnapshot(snap(distance: 3300, timerMs: 900000, splits: [1, 2], metric: false)),
      isEmpty,
    );
  });

  test('reset volta ao estado inicial', () {
    d.onSnapshot(snap());
    d.reset();
    expect(d.onSnapshot(snap()).single, isA<RecordingStarted>());
  });
}
