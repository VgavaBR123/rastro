import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/platform/method_channel_msl_altitude.dart';
import 'package:strava_estudo_app/platform/msl_altitude.dart';
import 'package:strava_estudo_app/platform/msl_altitude_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannelMslAltitudeConverter.defaultChannel;
  const converter = MethodChannelMslAltitudeConverter();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  Future<double?> call() => converter.toMsl(
    latitude: -19.92,
    longitude: -43.94,
    ellipsoidAltitudeMeters: 850,
  );

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('devolve o valor do nativo e envia os argumentos', () async {
    MethodCall? received;
    messenger.setMockMethodCallHandler(channel, (c) async {
      received = c;
      return 856.4;
    });
    expect(await call(), 856.4);
    expect(received!.method, 'toMsl');
    expect(received!.arguments, {
      'latitude': -19.92,
      'longitude': -43.94,
      'ellipsoidAltitudeMeters': 850.0,
    });
  });

  test('null do nativo vira null', () async {
    messenger.setMockMethodCallHandler(channel, (c) async => null);
    expect(await call(), isNull);
  });

  test('erro do nativo vira null, sem lancar', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (c) async => throw PlatformException(code: 'io'),
    );
    expect(await call(), isNull);
  });

  test('canal sem implementacao vira null', () async {
    expect(await call(), isNull);
  });

  test('entrada nao finita nao chama o nativo', () async {
    var calls = 0;
    messenger.setMockMethodCallHandler(channel, (c) async {
      calls++;
      return 1.0;
    });
    final r = await converter.toMsl(
      latitude: double.nan,
      longitude: 0,
      ellipsoidAltitudeMeters: 0,
    );
    expect(r, isNull);
    expect(calls, 0);
  });

  test('provider: host de teste usa NoMsl; Android usa o canal', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(
      container.read(mslAltitudeConverterProvider),
      isA<NoMslAltitudeConverter>(),
    );
    expect(
      defaultMslAltitudeConverter(isAndroid: true),
      isA<MethodChannelMslAltitudeConverter>(),
    );
  });
}
