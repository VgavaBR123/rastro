// Seus dados (F07): gravar a importacao no banco (uma transacao por
// atividade), duplicatas, ignoradas, erros, progresso e cancelamento.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/domain/waypoint.dart' as dom;
import 'package:strava_estudo_app/your_data/domain/activity_builder.dart';
import 'package:strava_estudo_app/your_data/domain/import_models.dart';
import 'package:strava_estudo_app/your_data/import_feed.dart';
import 'package:strava_estudo_app/your_data/import_service.dart';

import 'fixtures.dart';

class ListFeed implements ImportFeed {
  final List<ImportStep> steps;
  int i = 0;
  bool closed = false;
  ListFeed(this.steps);
  @override
  int get total => steps.length;
  @override
  Future<ImportStep?> next() async => closed || i >= steps.length ? null : steps[i++];
  @override
  Future<void> close() async => closed = true;
}

ImportedActivity act(
  String guid, {
  ActivityType type = ActivityType.run,
  int? startMs,
  bool indoor = false,
  ImportFormat format = ImportFormat.gpx,
}) {
  final s = startMs ?? kT0;
  return ImportedActivity(
    guid: guid,
    type: type,
    format: format,
    title: 'Titulo $guid',
    startMs: s,
    endMs: s + 60000,
    timerMs: 55000,
    distanceMeters: indoor ? 5000 : 30,
    isIndoor: indoor,
    points: indoor
        ? const []
        : [
            for (var i = 0; i < 3; i++)
              dom.Waypoint(
                position: GeoPoint(latitude: -23.5 + i * 0.0001, longitude: -46.6, altitudeMeters: 700.0 + i),
                cumulativeDistanceMeters: i * 11.0,
                elapsedTimeMs: i * 1000,
                timerTimeMs: i * 1000,
                classification: dom.WaypointClassification.accept,
                horizontalAccuracyMeters: 5,
              ),
          ],
  );
}

ImportStep ok(ImportedActivity a) => ImportStepActivity('${a.guid}.gpx', a);

void main() {
  late RecordingDatabase db;
  late ImportService service;
  setUp(() {
    db = RecordingDatabase(NativeDatabase.memory());
    service = ImportService(db);
  });
  tearDown(() => db.close());

  test('grava finalizada, pendente de sync, so eu, com origem e pontos', () async {
    final s = await service.run(ListFeed([ok(act('imp-a')), ok(act('imp-b', indoor: true, startMs: kT0 + 86400000, format: ImportFormat.fit))]));
    expect(s.imported, 2);
    expect(s.duplicates, 0);
    final a = (await db.finishedActivitiesAscending()).first;
    expect(a.guid, 'imp-a');
    expect(a.isFinished, isTrue);
    expect(a.syncState, SyncState.pending);
    expect(a.visibility, 'private');
    expect(a.importSource, 'gpx');
    expect(a.title, 'Titulo imp-a');
    expect(a.timerTimeMs, 55000);
    expect(a.endTimestampMs, kT0 + 60000);
    expect(a.distanceMeters, 30);
    final wps = await db.waypointsForActivity('imp-a');
    expect(wps, hasLength(3));
    expect(wps.map((w) => w.seq), [0, 1, 2]);
    expect(wps.last.altitudeMeters, 702);
    final b = (await db.finishedActivitiesAscending()).last;
    expect(b.isIndoor, isTrue);
    expect(b.importSource, 'fit');
    expect(await db.waypointsForActivity('imp-b'), isEmpty);
    // Entra na fila de sync como qualquer atividade.
    expect((await db.pendingActivities()).map((x) => x.guid), containsAll(['imp-a', 'imp-b']));
  });

  test('reimportar o mesmo arquivo nao duplica', () async {
    await service.run(ListFeed([ok(act('imp-a'))]));
    final s = await service.run(ListFeed([ok(act('imp-a'))]));
    expect(s.imported, 0);
    expect(s.duplicates, 1);
    expect(await db.finishedActivitiesAscending(), hasLength(1));
  });

  test('mesmo tipo com inicio a menos de 60 s (inclusive gravada no app) e duplicada', () async {
    await db.upsertActivity(ActivitiesCompanion.insert(
      guid: 'gravada',
      activityType: ActivityType.run,
      startTimestampMs: kT0,
      isFinished: const Value(true),
      syncState: SyncState.synced,
    ));
    final s = await service.run(ListFeed([
      ok(act('imp-1', startMs: kT0 + 59000)),
      ok(act('imp-2', startMs: kT0 - 59000)),
      ok(act('imp-3', startMs: kT0 + 30000, type: ActivityType.ride)),
      ok(act('imp-4', startMs: kT0 + 60000)),
    ]));
    expect(s.duplicates, 2);
    expect(s.imported, 2);
    final guids = (await db.finishedActivitiesAscending()).map((a) => a.guid);
    expect(guids, containsAll(['gravada', 'imp-3', 'imp-4']));
    expect(guids, isNot(contains('imp-1')));
  });

  test('ignoradas por tipo e erros com motivo; um erro nao para os outros', () async {
    final s = await service.run(ListFeed([
      const ImportStepSkipped('1.fit', 'natacao'),
      const ImportStepError('2.gpx', 'XML mal formado'),
      const ImportStepSkipped('3.fit', 'natacao'),
      ok(act('imp-x')),
      const ImportStepSkipped('Manual', kNoFileLabel),
    ]));
    expect(s.ignored, {'natacao': 2, kNoFileLabel: 1});
    expect(s.errors.single.source, '2.gpx');
    expect(s.errors.single.reason, 'XML mal formado');
    expect(s.imported, 1);
    expect(s.cancelled, isFalse);
  });

  test('progresso a cada item e cancelar mantem o que ja entrou e fecha a fila', () async {
    final feed = ListFeed([for (var i = 0; i < 5; i++) ok(act('imp-$i', startMs: kT0 + i * 86400000))]);
    final progress = <(int, int)>[];
    final s = await service.run(
      feed,
      onProgress: (p) => progress.add((p.done, p.total)),
      isCancelled: () => progress.length >= 3,
    );
    expect(s.cancelled, isTrue);
    expect(s.imported, 2);
    expect(progress, [(0, 5), (1, 5), (2, 5)]);
    expect(feed.closed, isTrue);
    expect(await db.finishedActivitiesAscending(), hasLength(2));
  });

  test('falha ao gravar uma atividade vira erro e nao deixa meia atividade', () async {
    final bad = ImportedActivity(
      guid: 'imp-bad',
      type: ActivityType.run,
      format: ImportFormat.gpx,
      title: null,
      startMs: kT0,
      endMs: kT0 + 1000,
      timerMs: 1000,
      distanceMeters: 1,
      isIndoor: false,
      points: [
        dom.Waypoint(
          position: const GeoPoint(latitude: double.nan, longitude: 0),
          cumulativeDistanceMeters: 0,
          elapsedTimeMs: 0,
          timerTimeMs: 0,
          classification: dom.WaypointClassification.accept,
        ),
      ],
    );
    final s = await ImportService(db, beforeCommit: (a) {
      if (a.guid == 'imp-bad') throw StateError('disco cheio');
    }).run(ListFeed([ImportStepActivity('bad.gpx', bad), ok(act('imp-ok', startMs: kT0 + 86400000))]));
    expect(s.errors.single.source, 'bad.gpx');
    expect(s.imported, 1);
    final guids = (await db.finishedActivitiesAscending()).map((a) => a.guid);
    expect(guids, ['imp-ok']);
    expect(await db.waypointsForActivity('imp-bad'), isEmpty);
  });

  test('fila que quebra no meio: o que entrou fica e o erro aparece', () async {
    final feed = _BrokenFeed(ok(act('imp-a')));
    final s = await service.run(feed);
    expect(s.imported, 1);
    expect(s.errors.single.reason, contains('interrompida'));
    expect(feed.closed, isTrue);
    expect(await db.finishedActivitiesAscending(), hasLength(1));
  });

  test('resumo em texto', () {
    const s = ImportSummary(
      total: 20,
      imported: 3,
      duplicates: 1,
      ignored: {'natacao': 12},
      errors: [ImportFailure('a.gpx', 'XML mal formado')],
      cancelled: false,
    );
    expect(s.ignoredLines, ['12 de natacao ignoradas']);
    const one = ImportSummary(total: 1, imported: 0, duplicates: 0, ignored: {'ioga': 1}, errors: [], cancelled: false);
    expect(one.ignoredLines, ['1 de ioga ignorada']);
  });
}

class _BrokenFeed implements ImportFeed {
  final ImportStep first;
  bool sent = false;
  bool closed = false;
  _BrokenFeed(this.first);
  @override
  int get total => 3;
  @override
  Future<ImportStep?> next() async {
    if (!sent) {
      sent = true;
      return first;
    }
    throw StateError('isolate caiu');
  }

  @override
  Future<void> close() async => closed = true;
}
