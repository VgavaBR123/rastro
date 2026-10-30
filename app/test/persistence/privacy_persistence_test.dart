// Privacidade automatica (F02): zonas, sugestoes ignoradas, pontas das
// atividades, visibilidade padrao "so eu", corte por atividade e migracao
// 7 -> 8, tudo no Drift em memoria (ou arquivo, na migracao).
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/persistence/recording_repository.dart';
import 'package:strava_estudo_app/privacy/domain/privacy_zone.dart';
import 'package:strava_estudo_app/privacy/domain/route_trim.dart';
import 'package:strava_estudo_app/privacy/privacy_repository.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/domain/waypoint.dart' as dom;

const double kStep = 0.0001; // ~11,1 m

dom.Waypoint wp(double lon, int i, {bool accepted = true, double lat = 0}) => dom.Waypoint(
  position: GeoPoint(latitude: lat, longitude: lon),
  cumulativeDistanceMeters: i * 11.1,
  elapsedTimeMs: i * 1000,
  timerTimeMs: i * 1000,
  classification: accepted
      ? dom.WaypointClassification.accept
      : dom.WaypointClassification.values.last,
);

/// Atividade finalizada com [n] pontos em linha reta a partir de [fromLon].
Future<void> seed(
  RecordingRepository repo,
  String guid, {
  int n = 200,
  double fromLon = 0,
  int startMs = 1000,
  bool finish = true,
}) async {
  await repo.startActivity(guid: guid, type: ActivityType.run, startTimestampMs: startMs);
  await repo.appendWaypoints(guid, [
    for (var i = 0; i < n; i++) wp(fromLon + i * kStep, i),
  ]);
  if (finish) {
    await repo.finish(guid, startMs + n * 1000, distanceMeters: n * 11.1, timerTimeMs: n * 1000);
  }
}

void main() {
  late RecordingDatabase db;
  late RecordingRepository repo;
  late PrivacyRepository privacy;

  setUp(() {
    db = RecordingDatabase(NativeDatabase.memory());
    repo = RecordingRepository(db);
    privacy = PrivacyRepository(db);
  });
  tearDown(() => db.close());

  group('zonas', () {
    test('adiciona, lista e remove', () async {
      expect(await privacy.zones(), isEmpty);
      final z = await privacy.addZone(
        const PrivacyZone(latitude: -23.5, longitude: -46.6, radiusMeters: 300, label: 'Casa'),
      );
      expect(z.id, isNotNull);
      final list = await privacy.zones();
      expect(list, hasLength(1));
      expect(list.single.label, 'Casa');
      expect(list.single.radiusMeters, 300);
      await privacy.removeZone(z.id!);
      expect(await privacy.zones(), isEmpty);
    });

    test('sugestao ignorada fica salva', () async {
      await privacy.dismissSuggestion(const GeoPoint(latitude: 1, longitude: 2));
      final d = await privacy.dismissedSuggestions();
      expect(d.single.latitude, 1);
      expect(d.single.longitude, 2);
    });
  });

  group('pontas e sugestoes', () {
    test('pontas usam o primeiro e o ultimo ponto aceito das finalizadas', () async {
      await seed(repo, 'a', n: 10);
      // Ponto descartado no fim nao conta.
      await repo.startActivity(guid: 'b', type: ActivityType.ride, startTimestampMs: 2000);
      await repo.appendWaypoints('b', [
        wp(1, 0),
        wp(1 + kStep, 1),
        wp(9, 2, accepted: false),
      ]);
      await repo.finish('b', 5000);
      await seed(repo, 'gravando', finish: false);

      final eps = {for (final e in await privacy.activityEndpoints()) e.guid: e};
      expect(eps.keys, unorderedEquals(['a', 'b']));
      expect(eps['a']!.start.longitude, 0);
      expect(eps['a']!.end.longitude, closeTo(9 * kStep, 1e-9));
      expect(eps['b']!.end.longitude, closeTo(1 + kStep, 1e-9));
    });

    test('3 atividades saindo de casa geram sugestao; aceitar ou ignorar some', () async {
      // Fins diferentes (~900 m entre eles): so o inicio se repete.
      for (var i = 0; i < 3; i++) {
        await seed(repo, 's$i', n: 100 + i * 80, startMs: 1000 + i);
      }
      var s = await privacy.suggestions();
      expect(s, hasLength(1));
      expect(s.single.center.longitude, closeTo(0, 1e-6));

      await privacy.dismissSuggestion(s.single.center);
      s = await privacy.suggestions();
      expect(s, isEmpty);
    });
  });

  group('rotina', () {
    test('inicios recentes na ordem da mais nova, sem a atual', () async {
      await seed(repo, 'velha', startMs: DateTime(2026, 1, 1, 6).millisecondsSinceEpoch);
      await seed(repo, 'nova', startMs: DateTime(2026, 1, 2, 7, 15).millisecondsSinceEpoch);
      final starts = await privacy.recentStarts();
      expect(starts.map((s) => s.minuteOfDay), [7 * 60 + 15, 6 * 60]);
      final semNova = await privacy.recentStarts(exceptGuid: 'nova');
      expect(semNova, hasLength(1));
    });

    test('atividades sem GPS nao ocupam lugar na janela das ultimas 6', () async {
      for (var i = 0; i < 6; i++) {
        await seed(repo, 'gps$i', n: 5, startMs: DateTime(2026, 1, 1 + i, 6).millisecondsSinceEpoch);
      }
      // Tres esteiras mais novas, sem nenhum ponto.
      for (var i = 0; i < 3; i++) {
        final start = DateTime(2026, 2, 1 + i, 6).millisecondsSinceEpoch;
        await repo.startActivity(guid: 'indoor$i', type: ActivityType.run, startTimestampMs: start);
        await repo.finish('indoor$i', start + 1000);
      }
      expect(await privacy.recentStarts(), hasLength(6));
      expect(await privacy.activityEndpoints(limit: 2), hasLength(2));
    });

    test('aviso de rotina olha a atividade compartilhada, nao as ultimas em geral', () async {
      // Uma atividade antiga longe, as 18h; depois 4 saidas de casa as 6h.
      await seed(repo, 'antiga', n: 5, fromLon: 1, startMs: DateTime(2026, 1, 1, 18).millisecondsSinceEpoch);
      for (var i = 0; i < 4; i++) {
        await seed(repo, 'casa$i', n: 5, startMs: DateTime(2026, 1, 2 + i, 6, i * 5).millisecondsSinceEpoch);
      }
      // E uma mais nova, de tarde, em outro lugar.
      await seed(repo, 'tarde', n: 5, fromLon: 2, startMs: DateTime(2026, 1, 9, 15).millisecondsSinceEpoch);

      expect(await privacy.routineWarningFor('casa3'), isTrue);
      expect(await privacy.routineWarningFor('casa1'), isFalse); // so 2 antes dela
      expect(await privacy.routineWarningFor('antiga'), isFalse);
      expect(await privacy.routineWarningFor('tarde'), isFalse);
      expect(await privacy.routineWarningFor('nao-existe'), isFalse);
    });
  });

  group('visibilidade e corte por atividade', () {
    test('atividade nova comeca como "so eu"', () async {
      await seed(repo, 'a');
      final a = (await repo.activity('a'))!;
      expect(ActivityVisibility.fromDb(a.visibility), ActivityVisibility.onlyMe);
      expect(a.hideEdgesMeters, 0);
    });

    test('valor desconhecido de visibilidade cai em "so eu"', () {
      expect(ActivityVisibility.fromDb(null), ActivityVisibility.onlyMe);
      expect(ActivityVisibility.fromDb('xyz'), ActivityVisibility.onlyMe);
    });

    test('tela Salvar grava ocultar primeiros e ultimos X m', () async {
      await seed(repo, 'a');
      await repo.saveDetails('a', title: 't', hideEdgesMeters: 500);
      expect((await repo.activity('a'))!.hideEdgesMeters, 500);
    });

    test('rota visivel: corta pela zona e pelos metros da atividade', () async {
      await seed(repo, 'a', n: 300);
      var v = await privacy.visibleRoute('a');
      expect(v.trim.hidesAnything, isFalse);
      expect(v.points, hasLength(300));

      await privacy.addZone(
        const PrivacyZone(latitude: 0, longitude: 0, radiusMeters: 200, label: 'Casa'),
      );
      v = await privacy.visibleRoute('a');
      expect(v.trim.hidesStart, isTrue);
      expect(v.trim.hidesEnd, isFalse);
      expect(v.full, hasLength(300));
      expect(v.points.length, lessThan(300));

      await repo.saveDetails('a', hideEdgesMeters: 200);
      v = await privacy.visibleRoute('a');
      expect(v.trim.hidesEnd, isTrue);
    });

    test('waypoints para upload: cortados so com "ocultar no servidor"', () async {
      await seed(repo, 'a', n: 300);
      await privacy.addZone(
        const PrivacyZone(latitude: 0, longitude: 0, radiusMeters: 200, label: 'Casa'),
      );
      final a = (await repo.activity('a'))!;
      final cortados = await privacy.uploadWaypoints(a);
      final trim = computeRouteTrim(
        [for (var i = 0; i < 300; i++) GeoPoint(latitude: 0, longitude: i * kStep)],
        zones: await privacy.zones(),
        activityGuid: 'a',
      );
      expect(cortados, hasLength(trim.end - trim.start));

      await db.saveSettings(hideOnServer: false);
      expect(await privacy.uploadWaypoints(a), hasLength(300));
    });

    test('exportacao sempre corta (funcao exposta para o futuro)', () async {
      await seed(repo, 'a', n: 300);
      await privacy.addZone(
        const PrivacyZone(latitude: 0, longitude: 0, radiusMeters: 200, label: 'Casa'),
      );
      final a = (await repo.activity('a'))!;
      await db.saveSettings(hideOnServer: false);
      expect((await privacy.exportWaypoints(a)).length, lessThan(300));
    });
  });

  test('configuracao "ocultar tambem no servidor" comeca ligada', () async {
    expect((await db.loadSettings()).hideOnServer, isTrue);
    await db.saveSettings(hideOnServer: false);
    expect((await db.loadSettings()).hideOnServer, isFalse);
  });

  test('apagar a atividade nao mexe nas zonas', () async {
    await seed(repo, 'a');
    await privacy.addZone(
      const PrivacyZone(latitude: 0, longitude: 0, radiusMeters: 200, label: 'Casa'),
    );
    await repo.deleteActivity('a', nowMs: 1);
    expect(await privacy.zones(), hasLength(1));
  });

  test('migracao de antes da coluna visibility mantem "todos" nas antigas', () async {
    final dir = Directory.systemTemp.createTempSync('rastro_mig5');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/rec.sqlite');

    var fileDb = RecordingDatabase(NativeDatabase(file));
    await RecordingRepository(fileDb).startActivity(
      guid: 'old',
      type: ActivityType.run,
      startTimestampMs: 5,
    );
    await fileDb.close();

    // Volta o arquivo para o schema 5 (sem title/description/visibility e
    // sem nada de F01/F02).
    fileDb = RecordingDatabase(
      NativeDatabase(
        file,
        setup: (raw) {
          final v = raw.select('PRAGMA user_version').first.values.first;
          if (v != 10) return;
          // F04 (schema 10) veio depois: tira o que e dele.
          raw.execute('ALTER TABLE activities DROP COLUMN rpe');
          raw.execute('ALTER TABLE activities DROP COLUMN mood');
          raw.execute('ALTER TABLE settings_rows DROP COLUMN gentle_mode');
          raw.execute('ALTER TABLE settings_rows DROP COLUMN narrator_prefs');
          raw.execute('DROP TABLE privacy_zones');
          raw.execute('DROP TABLE dismissed_zone_suggestions');
          raw.execute('DROP TABLE recording_gaps');
          for (final col in [
            'hide_edges_meters',
            'last_heartbeat_ms',
            'heartbeat_paused',
            'discarded_point_count',
            'title',
            'description',
            'visibility',
          ]) {
            raw.execute('ALTER TABLE activities DROP COLUMN $col');
          }
          raw.execute('ALTER TABLE settings_rows DROP COLUMN hide_on_server');
          raw.execute('ALTER TABLE settings_rows DROP COLUMN reliability_checklist_seen');
          raw.execute('PRAGMA user_version = 5');
        },
      ),
    );
    addTearDown(fileDb.close);

    final r = RecordingRepository(fileDb);
    final old = (await r.activity('old'))!;
    // Antes do F02 o padrao era "todos": as antigas mantem isso.
    expect(ActivityVisibility.fromDb(old.visibility), ActivityVisibility.everyone);
    // Atividade nova segue nascendo "so eu".
    await r.startActivity(guid: 'new', type: ActivityType.run, startTimestampMs: 9);
    expect(
      ActivityVisibility.fromDb((await r.activity('new'))!.visibility),
      ActivityVisibility.onlyMe,
    );
  });

  test('migracao 7 -> 8 cria zonas e colunas novas sem perder dados', () async {
    final dir = Directory.systemTemp.createTempSync('rastro_mig8');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/rec.sqlite');

    var fileDb = RecordingDatabase(NativeDatabase(file));
    final r = RecordingRepository(fileDb);
    await r.startActivity(guid: 'old', type: ActivityType.walk, startTimestampMs: 5);
    await r.saveDetails('old', visibility: ActivityVisibility.everyone);
    await fileDb.saveSettings(useMetric: false);
    await fileDb.close();

    fileDb = RecordingDatabase(
      NativeDatabase(
        file,
        setup: (raw) {
          final v = raw.select('PRAGMA user_version').first.values.first;
          if (v != 10) return;
          // F04 (schema 10) veio depois: tira o que e dele.
          raw.execute('ALTER TABLE activities DROP COLUMN rpe');
          raw.execute('ALTER TABLE activities DROP COLUMN mood');
          raw.execute('ALTER TABLE settings_rows DROP COLUMN gentle_mode');
          raw.execute('ALTER TABLE settings_rows DROP COLUMN narrator_prefs');
          raw.execute('DROP TABLE privacy_zones');
          raw.execute('DROP TABLE dismissed_zone_suggestions');
          raw.execute('ALTER TABLE activities DROP COLUMN hide_edges_meters');
          raw.execute('ALTER TABLE settings_rows DROP COLUMN hide_on_server');
          raw.execute('PRAGMA user_version = 7');
        },
      ),
    );
    addTearDown(fileDb.close);

    final old = (await RecordingRepository(fileDb).activity('old'))!;
    expect(old.activityType, ActivityType.walk);
    // A escolha antiga e mantida.
    expect(ActivityVisibility.fromDb(old.visibility), ActivityVisibility.everyone);
    expect(old.hideEdgesMeters, 0);
    final settings = await fileDb.loadSettings();
    expect(settings.useMetric, isFalse);
    expect(settings.hideOnServer, isTrue);
    final p = PrivacyRepository(fileDb);
    await p.addZone(
      const PrivacyZone(latitude: 0, longitude: 0, radiusMeters: 200, label: 'Casa'),
    );
    await p.dismissSuggestion(const GeoPoint(latitude: 1, longitude: 1));
    expect(await p.zones(), hasLength(1));
    expect(await p.dismissedSuggestions(), hasLength(1));
  });
}
