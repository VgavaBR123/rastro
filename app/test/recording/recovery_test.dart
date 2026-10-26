// Recuperacao pos-crash (roteiro 5): reconstruir a sessao dos pontos salvos,
// continuar gravando na mesma atividade ou finalizar com o que sobrou.
import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/persistence/recording_repository.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/location_sample.dart';
import 'package:strava_estudo_app/recording/domain/recording_clock.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/domain/recording_session.dart';
import 'package:strava_estudo_app/recording/domain/waypoint.dart' as dom;
import 'package:strava_estudo_app/recording/presentation/recording_controller.dart';
import 'package:strava_estudo_app/recording/source/location_source.dart';

import '../fixtures/sample_route.dart';

/// Continua a rota da fixture para leste, com nova base monotonica (a fonte
/// recomeca do zero depois do crash).
List<LocationSample> continuation({required int fromIndex, int count = 5}) => [
      for (var i = 0; i < count; i++)
        LocationSample(
          position: GeoPoint(
            latitude: 0,
            longitude: 0.0001 * (fromIndex + i),
            altitudeMeters: 150,
          ),
          wallClockMs: 1000 * i,
          monotonicMs: 1000 * i,
          horizontalAccuracyMeters: 5.0,
          verticalAccuracyMeters: 3.0,
          speedMetersPerSecond: 11.0,
        ),
    ];

List<dom.Waypoint> recordAccepted(List<LocationSample> samples) {
  final accepted = <dom.Waypoint>[];
  final session = RecordingSession(
    activityType: ActivityType.run,
    autoPauseEnabled: false,
    onWaypoint: (w) {
      if (!w.isFiltered) accepted.add(w);
    },
  )..start(0);
  samples.forEach(session.addSample);
  return accepted;
}

class FakeLocationSource implements LocationSource {
  final _controller = StreamController<LocationSample>.broadcast();
  void add(LocationSample s) => _controller.add(s);
  @override
  Future<bool> ensurePermission() async => true;
  @override
  Stream<LocationSample> positions() => _controller.stream;
  @override
  Future<void> stop() async {}
}

void main() {
  group('RecordingClock.restore', () {
    test('continua o cronometro e conta o tempo fora como pausa', () {
      final c = RecordingClock()
        ..restore(0, elapsedMs: 60000, timerMs: 40000);
      expect(c.elapsedMs, 60000);
      expect(c.timerMs, 40000);
      c.tick(5000);
      expect(c.elapsedMs, 65000);
      expect(c.timerMs, 45000);
    });
  });

  group('RecordingSession.restore', () {
    test('reconstroi distancia, tempo, splits e elevacao dos pontos salvos', () {
      final accepted = recordAccepted(sampleRoute());
      final last = accepted.last;

      final restored = RecordingSession(
        activityType: ActivityType.run,
        autoPauseEnabled: false,
      )..restore(accepted, monotonicMs: 0, elapsedMs: last.elapsedTimeMs + 30000);

      final st = restored.stats;
      expect(st.state, RecordingState.recording);
      expect(st.distanceMeters, closeTo(last.cumulativeDistanceMeters, 1e-9));
      expect(st.timerMs, last.timerTimeMs);
      expect(st.elapsedMs, last.elapsedTimeMs + 30000);
      expect(st.acceptedPointCount, sampleRouteGoodCount);
      // Altitude da fixture sobe 2 m por ponto; o replay refaz o ganho.
      expect(st.ascentMeters, greaterThan(0));
      expect(restored.splits.kilometers.currentSplit, isNotNull);
    });

    test('depois de restaurar, novos pontos somam sem contar o trecho do crash', () {
      final accepted = recordAccepted(sampleRoute());
      final before = accepted.last.cumulativeDistanceMeters;

      final restored = RecordingSession(
        activityType: ActivityType.run,
        autoPauseEnabled: false,
      )..restore(accepted, monotonicMs: 0, elapsedMs: accepted.last.elapsedTimeMs);

      // Retoma 20 pontos adiante (o corredor seguiu enquanto o app estava fora).
      for (final s in continuation(fromIndex: 30)) {
        restored.addSample(s);
      }
      final after = restored.stats.distanceMeters;
      // 5 pontos novos = 4 segmentos de ~11,1 m; o salto de ~220 m nao entra.
      expect(after - before, closeTo(4 * 11.13, 1.0));
      expect(restored.stats.timerMs, accepted.last.timerTimeMs + 4000);
    });

    test('elapsed menor que o cronometro (relogio de parede voltou) e corrigido', () {
      final accepted = recordAccepted(sampleRoute());
      final restored = RecordingSession(activityType: ActivityType.run)
        ..restore(accepted, monotonicMs: 0, elapsedMs: 0);
      expect(restored.stats.elapsedMs, accepted.last.timerTimeMs);
      expect(restored.stats.timerMs, accepted.last.timerTimeMs);
    });
  });

  group('recuperacao com banco e controller', () {
    late RecordingDatabase db;
    var clock = 1000;

    setUp(() {
      db = RecordingDatabase(NativeDatabase.memory());
      clock = 1000;
    });
    tearDown(() => db.close());

    /// Grava a fixture e "mata" o app sem encerrar: so o que foi descarregado
    /// em lote fica no banco.
    Future<String> recordAndCrash() async {
      final source = FakeLocationSource();
      final ctrl = RecordingController(
        source: source,
        repo: RecordingRepository(db),
        now: () => clock,
      );
      await ctrl.start(ActivityType.run, autoPauseEnabled: false);
      for (final s in sampleRoute()) {
        source.add(s);
      }
      await pumpEventQueue(times: 50);
      final guid = ctrl.activityGuid!;
      ctrl.dispose(); // sem stop(): simula o processo morrendo
      return guid;
    }

    test('lista a atividade interrompida com os pontos salvos', () async {
      final guid = await recordAndCrash();
      // Repositorio novo = processo novo (sem o estado em memoria do anterior).
      final list = await RecordingRepository(db).interrupted();
      expect(list, hasLength(1));
      expect(list.single.activity.guid, guid);
      expect(list.single.acceptedPoints, hasLength(kWaypointFlushBatch));
      expect(list.single.distanceMeters, greaterThan(90));
    });

    test('exceptGuid ignora a gravacao em andamento', () async {
      final guid = await recordAndCrash();
      final list = await RecordingRepository(db).interrupted(exceptGuid: guid);
      expect(list, isEmpty);
    });

    test('salvar finaliza com o resumo do ultimo ponto e entra na fila', () async {
      await recordAndCrash();
      final repo = RecordingRepository(db);
      final it = (await repo.interrupted()).single;
      await repo.finishInterrupted(it);

      expect(await repo.interrupted(), isEmpty);
      final saved = (await repo.recent()).single;
      expect(saved.distanceMeters, closeTo(it.distanceMeters, 1e-9));
      expect(saved.timerTimeMs, it.timerMs);
      expect(saved.endTimestampMs, saved.startTimestampMs + it.elapsedMs);
      expect(saved.syncState, SyncState.pending);
    });

    test('retomar continua a mesma atividade e a sequencia de pontos', () async {
      final guid = await recordAndCrash();
      clock += 120000; // app reaberto 2 min depois

      final repo = RecordingRepository(db);
      final it = (await repo.interrupted()).single;
      final source = FakeLocationSource();
      final ctrl = RecordingController(source: source, repo: repo, now: () => clock);
      addTearDown(ctrl.dispose);

      await ctrl.resumeInterrupted(it);
      expect(ctrl.activityGuid, guid);
      expect(ctrl.state.state, RecordingState.recording);
      expect(ctrl.state.distanceMeters, closeTo(it.distanceMeters, 1e-9));
      expect(ctrl.state.timerMs, it.timerMs);
      expect(ctrl.state.elapsedMs, 120000);
      expect(ctrl.route, hasLength(it.acceptedPoints.length));

      for (final s in continuation(fromIndex: 30)) {
        source.add(s);
      }
      await pumpEventQueue(times: 50);
      await ctrl.stop();

      final rows = await db.waypointsForActivity(guid);
      expect(rows, hasLength(kWaypointFlushBatch + 5));
      expect([for (final r in rows) r.seq], List.generate(rows.length, (i) => i));

      final saved = (await repo.recent()).single;
      expect(saved.guid, guid);
      expect(saved.distanceMeters, closeTo(it.distanceMeters + 4 * 11.13, 1.0));
      expect(await repo.interrupted(), isEmpty);
    });
  });
}
