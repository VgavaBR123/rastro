// Capitulos (F05): o "dia atual" dos capitulos muda sem recriar os providers
// (Inicio e Estatisticas ficam vivos no shell). Vira na meia-noite local por
// um Timer e e relido quando o app volta do segundo plano. Cartao, lista e
// sequencia acompanham, e a lista/sequencia usam o mesmo "agora".
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/auth/session_store.dart';
import 'package:strava_estudo_app/chapters/chapter_providers.dart';
import 'package:strava_estudo_app/chapters/domain/period.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';

Future<void> seed(RecordingDatabase db, String guid, DateTime start) => db.upsertActivity(
  ActivitiesCompanion.insert(
    guid: guid,
    activityType: ActivityType.run,
    startTimestampMs: start.millisecondsSinceEpoch,
    timerTimeMs: const Value(1800000),
    distanceMeters: const Value(5000),
    isFinished: const Value(true),
    syncState: SyncState.pending,
  ),
);

/// Timer falso: guarda o atraso e o callback para o teste disparar.
class FakeDayTimers {
  final List<Duration> delays = [];
  final List<void Function()> callbacks = [];
  int cancelled = 0;

  CancelTimer schedule(Duration delay, void Function() onFire) {
    delays.add(delay);
    callbacks.add(onFire);
    return () => cancelled++;
  }

  void fireLast() => callbacks.last();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RecordingDatabase db;
  late ProviderContainer container;
  late DateTime clock;
  late FakeDayTimers timers;

  setUp(() {
    db = RecordingDatabase(NativeDatabase.memory());
    timers = FakeDayTimers();
    clock = DateTime(2026, 10, 31, 22, 30);
    container = ProviderContainer(overrides: [
      recordingDatabaseProvider.overrideWithValue(db),
      sessionStoreProvider.overrideWithValue(InMemorySessionStore()),
      chapterClockProvider.overrideWithValue(() => clock),
      chapterDayTimerProvider.overrideWithValue(timers.schedule),
    ]);
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('agenda a virada para a proxima meia-noite local e cancela no dispose', () {
    final sub = container.listen(chapterTodayProvider, (_, _) {});
    expect(container.read(chapterTodayProvider), DateTime(2026, 10, 31));
    expect(timers.delays.single, DateTime(2026, 11, 1).difference(clock));
    sub.close();
    container.dispose();
    expect(timers.cancelled, greaterThanOrEqualTo(1));
    container = ProviderContainer();
  });

  test('meia-noite: o cartao de outubro aparece sem recriar o container', () async {
    await seed(db, 'a', DateTime(2026, 10, 5, 7));
    final sub = container.listen(homeChapterProvider, (_, _) {});
    addTearDown(sub.close);
    expect(await container.read(homeChapterProvider.future), isNull);

    clock = DateTime(2026, 11, 1, 0, 0, 1);
    timers.fireLast();
    expect(container.read(chapterTodayProvider), DateTime(2026, 11, 1));
    expect(await container.read(homeChapterProvider.future), const MonthKey(2026, 10));
    // E agenda a proxima virada.
    expect(timers.delays.last, DateTime(2026, 11, 2).difference(clock));
  });

  test('ano novo: a lista ganha o ano e o anterior deixa de ser "ate agora"', () async {
    await seed(db, 'a', DateTime(2026, 10, 5, 7));
    clock = DateTime(2026, 12, 31, 23);
    final sub = container.listen(chaptersOverviewProvider, (_, _) {});
    addTearDown(sub.close);
    var o = await container.read(chaptersOverviewProvider.future);
    expect(o.years.map((y) => y.label), ['2026 ate agora']);

    clock = DateTime(2027, 1, 1, 0, 5);
    timers.fireLast();
    o = await container.read(chaptersOverviewProvider.future);
    expect(o.years.map((y) => y.label), ['2027 ate agora', '2026']);
    expect(o.referenceMonth, const MonthKey(2027, 1));
    expect(o.jokerLabel, 'Coringa de janeiro: disponivel');
  });

  test('segunda-feira: a semana passada fecha e a sequencia usa o novo dia', () async {
    // Ativas nas semanas de 12/10 e 19/10; a de 26/10 vazia.
    await seed(db, 'a', DateTime(2026, 10, 14, 7));
    await seed(db, 'b', DateTime(2026, 10, 21, 7));
    clock = DateTime(2026, 11, 1, 20); // domingo: 26/10 ainda e a corrente
    final sub = container.listen(chaptersOverviewProvider, (_, _) {});
    addTearDown(sub.close);
    var o = await container.read(chaptersOverviewProvider.future);
    expect(o.streak.current, 2);
    expect(o.jokerLabel, 'Coringa de novembro: disponivel');

    // Segunda 2/11: a semana de 26/10 fechou vazia e gastou o coringa de outubro.
    clock = DateTime(2026, 11, 2, 0, 1);
    timers.fireLast();
    o = await container.read(chaptersOverviewProvider.future);
    expect(o.streak.coveredMondays, [DateTime(2026, 10, 26)]);
    expect(o.streak.current, 2);
    expect((await container.read(currentStreakProvider.future)).coveredMondays, [DateTime(2026, 10, 26)]);
  });

  test('mesmo dia: o timer nao troca o estado a toa', () {
    final values = <DateTime>[];
    final sub = container.listen(chapterTodayProvider, (_, next) => values.add(next));
    addTearDown(sub.close);
    clock = DateTime(2026, 10, 31, 23, 59);
    timers.fireLast();
    expect(values, isEmpty);
  });
}
