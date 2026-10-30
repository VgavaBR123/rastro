// Borda do checklist "Gravacao confiavel" (F01): canal nativo do fabricante e
// conversao das permissoes do geolocator. Sem plugin real (canal simulado).
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:strava_estudo_app/platform/platform_reliability_probe.dart';
import 'package:strava_estudo_app/platform/reliability_probe.dart';
import 'package:strava_estudo_app/recording/domain/reliability_checklist.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = DeviceSettingsChannel.defaultChannel;
  const device = DeviceSettingsChannel();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  group('DeviceSettingsChannel', () {
    test('le o fabricante', () async {
      messenger.setMockMethodCallHandler(channel, (c) async {
        expect(c.method, 'manufacturer');
        return 'Xiaomi';
      });
      expect(await device.manufacturer(), 'Xiaomi');
    });

    test('abre a tela do fabricante e devolve se abriu', () async {
      MethodCall? got;
      messenger.setMockMethodCallHandler(channel, (c) async {
        got = c;
        return true;
      });
      const s = ManufacturerShortcut('pkg.a', 'pkg.a.Tela');
      expect(await device.openComponent(s), isTrue);
      expect(got!.method, 'openComponent');
      expect(got!.arguments, {'package': 'pkg.a', 'class': 'pkg.a.Tela'});
    });

    test('sem canal (iOS ou teste) nao lanca: null e false', () async {
      expect(await device.manufacturer(), isNull);
      expect(
        await device.openComponent(const ManufacturerShortcut('a', 'b')),
        isFalse,
      );
    });

    test('erro do nativo vira false', () async {
      messenger.setMockMethodCallHandler(channel, (c) async {
        throw PlatformException(code: 'x');
      });
      expect(
        await device.openComponent(const ManufacturerShortcut('a', 'b')),
        isFalse,
      );
    });
  });

  test('locationAccessFrom converte as permissoes do geolocator', () {
    expect(
      locationAccessFrom(LocationPermission.always),
      LocationAccess.always,
    );
    expect(
      locationAccessFrom(LocationPermission.whileInUse),
      LocationAccess.whileInUse,
    );
    expect(
      locationAccessFrom(LocationPermission.denied),
      LocationAccess.denied,
    );
    expect(
      locationAccessFrom(LocationPermission.deniedForever),
      LocationAccess.deniedForever,
    );
    expect(
      locationAccessFrom(LocationPermission.unableToDetermine),
      LocationAccess.unknown,
    );
  });

  test('NoopReliabilityProbe: nada a conferir e acoes sem efeito', () async {
    const probe = NoopReliabilityProbe();
    final snap = await probe.read();
    expect(snap.platform, DevicePlatform.other);
    expect(await probe.run(ChecklistAction.openBatterySettings), isFalse);
  });
}
