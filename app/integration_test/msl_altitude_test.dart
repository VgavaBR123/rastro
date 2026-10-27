// Chama o conversor MSL nativo de verdade no aparelho/emulador Android.
// flutter test integration_test/msl_altitude_test.dart -d <device>
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:strava_estudo_app/platform/method_channel_msl_altitude.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Android 14+ (API 34): a plataforma ja entrega MSL no fix e o canal devolve
  // null de proposito (converter de novo somaria o geoide duas vezes). Abaixo
  // disso, o AltitudeConverterCompat converte: 850 m elipsoidais viram ~856.
  testWidgets('BH: altitude elipsoidal 850 vira MSL ~856 (ou null no 14+)', (tester) async {
    const converter = MethodChannelMslAltitudeConverter();
    final msl = await converter.toMsl(
      latitude: -19.92,
      longitude: -43.94,
      ellipsoidAltitudeMeters: 850,
    );
    // Geoide em BH fica abaixo do elipsoide (N ~ -6 m): MSL = h - N > h.
    // ignore: avoid_print
    print('MSL_RESULT=$msl');
    if (msl == null) return; // Android 14+: plataforma ja entrega MSL.
    expect(msl, inInclusiveRange(852.0, 862.0));

    // Segunda chamada na mesma celula sai do cache e precisa bater.
    final again = await converter.toMsl(
      latitude: -19.921,
      longitude: -43.941,
      ellipsoidAltitudeMeters: 900,
    );
    // ignore: avoid_print
    print('MSL_RESULT2=$again');
    expect(again, isNotNull);
    expect(again! - 900, closeTo(msl - 850, 0.5));
  });
}
