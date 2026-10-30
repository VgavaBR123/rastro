// Privacidade automatica (F02): deteccao de casa e trabalho no aparelho,
// agrupando inicios e fins das atividades.
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/privacy/domain/privacy_zone.dart';
import 'package:strava_estudo_app/privacy/domain/zone_detection.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';

/// Casa em (0, 0); trabalho ~5,5 km a leste.
const casa = GeoPoint(latitude: 0, longitude: 0);
const trabalho = GeoPoint(latitude: 0, longitude: 0.05);
const longe = GeoPoint(latitude: 0.2, longitude: 0.2);

/// Ponto a ~[metros] a norte de [p].
GeoPoint perto(GeoPoint p, double metros) =>
    GeoPoint(latitude: p.latitude + metros / 111195, longitude: p.longitude);

ActivityEndpoints ep(String g, GeoPoint s, GeoPoint e) =>
    ActivityEndpoints(guid: g, start: s, end: e);

void main() {
  test('menos de 3 ocorrencias: nenhuma sugestao', () {
    final s = suggestPrivacyZones([ep('1', casa, longe)]);
    expect(s, isEmpty);
  });

  test('3 inicios perto da casa (dentro de 150 m) viram sugestao', () {
    final s = suggestPrivacyZones([
      ep('1', casa, longe),
      ep('2', perto(casa, 40), perto(longe, 5000)),
      ep('3', perto(casa, 80), perto(longe, 10000)),
    ]);
    expect(s, hasLength(1));
    expect(s.single.occurrences, 3);
    expect(haversineMeters(s.single.center, casa), lessThan(80));
    expect(s.single.kind, SuggestionKind.home);
  });

  test('inicio e fim de ida e volta contam como duas ocorrencias', () {
    final s = suggestPrivacyZones([
      ep('1', casa, perto(casa, 30)),
      ep('2', perto(casa, 20), perto(longe, 2000)),
    ]);
    expect(s.single.occurrences, 3);
  });

  test('pontos a mais de 150 m nao se juntam', () {
    final s = suggestPrivacyZones([
      ep('1', casa, longe),
      ep('2', perto(casa, 400), perto(longe, 3000)),
      ep('3', perto(casa, 800), perto(longe, 6000)),
    ]);
    expect(s, isEmpty);
  });

  test('casa e trabalho: o mais frequente e casa, o segundo trabalho', () {
    final s = suggestPrivacyZones([
      ep('1', casa, trabalho),
      ep('2', trabalho, casa),
      ep('3', casa, perto(casa, 10)),
      ep('4', perto(trabalho, 20), perto(longe, 9000)),
    ]);
    expect(s, hasLength(2));
    expect(s[0].kind, SuggestionKind.home);
    expect(haversineMeters(s[0].center, casa), lessThan(50));
    expect(s[1].kind, SuggestionKind.work);
    expect(haversineMeters(s[1].center, trabalho), lessThan(50));
  });

  test('lugar ja protegido por uma zona nao volta como sugestao', () {
    final s = suggestPrivacyZones(
      [
        ep('1', casa, longe),
        ep('2', casa, perto(longe, 3000)),
        ep('3', casa, perto(longe, 6000)),
      ],
      zones: [
        const PrivacyZone(
          latitude: 0,
          longitude: 0,
          radiusMeters: 200,
          label: 'Casa',
        ),
      ],
    );
    expect(s, isEmpty);
  });

  test('sugestao ignorada nao volta', () {
    final s = suggestPrivacyZones(
      [
        ep('1', casa, longe),
        ep('2', casa, perto(longe, 3000)),
        ep('3', perto(casa, 30), perto(longe, 6000)),
      ],
      dismissed: [perto(casa, 50)],
    );
    expect(s, isEmpty);
  });

  test('deterministico: mesma entrada, mesma saida', () {
    final input = [
      ep('1', casa, trabalho),
      ep('2', trabalho, casa),
      ep('3', casa, trabalho),
    ];
    final a = suggestPrivacyZones(input);
    final b = suggestPrivacyZones(input);
    expect(
      [for (final s in a) (s.center.latitude, s.center.longitude, s.occurrences)],
      [for (final s in b) (s.center.latitude, s.center.longitude, s.occurrences)],
    );
  });

  test('rotulo e texto da sugestao', () {
    expect(SuggestionKind.home.label, 'Casa');
    expect(SuggestionKind.work.label, 'Trabalho');
    expect(SuggestionKind.frequent.label, 'Local frequente');
    expect(SuggestionKind.home.question, contains('sua casa'));
    expect(SuggestionKind.work.question, contains('seu trabalho'));
  });
}
