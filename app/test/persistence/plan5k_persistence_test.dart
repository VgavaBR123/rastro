// Plano 5 km (F06) no banco: estado do plano, resultados das sessoes ligados
// a atividade, RPE lido da atividade, exclusao da atividade sem quebrar o
// plano, preferencia "Voz do plano" e a migracao 11 -> 12 sobre arquivo real.
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/plan5k/domain/plan_progress.dart';
import 'package:strava_estudo_app/plan5k/plan_repository.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';

Future<void> seed(RecordingDatabase db, String guid, {int? rpe}) => db.upsertActivity(
  ActivitiesCompanion.insert(
    guid: guid,
    activityType: ActivityType.run,
    startTimestampMs: 1000,
    isFinished: const Value(true),
    syncState: SyncState.pending,
    title: const Value('Titulo'),
    rpe: Value(rpe),
  ),
);

/// Banco que roda [afterRead] logo depois de o reconcile ler as sessoes: simula
/// o GuidedSessionController fechando a sessao no meio do reconcile.
class _RacyDb extends RecordingDatabase {
  Future<void> Function()? afterRead;
  _RacyDb() : super(NativeDatabase.memory());

  @override
  Future<List<({Plan5kSessionRow row, Activity? activity})>> plan5kSessionsWithActivity() async {
    final rows = await super.plan5kSessionsWithActivity();
    final hook = afterRead;
    afterRead = null;
    if (hook != null) await hook();
    return rows;
  }
}

void main() {
  test('corrida: o fechamento da sessao guiada vence o reconcile', () async {
    final db = _RacyDb();
    addTearDown(db.close);
    final repo = PlanRepository(db);
    await seed(db, 'act_1'); // ja finalizada (Encerrar pela notificacao)
    await repo.beginSession(week: 1, number: 1, round: 0, requiredMs: 1000, guid: 'act_1', nowMs: 1);
    await repo.saveProgress('act_1', movingMs: 10); // salvo ha pouco: daria parcial
    db.afterRead = () =>
        repo.finishSession('act_1', movingMs: 1000, status: SessionStatus.done, nowMs: 2);
    await repo.reconcile(activeGuid: null, nowMs: 3);
    final r = (await repo.results()).single;
    expect(r.status, SessionStatus.done);
    expect(r.movingMs, 1000);
  });

  group('em memoria', () {
    late RecordingDatabase db;
    late PlanRepository repo;
    setUp(() {
      db = RecordingDatabase(NativeDatabase.memory());
      repo = PlanRepository(db);
    });
    tearDown(() => db.close());

    test('schema na versao 12', () => expect(db.schemaVersion, 12));

    test('plano nasce sem comecar; comecar, mudar e reiniciar', () async {
      expect((await repo.loadState()).started, isFalse);
      await repo.saveState(const PlanState(started: true, startWeek: 3, currentWeek: 3));
      var s = await repo.loadState();
      expect(s.started, isTrue);
      expect(s.startWeek, 3);
      await repo.saveState(s.repeatWeek());
      s = await repo.loadState();
      expect(s.repeatsOf(3), 1);
      await repo.saveState(s.advanceWeek());
      expect((await repo.loadState()).currentWeek, 4);

      final id = await repo.beginSession(week: 4, number: 1, round: 0, requiredMs: 100, guid: 'a', nowMs: 1);
      expect(id, isPositive);
      await repo.reset();
      expect((await repo.loadState()).started, isFalse);
      expect(await repo.results(), isEmpty);
    });

    test('sessao ligada a atividade: em andamento, depois concluida com o RPE da atividade', () async {
      await seed(db, 'act_1', rpe: 9);
      await repo.beginSession(week: 1, number: 1, round: 0, requiredMs: 1000, guid: 'act_1', nowMs: 5);
      var rs = await repo.results();
      expect(rs.single.status, SessionStatus.inProgress);
      expect(rs.single.activityGuid, 'act_1');
      expect((await repo.sessionForGuid('act_1'))!.number, 1);
      expect(await repo.sessionForGuid('outra'), isNull);

      await repo.finishSession('act_1', movingMs: 950, status: SessionStatus.done, nowMs: 9);
      rs = await repo.results();
      expect(rs.single.status, SessionStatus.done);
      expect(rs.single.movingMs, 950);
      expect(rs.single.rpe, 9);
    });

    test('excluir a atividade de uma sessao concluida: a sessao continua concluida', () async {
      await seed(db, 'act_1', rpe: 9);
      await repo.beginSession(week: 1, number: 1, round: 0, requiredMs: 1000, guid: 'act_1', nowMs: 5);
      await repo.finishSession('act_1', movingMs: 1000, status: SessionStatus.done, nowMs: 9);
      await db.deleteActivity('act_1', nowMs: 10);
      final r = (await repo.results()).single;
      expect(r.status, SessionStatus.done);
      // Sem a atividade nao ha mais RPE: nao pesa na regra de repeticao.
      expect(r.rpe, isNull);
    });

    test('descartar a gravacao apaga a sessao ligada', () async {
      await repo.beginSession(week: 1, number: 1, round: 0, requiredMs: 1000, guid: 'act_1', nowMs: 5);
      await repo.discardSession('act_1');
      expect(await repo.results(), isEmpty);
    });

    test('tempo de plano salvo durante a sessao (para a retomada)', () async {
      await repo.beginSession(week: 1, number: 2, round: 0, requiredMs: 1000, guid: 'act_1', nowMs: 5);
      await repo.saveProgress('act_1', movingMs: 420);
      expect((await repo.sessionForGuid('act_1'))!.movingMs, 420);
    });

    test('sessao em andamento sem gravacao aberta: fecha pela atividade ou some', () async {
      await seed(db, 'fim'); // finalizada (ex.: "Salvar e encerrar" da recuperacao)
      await repo.beginSession(week: 1, number: 1, round: 0, requiredMs: 1000, guid: 'fim', nowMs: 1);
      await repo.saveProgress('fim', movingMs: 300);
      await repo.beginSession(week: 1, number: 2, round: 0, requiredMs: 1000, guid: 'sumiu', nowMs: 2);
      await repo.saveProgress('sumiu', movingMs: 950);
      await repo.beginSession(week: 1, number: 3, round: 0, requiredMs: 1000, guid: 'aberta', nowMs: 3);
      await db.upsertActivity(ActivitiesCompanion.insert(
        guid: 'aberta',
        activityType: ActivityType.run,
        startTimestampMs: 1,
        syncState: SyncState.pending,
      ));
      await repo.reconcile(activeGuid: null, nowMs: 50);
      final byGuid = {for (final r in await repo.results()) r.activityGuid: r.status};
      expect(byGuid['fim'], SessionStatus.partial);
      // Atividade em andamento que sumiu = descartada na recuperacao: nao conta.
      expect(byGuid.containsKey('sumiu'), isFalse);
      // Gravacao interrompida ainda recuperavel: fica em andamento.
      expect(byGuid['aberta'], SessionStatus.inProgress);
    });

    test('voz do plano: padrao ligada, independente do narrador', () async {
      final row = await db.loadSettings();
      expect(row.plan5kVoice, isTrue);
      await db.saveSettings(plan5kVoice: false);
      expect((await db.loadSettings()).plan5kVoice, isFalse);
      expect((await db.loadSettings()).narratorPrefs, isNull);
    });
  });

  test('migracao 11 -> 12 cria o plano sem perder dados', () async {
    final dir = Directory.systemTemp.createTempSync('rastro_mig12');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/rec.sqlite');

    var fileDb = RecordingDatabase(NativeDatabase(file));
    await seed(fileDb, 'old', rpe: 6);
    await fileDb.saveSettings(useMetric: false, gentleMode: true);
    await fileDb.markChapterMonthSeen(202610);
    await fileDb.close();

    fileDb = RecordingDatabase(
      NativeDatabase(
        file,
        setup: (raw) {
          final v = raw.select('PRAGMA user_version').first.values.first;
          if (v != 12) return;
          raw.execute('DROP TABLE plan5k_states');
          raw.execute('DROP TABLE plan5k_sessions');
          raw.execute('ALTER TABLE settings_rows DROP COLUMN plan5k_voice');
          raw.execute('PRAGMA user_version = 11');
        },
      ),
    );
    addTearDown(fileDb.close);

    final rows = await fileDb.finishedActivitiesAscending();
    expect(rows.single.guid, 'old');
    expect(rows.single.rpe, 6);
    final settings = await fileDb.loadSettings();
    expect(settings.useMetric, isFalse);
    expect(settings.gentleMode, isTrue);
    expect(settings.chapterMonthSeen, 202610);
    expect(settings.plan5kVoice, isTrue);

    final repo = PlanRepository(fileDb);
    expect((await repo.loadState()).started, isFalse);
    await repo.saveState(const PlanState(started: true));
    await repo.beginSession(week: 1, number: 1, round: 0, requiredMs: 1, guid: 'old', nowMs: 1);
    expect((await repo.results()).single.rpe, 6);
  });
}
