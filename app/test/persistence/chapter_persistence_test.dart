// Capitulos (F05) no banco: o ultimo mes cujo capitulo foi visto ou
// dispensado (cartao do Inicio), as atividades lidas para o capitulo e a
// migracao 10 -> 11 sobre arquivo real.
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';

Future<void> seed(RecordingDatabase db, String guid, {bool finished = true, int start = 1000}) =>
    db.upsertActivity(
      ActivitiesCompanion.insert(
        guid: guid,
        activityType: ActivityType.run,
        startTimestampMs: start,
        timerTimeMs: const Value(60000),
        distanceMeters: const Value(1000),
        isFinished: Value(finished),
        syncState: SyncState.pending,
        title: const Value('Titulo'),
      ),
    );

void main() {
  group('em memoria', () {
    late RecordingDatabase db;
    setUp(() => db = RecordingDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('schema na versao 11', () => expect(db.schemaVersion, greaterThanOrEqualTo(11)));

    test('ultimo capitulo visto: padrao null e so avanca', () async {
      expect(await db.chapterMonthSeen(), isNull);
      await db.markChapterMonthSeen(202610);
      expect(await db.chapterMonthSeen(), 202610);
      // Abrir um capitulo antigo pela lista nao faz o cartao voltar.
      await db.markChapterMonthSeen(202605);
      expect(await db.chapterMonthSeen(), 202610);
      await db.markChapterMonthSeen(202611);
      expect(await db.chapterMonthSeen(), 202611);
    });

    test('marcar o capitulo nao mexe nas outras configuracoes', () async {
      await db.saveSettings(useMetric: false, gentleMode: true);
      await db.markChapterMonthSeen(202610);
      final row = await db.loadSettings();
      expect(row.useMetric, isFalse);
      expect(row.gentleMode, isTrue);
    });

    test('atividades do capitulo: so as finalizadas, em ordem de inicio', () async {
      await seed(db, 'b', start: 5000);
      await seed(db, 'a', start: 1000);
      await seed(db, 'aberta', finished: false, start: 3000);
      final rows = await db.finishedActivitiesAscending();
      expect(rows.map((a) => a.guid), ['a', 'b']);
    });
  });

  test('migracao 10 -> 11 cria o ultimo capitulo visto sem perder dados', () async {
    final dir = Directory.systemTemp.createTempSync('rastro_mig11');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/rec.sqlite');

    var fileDb = RecordingDatabase(NativeDatabase(file));
    await seed(fileDb, 'old');
    await fileDb.saveSettings(useMetric: false, gentleMode: true);
    await fileDb.close();

    fileDb = RecordingDatabase(
      NativeDatabase(
        file,
        setup: (raw) {
          final v = raw.select('PRAGMA user_version').first.values.first;
          if (v != 14) return;
          raw.execute('DROP TABLE safety_local_sessions');
          raw.execute('ALTER TABLE activities DROP COLUMN import_source');
          raw.execute('DROP TABLE plan5k_states');
          raw.execute('DROP TABLE plan5k_sessions');
          raw.execute('ALTER TABLE settings_rows DROP COLUMN plan5k_voice');
          raw.execute('ALTER TABLE settings_rows DROP COLUMN chapter_month_seen');
          raw.execute('PRAGMA user_version = 10');
        },
      ),
    );
    addTearDown(fileDb.close);

    final rows = await fileDb.finishedActivitiesAscending();
    expect(rows.single.guid, 'old');
    expect(rows.single.title, 'Titulo');
    final settings = await fileDb.loadSettings();
    expect(settings.useMetric, isFalse);
    expect(settings.gentleMode, isTrue);
    expect(await fileDb.chapterMonthSeen(), isNull);
    await fileDb.markChapterMonthSeen(202610);
    expect(await fileDb.chapterMonthSeen(), 202610);
  });
}
