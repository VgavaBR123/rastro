// Teste do RecordingController: caminho real (fonte fake -> dominio -> persistencia).
import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/persistence/recording_repository.dart';
import 'package:strava_estudo_app/recording/domain/location_sample.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/presentation/recording_controller.dart';
import 'package:strava_estudo_app/recording/source/location_source.dart';

import '../../fixtures/sample_route.dart';

/// Fonte de localizacao fake: o teste empurra amostras no stream.
class FakeLocationSource implements LocationSource {
  final _controller = StreamController<LocationSample>();
  bool permission = true;

  void add(LocationSample s) => _controller.add(s);

  @override
  Future<bool> ensurePermission() async => permission;

  @override
  Stream<LocationSample> positions() => _controller.stream;

  @override
  Future<void> stop() async => _controller.close();
}

void main() {
  late RecordingDatabase db;
  late RecordingRepository repo;
  late FakeLocationSource source;
  late RecordingController ctrl;

  setUp(() {
    db = RecordingDatabase(NativeDatabase.memory());
    repo = RecordingRepository(db);
    source = FakeLocationSource();
    ctrl = RecordingController(source: source, repo: repo, now: () => 1000);
  });

  tearDown(() async {
    ctrl.dispose();
    await db.close();
  });

  test('grava, atualiza estado e persiste; stop finaliza', () async {
    await ctrl.start(ActivityType.run, autoPauseEnabled: false);
    expect(ctrl.state.state, RecordingState.recording);

    for (final s in sampleRoute()) {
      source.add(s);
    }
    await pumpEventQueue(times: 50);

    // 1 ponto ruim filtrado -> 10 aceitos.
    expect(ctrl.state.points, sampleRouteGoodCount);
    expect(ctrl.state.distanceMeters, greaterThan(100));

    final guid = ctrl.activityGuid!;
    await ctrl.stop();
    expect(ctrl.state.state, RecordingState.finished);

    // Persistiu os pontos aceitos e finalizou.
    final pts = await repo.waypoints(guid);
    expect(pts.length, sampleRouteGoodCount);
    final pend = await repo.unfinished();
    expect(pend.map((e) => e.guid), isNot(contains(guid)));
  });

  test('Rastro Seguro: guarda so as amostras aceitas recentes, com a hora', () async {
    await ctrl.start(ActivityType.run, autoPauseEnabled: false);
    for (final s in sampleRoute()) {
      source.add(s);
    }
    await pumpEventQueue(times: 50);
    final all = ctrl.recentAccepted(sinceWallMs: 0);
    expect(all, hasLength(sampleRouteGoodCount));
    expect(ctrl.recentAccepted(sinceWallMs: all.last.wallClockMs), [all.last]);
    expect(ctrl.lastSample, isNotNull);
    await ctrl.stop();
  });

  test('permissao negada nao inicia e seta erro', () async {
    source.permission = false;
    await ctrl.start(ActivityType.ride);
    expect(ctrl.state.state, RecordingState.idle);
    expect(ctrl.state.error, isNotNull);
  });

  test('pausar e retomar refletem no estado', () async {
    await ctrl.start(ActivityType.run, autoPauseEnabled: false);
    final route = sampleRoute();
    source.add(route[0]);
    source.add(route[1]);
    await pumpEventQueue(times: 20);
    ctrl.pause();
    expect(ctrl.state.state, RecordingState.manuallyPaused);
    ctrl.resume();
    expect(ctrl.state.state, RecordingState.recording);
    await ctrl.stop();
  });
}
