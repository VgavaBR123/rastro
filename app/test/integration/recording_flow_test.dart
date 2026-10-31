// Teste de integracao (shift-left): fluxo real gravacao -> metricas -> persistencia
// -> recuperacao, usando a fixture de rota e banco em memoria. Exercita o dominio
// e a camada Drift juntos, sem plugins nativos.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/persistence/recording_repository.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/domain/recording_session.dart';
import 'package:strava_estudo_app/recording/domain/waypoint.dart' as dom;

import '../fixtures/sample_route.dart';

void main() {
  late RecordingDatabase db;
  late RecordingRepository repo;

  setUp(() {
    db = RecordingDatabase(NativeDatabase.memory());
    repo = RecordingRepository(db);
  });
  tearDown(() async => db.close());

  test('grava rota, calcula métricas, persiste e recupera', () async {
    const guid = 'route-1';
    final route = sampleRoute();

    // Coleta os waypoints aceitos para persistir de forma incremental.
    final accepted = <dom.Waypoint>[];
    final session = RecordingSession(
      activityType: ActivityType.run,
      autoPauseEnabled: false, // determinismo
      onWaypoint: (w) {
        if (w.classification == dom.WaypointClassification.accept) accepted.add(w);
      },
    );

    await repo.startActivity(
      guid: guid,
      type: ActivityType.run,
      startTimestampMs: route.first.wallClockMs,
      startBatteryLevel: 95,
    );

    session.start(route.first.monotonicMs);
    for (final s in route) {
      session.addSample(s);
    }

    // Persiste em lote (como faria a borda a cada N pontos).
    await repo.appendWaypoints(guid, accepted);

    final stats = session.stats;

    // 1 ponto ruim (acc=300) foi filtrado -> 10 aceitos.
    expect(accepted.length, sampleRouteGoodCount);
    expect(stats.acceptedPointCount, sampleRouteGoodCount);

    // Distancia ~= haversine do primeiro ao ultimo ponto bom (linha reta leste).
    final expectedDist = haversineMeters(
      const GeoPoint(latitude: 0, longitude: 0),
      const GeoPoint(latitude: 0, longitude: 0.0001 * 10),
    );
    expect(stats.distanceMeters, closeTo(expectedDist, 1.0));

    // Elevacao: sobe 2 m/ponto; o ponto ruim nao entra. Ganho > 0 e sem perda.
    expect(stats.ascentMeters, greaterThan(0));
    expect(stats.descentMeters, 0.0);

    // Persistencia: os aceitos foram gravados em ordem.
    final persisted = await repo.waypoints(guid);
    expect(persisted.length, sampleRouteGoodCount);
    expect(persisted.last.cumulativeDistanceMeters,
        closeTo(stats.distanceMeters, 0.001));

    // Encerramento -> some da fila de recuperacao.
    session.finish();
    await repo.finish(guid, route.last.wallClockMs, endBattery: 88);
    final pend = await repo.unfinished();
    expect(pend.map((e) => e.guid), isNot(contains(guid)));
  });

  test('recuperacao: atividade interrompida reconstroi distância por replay', () async {
    const guid = 'route-crash';
    final route = sampleRoute();

    // Simula gravacao parcial (ate antes do fim), SEM finish (crash).
    final accepted = <dom.Waypoint>[];
    final session = RecordingSession(
      activityType: ActivityType.ride,
      autoPauseEnabled: false,
      onWaypoint: (w) {
        if (w.classification == dom.WaypointClassification.accept) accepted.add(w);
      },
    );
    await repo.startActivity(
      guid: guid,
      type: ActivityType.ride,
      startTimestampMs: route.first.wallClockMs,
    );
    session.start(route.first.monotonicMs);
    for (final s in route.take(8)) {
      session.addSample(s);
    }
    await repo.appendWaypoints(guid, accepted);

    // "Reabre o app": a atividade aparece como nao finalizada e os pontos
    // persistidos permitem reconstruir a distancia (replay).
    final pend = await repo.unfinished();
    expect(pend.map((e) => e.guid), contains(guid));

    final pts = await repo.waypoints(guid);
    expect(pts.isNotEmpty, true);
    final recoveredDistance = pts.last.cumulativeDistanceMeters;
    expect(recoveredDistance, closeTo(session.stats.distanceMeters, 0.001));
  });
}
