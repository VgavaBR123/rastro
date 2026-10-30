// Fechamento gentil (F04) no banco: RPE e humor da atividade, Modo Gentil nas
// configuracoes, frases a partir do historico salvo e migracao 9 -> 10 sobre
// arquivo real.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/closing/closing_service.dart';
import 'package:strava_estudo_app/closing/domain/effort.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/persistence/recording_repository.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/domain/waypoint.dart' as dom;
import 'package:strava_estudo_app/settings/settings_controller.dart';

const int _dayMs = 24 * 60 * 60 * 1000;

/// Atividade finalizada em linha reta, [meters] em [seconds] (ritmo constante).
Future<void> seed(
  RecordingRepository repo,
  String guid, {
  required int startMs,
  double meters = 5000,
  int seconds = 1800,
  ActivityType type = ActivityType.run,
}) async {
  await repo.startActivity(guid: guid, type: type, startTimestampMs: startMs);
  const n = 60;
  await repo.appendWaypoints(guid, [
    for (var i = 0; i <= n; i++)
      dom.Waypoint(
        position: GeoPoint(latitude: 0, longitude: i * 0.0001),
        cumulativeDistanceMeters: meters * i / n,
        elapsedTimeMs: seconds * 1000 * i ~/ n,
        timerTimeMs: seconds * 1000 * i ~/ n,
        classification: dom.WaypointClassification.accept,
      ),
  ]);
  await repo.finish(
    guid,
    startMs + seconds * 1000,
    distanceMeters: meters,
    timerTimeMs: seconds * 1000,
  );
}

void main() {
  group('em memoria', () {
    late RecordingDatabase db;
    late RecordingRepository repo;
    setUp(() {
      db = RecordingDatabase(NativeDatabase.memory());
      repo = RecordingRepository(db);
    });
    tearDown(() => db.close());

    test('schema na versao 10', () => expect(db.schemaVersion, 10));

    test('RPE e humor sao opcionais e ficam na atividade', () async {
      await seed(repo, 'a', startMs: 1000);
      final before = (await repo.activity('a'))!;
      expect(before.rpe, isNull);
      expect(before.mood, isNull);

      await repo.saveDetails('a', rpe: 7, mood: Mood.tired);
      final after = (await repo.activity('a'))!;
      expect(after.rpe, 7);
      expect(Mood.fromDb(after.mood), Mood.tired);
    });

    test('RPE fora de 1 a 10 vira null', () async {
      await seed(repo, 'a', startMs: 1000);
      await repo.saveDetails('a', rpe: 14);
      expect((await repo.activity('a'))!.rpe, isNull);
    });

    test('Modo Gentil: padrao desligado e persiste pelo controller', () async {
      final c1 = SettingsController(db);
      await c1.load();
      expect(c1.state.gentleMode, isFalse);
      await c1.setGentleMode(true);
      await c1.setUseMetric(false);
      final c2 = SettingsController(db);
      await c2.load();
      expect(c2.state.gentleMode, isTrue);
      expect(c2.state.useMetric, isFalse);
    });

    test('frases do fechamento a partir do historico salvo', () async {
      final now = DateTime(2026, 10, 22, 7).millisecondsSinceEpoch;
      await seed(repo, 'old1', startMs: now - 3 * _dayMs, meters: 5000);
      await seed(repo, 'old2', startMs: now - 10 * _dayMs, meters: 8000, seconds: 3000);
      await seed(repo, 'now', startMs: now, meters: 9000, seconds: 3000);
      final service = ClosingService(repo);
      final out = await service.phrasesFor('now', gentle: false, metric: true);
      expect(out, contains('Sua corrida mais longa das ultimas 4 semanas.'));
      expect(out.length, inInclusiveRange(2, 3));
    });

    test('constancia usa os splits gravados', () async {
      final now = DateTime(2026, 10, 22, 7).millisecondsSinceEpoch;
      // Antiga com ritmo irregular: primeira metade rapida, segunda lenta.
      await repo.startActivity(guid: 'irr', type: ActivityType.run, startTimestampMs: now - 2 * _dayMs);
      await repo.appendWaypoints('irr', [
        for (var i = 0; i <= 40; i++)
          dom.Waypoint(
            position: GeoPoint(latitude: 0, longitude: i * 0.0001),
            cumulativeDistanceMeters: i * 100.0,
            elapsedTimeMs: (i <= 20 ? i * 25 : 500 + (i - 20) * 40) * 1000,
            timerTimeMs: (i <= 20 ? i * 25 : 500 + (i - 20) * 40) * 1000,
            classification: dom.WaypointClassification.accept,
          ),
      ]);
      await repo.finish('irr', now - 2 * _dayMs + 1300000, distanceMeters: 4000, timerTimeMs: 1300000);
      await seed(repo, 'now', startMs: now, meters: 4000, seconds: 1400);
      final out = await ClosingService(repo).phrasesFor('now', gentle: false, metric: true);
      expect(out, contains('Seu ritmo mais constante das ultimas 4 semanas.'));
    });

    test('atividade inexistente: sem frases', () async {
      expect(await ClosingService(repo).phrasesFor('x', gentle: false, metric: true), isEmpty);
    });
  });

  test('migracao 9 -> 10 cria RPE, humor e Modo Gentil sem perder dados', () async {
    final dir = Directory.systemTemp.createTempSync('rastro_mig10');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/rec.sqlite');

    var fileDb = RecordingDatabase(NativeDatabase(file));
    var repo = RecordingRepository(fileDb);
    await seed(repo, 'old', startMs: 5);
    await repo.saveDetails('old', title: 'Antiga');
    await fileDb.saveSettings(useMetric: false);
    await fileDb.close();

    fileDb = RecordingDatabase(
      NativeDatabase(
        file,
        setup: (raw) {
          final v = raw.select('PRAGMA user_version').first.values.first;
          if (v != 10) return;
          raw.execute('ALTER TABLE activities DROP COLUMN rpe');
          raw.execute('ALTER TABLE activities DROP COLUMN mood');
          raw.execute('ALTER TABLE settings_rows DROP COLUMN gentle_mode');
          raw.execute('PRAGMA user_version = 9');
        },
      ),
    );
    addTearDown(fileDb.close);
    repo = RecordingRepository(fileDb);

    final old = (await repo.activity('old'))!;
    expect(old.title, 'Antiga');
    expect(old.rpe, isNull);
    expect(old.mood, isNull);
    final settings = await fileDb.loadSettings();
    expect(settings.useMetric, isFalse);
    expect(settings.gentleMode, isFalse);

    await repo.saveDetails('old', title: 'Antiga', rpe: 4, mood: Mood.good);
    expect((await repo.activity('old'))!.rpe, 4);
  });
}
