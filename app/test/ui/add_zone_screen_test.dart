// Novo local protegido (F02): regras da tela fora do mapa nativo. O mapa
// precisa ganhar os gestos dentro da lista que rola, e salvar exige um ponto
// escolhido de perto (sem cair num centro padrao sem querer).
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/ui/privacy/add_zone_screen.dart';

void main() {
  test('mapa do local pega os arrastos antes da lista que rola', () {
    final g = zonePickerGestureRecognizers();
    expect(g, hasLength(1));
    final recognizer = g.single.constructor();
    expect(recognizer, isA<EagerGestureRecognizer>());
    recognizer.dispose();
    expect(g.single, isA<Factory<OneSequenceGestureRecognizer>>());
  });

  group('validateMapPick', () {
    const p = GeoPoint(latitude: -19.9, longitude: -43.9);

    test('sem centro (mapa ainda nao parou): pede para mover o mapa', () {
      expect(validateMapPick(null, null), isNotNull);
    });

    test('visao ampla (zoom baixo, ex.: mapa do pais): recusa', () {
      expect(validateMapPick(p, 3), isNotNull);
      expect(validateMapPick(p, kMinZonePickZoom - 0.1), isNotNull);
    });

    test('de perto: aceita', () {
      expect(validateMapPick(p, kMinZonePickZoom), isNull);
      expect(validateMapPick(p, 16), isNull);
    });
  });

  test('coordenada digitada', () {
    expect(parseCoordinate('-19,9', limit: 90), -19.9);
    expect(parseCoordinate('200', limit: 90), isNull);
    expect(parseCoordinate('abc', limit: 180), isNull);
  });
}
