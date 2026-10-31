// Seus dados (F07) no banco: a origem da atividade importada (formato do
// arquivo) e a migracao 12 -> 13 sobre arquivo real, sem perda de dados.
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';

Future<void> seed(RecordingDatabase db, String guid, {String? importSource}) =>
    db.upsertActivity(
      ActivitiesCompanion.insert(
        guid: guid,
        activityType: ActivityType.ride,
        startTimestampMs: 5000,
        isFinished: const Value(true),
        syncState: SyncState.pending,
        title: const Value('Pedal antigo'),
        importSource: Value(importSource),
      ),
    );

void main() {
  test('schema na versao 14', () async {
    final db = RecordingDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect(db.schemaVersion, 14);
  });

  test('atividade gravada no app nao tem origem; importada guarda o formato', () async {
    final db = RecordingDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await seed(db, 'app');
    await seed(db, 'imp', importSource: 'gpx');
    final rows = await db.finishedActivitiesAscending();
    expect(rows.firstWhere((a) => a.guid == 'app').importSource, isNull);
    expect(rows.firstWhere((a) => a.guid == 'imp').importSource, 'gpx');
  });

  test('migracao 12 -> 13 cria a origem sem perder dados', () async {
    final dir = Directory.systemTemp.createTempSync('rastro_mig13');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/rec.sqlite');

    var fileDb = RecordingDatabase(NativeDatabase(file));
    await seed(fileDb, 'old');
    await fileDb.saveSettings(useMetric: false, plan5kVoice: false);
    await fileDb.close();

    fileDb = RecordingDatabase(
      NativeDatabase(
        file,
        setup: (raw) {
          final v = raw.select('PRAGMA user_version').first.values.first;
          if (v != 14) return;
          raw.execute('DROP TABLE safety_local_sessions');
          raw.execute('ALTER TABLE activities DROP COLUMN import_source');
          raw.execute('PRAGMA user_version = 12');
        },
      ),
    );
    addTearDown(fileDb.close);

    final rows = await fileDb.finishedActivitiesAscending();
    expect(rows.single.guid, 'old');
    expect(rows.single.title, 'Pedal antigo');
    expect(rows.single.importSource, isNull);
    final settings = await fileDb.loadSettings();
    expect(settings.useMetric, isFalse);
    expect(settings.plan5kVoice, isFalse);

    // A coluna nova funciona depois da migracao.
    await seed(fileDb, 'novo', importSource: 'fit');
    final again = await fileDb.finishedActivitiesAscending();
    expect(again.firstWhere((a) => a.guid == 'novo').importSource, 'fit');
  });
}
