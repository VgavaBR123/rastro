// Capitulos (F05): providers que leem o banco local e aplicam o dominio.
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

Future<void> seed(RecordingDatabase db, String guid, DateTime start, {bool finished = true}) =>
    db.upsertActivity(
      ActivitiesCompanion.insert(
        guid: guid,
        activityType: ActivityType.run,
        startTimestampMs: start.millisecondsSinceEpoch,
        timerTimeMs: const Value(1800000),
        distanceMeters: const Value(5000),
        isFinished: Value(finished),
        syncState: SyncState.pending,
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RecordingDatabase db;
  late ProviderContainer container;
  final now = DateTime(2026, 11, 2, 9);

  setUp(() {
    db = RecordingDatabase(NativeDatabase.memory());
    container = ProviderContainer(overrides: [
      recordingDatabaseProvider.overrideWithValue(db),
      sessionStoreProvider.overrideWithValue(InMemorySessionStore()),
      chapterClockProvider.overrideWithValue(() => now),
    ]);
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('cartao do Inicio: mes anterior ate marcar como visto', () async {
    await seed(db, 'a', DateTime(2026, 10, 5, 7));
    final sub = container.listen(homeChapterProvider, (_, _) {});
    addTearDown(sub.close);
    expect(await container.read(homeChapterProvider.future), const MonthKey(2026, 10));

    await container.read(chapterSeenMarkerProvider).markSeen(const MonthKey(2026, 10));
    expect(await container.read(homeChapterProvider.future), isNull);
  });

  test('cartao do Inicio: app novo sem atividade nao mostra', () async {
    await seed(db, 'a', DateTime(2026, 11, 1, 7));
    expect(await container.read(homeChapterProvider.future), isNull);
  });

  test('capitulo do mes e indice a partir do banco; nao finalizada fica de fora', () async {
    await seed(db, 'a', DateTime(2026, 10, 5, 7));
    await seed(db, 'b', DateTime(2026, 8, 5, 7));
    await seed(db, 'x', DateTime(2026, 9, 5, 7), finished: false);
    final c = await container.read(monthChapterProvider(const MonthKey(2026, 10)).future);
    expect(c.totals.count, 1);
    final index = await container.read(chapterIndexProvider.future);
    expect(index.months, [const MonthKey(2026, 10), const MonthKey(2026, 8)]);
    expect(index.years, [2026]);
    final y = await container.read(yearChapterProvider(2026).future);
    expect(y.totals.count, 2);
    expect(y.partial, isTrue);
  });

  test('sequencia de agora para o resumo das Estatisticas', () async {
    await seed(db, 'a', DateTime(2026, 10, 21, 7));
    await seed(db, 'b', DateTime(2026, 10, 28, 7));
    final s = await container.read(currentStreakProvider.future);
    expect(s.current, 2);
    expect(s.jokerAvailable(MonthKey.of(now)), isTrue);
  });
}
