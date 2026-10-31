// Testes das consultas de historico e trajeto no repositorio.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/persistence/recording_repository.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/domain/waypoint.dart' as dom;

dom.Waypoint acc(double lat, double dist) => dom.Waypoint(
      position: GeoPoint(latitude: lat, longitude: 0, altitudeMeters: 100),
      cumulativeDistanceMeters: dist,
      elapsedTimeMs: 0,
      timerTimeMs: 0,
      classification: dom.WaypointClassification.accept,
      horizontalAccuracyMeters: 5,
    );

void main() {
  late RecordingDatabase db;
  late RecordingRepository repo;

  setUp(() {
    db = RecordingDatabase(NativeDatabase.memory());
    repo = RecordingRepository(db);
  });
  tearDown(() async => db.close());

  Future<void> seed(String guid, ActivityType type, int start) async {
    await repo.startActivity(guid: guid, type: type, startTimestampMs: start);
    await repo.appendWaypoints(guid, [acc(0.0, 0), acc(0.001, 11)]);
    await repo.finish(guid, start + 60000);
  }

  test('recent() devolve finalizadas, mais recentes primeiro', () async {
    await seed('a', ActivityType.run, 1000);
    await seed('b', ActivityType.ride, 5000);
    // 'c' nao finalizada nao deve aparecer.
    await repo.startActivity(guid: 'c', type: ActivityType.walk, startTimestampMs: 9000);

    final list = await repo.recent();
    expect(list.map((e) => e.guid), ['b', 'a']); // desc por startTimestamp
    expect(list.every((e) => e.isFinished), true);
  });

  test('deleteActivity() remove cabecalho e waypoints da atividade', () async {
    await seed('a', ActivityType.run, 1000);
    await seed('b', ActivityType.ride, 5000);
    expect((await repo.waypoints('a')).length, 2);

    await repo.deleteActivity('a');

    expect(await repo.waypoints('a'), isEmpty);
    expect((await repo.recent()).map((e) => e.guid), ['b']);
    // A outra atividade segue intacta, com os pontos dela.
    expect((await repo.waypoints('b')).length, 2);
  });

  test('routePoints() devolve só pontos aceitos', () async {
    await seed('a', ActivityType.run, 1000);
    final route = await repo.routePoints('a');
    expect(route.length, 2);
    expect(route.first, isA<GeoPoint>());
  });
}
