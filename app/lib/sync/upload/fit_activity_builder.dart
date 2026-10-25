// Monta o arquivo FIT de uma atividade a partir dos dados persistidos
// (clean room, relatorios/06-sincronizacao.md).
//
// Le o fluxo de waypoints do banco, mantem apenas os aceitos (classification
// == 0, ACCEPT), converte cada um numa FitRecord e delega a serializacao ao
// encodeActivityFit (lib/sync/fit/fit_writer.dart).
library;

import 'dart:typed_data';

import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/sync/fit/fit_writer.dart';

/// classification do waypoint que entra no FIT (0 == ACCEPT).
const int _classificationAccept = 0;

/// Constroi o FIT da atividade `header` usando os waypoints aceitos de `db`.
Future<Uint8List> buildActivityFit(RecordingDatabase db, Activity header) async {
  final List<Waypoint> waypoints = await db.waypointsForActivity(header.guid);

  final List<FitRecord> records = <FitRecord>[
    for (final Waypoint wp in waypoints)
      if (wp.classification == _classificationAccept)
        FitRecord(
          // elapsedTimeMs e relativo ao inicio; o FIT quer o instante absoluto.
          timestampUnixMs: header.startTimestampMs + wp.elapsedTimeMs,
          latitude: wp.latitude,
          longitude: wp.longitude,
          cumulativeDistanceMeters: wp.cumulativeDistanceMeters,
          altitudeMeters: wp.altitudeMeters,
          speedMetersPerSecond: wp.speedMetersPerSecond,
        ),
  ];

  return encodeActivityFit(
    startTimeUnixMs: header.startTimestampMs,
    records: records,
  );
}
