/// Ponte entre a privacidade automatica (F02) e o banco: zonas, sugestoes
/// ignoradas, pontas das atividades para a deteccao, inicios recentes para o
/// aviso de rotina e a rota/waypoints ja cortados para a imagem, o upload e a
/// exportacao.
library;

import '../persistence/database.dart';
import '../recording/domain/geo.dart';
import '../recording/domain/waypoint.dart' as dom;
import 'domain/privacy_zone.dart';
import 'domain/route_trim.dart';
import 'domain/routine.dart';
import 'domain/zone_detection.dart';

/// Rota de uma atividade com o corte de privacidade.
class PrivateRoute {
  /// Todos os pontos aceitos.
  final List<GeoPoint> full;
  final RouteTrim trim;
  const PrivateRoute(this.full, this.trim);

  /// So os pontos que podem aparecer.
  List<GeoPoint> get points => trim.apply(full);

  static const PrivateRoute empty = PrivateRoute([], RouteTrim.none(0));
}

class PrivacyRepository {
  final RecordingDatabase db;
  final int Function() _nowMs;

  PrivacyRepository(this.db, {int Function()? nowMs})
    : _nowMs = nowMs ?? (() => DateTime.now().millisecondsSinceEpoch);

  // --- Zonas ---

  Future<List<PrivacyZone>> zones() async => [
    for (final r in await db.allPrivacyZones())
      PrivacyZone(
        id: r.id,
        latitude: r.latitude,
        longitude: r.longitude,
        radiusMeters: r.radiusMeters,
        label: r.label,
      ),
  ];

  /// Salva [zone] e devolve com o id. Rotulo vazio vira "Local protegido".
  Future<PrivacyZone> addZone(PrivacyZone zone) async {
    final label = zone.label.trim().isEmpty
        ? 'Local protegido'
        : zone.label.trim();
    final id = await db.insertPrivacyZone(
      PrivacyZonesCompanion.insert(
        latitude: zone.latitude,
        longitude: zone.longitude,
        radiusMeters: zone.radiusMeters,
        label: label,
        createdAtMs: _nowMs(),
      ),
    );
    return PrivacyZone(
      id: id,
      latitude: zone.latitude,
      longitude: zone.longitude,
      radiusMeters: zone.radiusMeters,
      label: label,
    );
  }

  Future<void> removeZone(int id) => db.deletePrivacyZone(id);

  // --- Sugestoes ---

  Future<List<GeoPoint>> dismissedSuggestions() async => [
    for (final r in await db.allDismissedZoneSuggestions())
      GeoPoint(latitude: r.latitude, longitude: r.longitude),
  ];

  /// O lugar [center] nao volta a ser sugerido.
  Future<void> dismissSuggestion(GeoPoint center) =>
      db.insertDismissedZoneSuggestion(
        DismissedZoneSuggestionsCompanion.insert(
          latitude: center.latitude,
          longitude: center.longitude,
          createdAtMs: _nowMs(),
        ),
      );

  /// Primeiro e ultimo ponto aceito das atividades finalizadas recentes.
  Future<List<ActivityEndpoints>> activityEndpoints({int limit = 100}) async {
    final rows = await db.finishedActivityEndpoints(limit: limit);
    final byGuid = <String, List<GeoPoint>>{};
    final order = <String>[];
    for (final r in rows) {
      final list = byGuid.putIfAbsent(r.guid, () {
        order.add(r.guid);
        return [];
      });
      list.add(GeoPoint(latitude: r.latitude, longitude: r.longitude));
    }
    return [
      for (final g in order)
        ActivityEndpoints(
          guid: g,
          start: byGuid[g]!.first,
          end: byGuid[g]!.last,
        ),
    ];
  }

  /// Sugestoes de zona ainda nao aceitas nem ignoradas.
  Future<List<ZoneSuggestion>> suggestions() async => suggestPrivacyZones(
    await activityEndpoints(),
    zones: await zones(),
    dismissed: await dismissedSuggestions(),
  );

  // --- Rotina ---

  /// Inicio (lugar e horario local) das atividades finalizadas mais recentes,
  /// da mais nova para a mais antiga.
  /// Com [atOrBeforeMs], so as que comecaram ate esse instante.
  Future<List<ActivityStartSample>> recentStarts({
    int limit = kRoutineWindow,
    String? exceptGuid,
    int? atOrBeforeMs,
  }) async {
    final rows = await db.finishedActivityEndpoints(
      limit: limit + 1,
      atOrBeforeMs: atOrBeforeMs,
    );
    final seen = <String>{};
    final out = <ActivityStartSample>[];
    for (final r in rows) {
      if (r.guid == exceptGuid || !seen.add(r.guid)) continue;
      out.add(
        ActivityStartSample.at(
          GeoPoint(latitude: r.latitude, longitude: r.longitude),
          DateTime.fromMillisecondsSinceEpoch(r.startMs),
        ),
      );
    }
    return out.take(limit).toList();
  }

  /// Aviso de rotina para a atividade [guid] (tela Compartilhar): ela e as
  /// 5 anteriores a ela, e so avisa se ela propria faz parte do grupo que se
  /// repete. Sem atividade ou sem GPS, nao avisa.
  Future<bool> routineWarningFor(String guid) async {
    final a = await (db.select(
      db.activities,
    )..where((t) => t.guid.equals(guid))).getSingleOrNull();
    if (a == null) return false;
    final rows = await _accepted(guid);
    if (rows.isEmpty) return false;
    final previous = await recentStarts(
      limit: kRoutineWindow - 1,
      exceptGuid: guid,
      atOrBeforeMs: a.startTimestampMs,
    );
    return isRoutinePredictableFor(
      ActivityStartSample.at(
        _point(rows.first),
        DateTime.fromMillisecondsSinceEpoch(a.startTimestampMs),
      ),
      previous,
    );
  }

  // --- Corte ---

  RouteTrim _trim(Activity a, List<GeoPoint> route, List<PrivacyZone> zones) =>
      computeRouteTrim(
        route,
        zones: zones,
        activityGuid: a.guid,
        hideStartMeters: a.hideEdgesMeters.toDouble(),
        hideEndMeters: a.hideEdgesMeters.toDouble(),
      );

  Future<List<Waypoint>> _accepted(String guid) async => [
    for (final w in await db.waypointsForActivity(guid))
      if (w.classification == dom.WaypointClassification.accept.index) w,
  ];

  static GeoPoint _point(Waypoint w) => GeoPoint(
    latitude: w.latitude,
    longitude: w.longitude,
    altitudeMeters: w.altitudeMeters,
  );

  /// Rota aceita de [guid] com o corte das zonas e da atividade.
  Future<PrivateRoute> visibleRoute(String guid) async {
    final a = await (db.select(
      db.activities,
    )..where((t) => t.guid.equals(guid))).getSingleOrNull();
    if (a == null) return PrivateRoute.empty;
    final full = [for (final w in await _accepted(guid)) _point(w)];
    return PrivateRoute(full, _trim(a, full, await zones()));
  }

  /// Waypoints aceitos de [a] sem as pontas ocultas. Base da exportacao
  /// (GPX/FIT para fora do app): sempre corta.
  Future<List<Waypoint>> exportWaypoints(Activity a) async {
    final rows = await _accepted(a.guid);
    final trim = _trim(a, [for (final w in rows) _point(w)], await zones());
    return trim.apply(rows);
  }

  /// Waypoints aceitos que sobem para o servidor: cortados quando "Ocultar
  /// tambem no servidor" esta ligado (padrao), inteiros quando nao.
  Future<List<Waypoint>> uploadWaypoints(Activity a) async {
    final settings = await db.loadSettings();
    if (!settings.hideOnServer) return _accepted(a.guid);
    return exportWaypoints(a);
  }
}
