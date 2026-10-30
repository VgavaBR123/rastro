// Checklist "Gravacao confiavel" (F01): itens a partir do estado real do
// aparelho e instrucoes por fabricante. Dominio puro.
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/recording/domain/reliability_checklist.dart';

const _okAndroid = ReliabilitySnapshot(
  platform: DevicePlatform.android,
  manufacturer: 'samsung',
  batteryOptimizationIgnored: true,
  location: LocationAccess.always,
  preciseLocation: true,
  notificationsGranted: true,
);

void main() {
  group('detectManufacturer', () {
    test('reconhece as marcas, sem diferenciar caixa', () {
      expect(detectManufacturer('Xiaomi'), Manufacturer.xiaomi);
      expect(detectManufacturer('Redmi'), Manufacturer.xiaomi);
      expect(detectManufacturer('POCO'), Manufacturer.xiaomi);
      expect(detectManufacturer('samsung'), Manufacturer.samsung);
      expect(detectManufacturer('motorola'), Manufacturer.motorola);
      expect(detectManufacturer('Google'), Manufacturer.generic);
      expect(detectManufacturer(null), Manufacturer.generic);
    });
  });

  group('buildReliabilityChecklist (Android)', () {
    test('tudo certo: itens ok e pronto', () {
      final list = buildReliabilityChecklist(_okAndroid);
      expect(list.map((i) => i.id), [
        ChecklistItemId.battery,
        ChecklistItemId.location,
        ChecklistItemId.preciseLocation,
        ChecklistItemId.notifications,
        ChecklistItemId.manufacturer,
      ]);
      final required = list.where((i) => i.id != ChecklistItemId.manufacturer);
      expect(required.every((i) => i.status == ChecklistStatus.ok), isTrue);
      expect(isReliabilityReady(list), isTrue);
    });

    test('bateria otimizada e sem notificacao pedem acao', () {
      final list = buildReliabilityChecklist(
        _okAndroid.copyWith(
          batteryOptimizationIgnored: false,
          notificationsGranted: false,
        ),
      );
      ChecklistItem item(ChecklistItemId id) =>
          list.firstWhere((i) => i.id == id);
      expect(item(ChecklistItemId.battery).status, ChecklistStatus.action);
      expect(
        item(ChecklistItemId.battery).action,
        ChecklistAction.openBatterySettings,
      );
      expect(
        item(ChecklistItemId.notifications).status,
        ChecklistStatus.action,
      );
      expect(
        item(ChecklistItemId.notifications).action,
        ChecklistAction.requestNotifications,
      );
      expect(isReliabilityReady(list), isFalse);
    });

    test('localizacao: negada pede acao, so em uso basta no Android', () {
      ChecklistItem loc(LocationAccess a) =>
          buildReliabilityChecklist(_okAndroid.copyWith(location: a))
              .firstWhere((i) => i.id == ChecklistItemId.location);
      expect(loc(LocationAccess.denied).status, ChecklistStatus.action);
      expect(
        loc(LocationAccess.denied).action,
        ChecklistAction.requestLocation,
      );
      expect(
        loc(LocationAccess.deniedForever).action,
        ChecklistAction.openAppSettings,
      );
      expect(loc(LocationAccess.whileInUse).status, ChecklistStatus.ok);
    });

    test('localizacao aproximada pede acao', () {
      final list = buildReliabilityChecklist(
        _okAndroid.copyWith(preciseLocation: false),
      );
      final p = list.firstWhere((i) => i.id == ChecklistItemId.preciseLocation);
      expect(p.status, ChecklistStatus.action);
    });

    test('leitura indisponivel vira desconhecido, sem bloquear', () {
      final list = buildReliabilityChecklist(
        _okAndroid.copyWith(batteryOptimizationIgnored: null),
      );
      final b = list.firstWhere((i) => i.id == ChecklistItemId.battery);
      expect(b.status, ChecklistStatus.unknown);
      expect(isReliabilityReady(list), isTrue);
    });

    test('item do fabricante traz passos e atalho', () {
      final list = buildReliabilityChecklist(
        _okAndroid.copyWith(manufacturer: 'Xiaomi'),
      );
      final m = list.firstWhere((i) => i.id == ChecklistItemId.manufacturer);
      expect(m.title, contains('Xiaomi'));
      expect(m.steps, isNotEmpty);
      expect(m.action, ChecklistAction.openManufacturerSettings);
      expect(m.status, ChecklistStatus.info);
    });
  });

  group('buildReliabilityChecklist (iOS)', () {
    const ios = ReliabilitySnapshot(
      platform: DevicePlatform.ios,
      location: LocationAccess.whileInUse,
      preciseLocation: true,
    );

    test('so localizacao e precisao; Sempre e recomendado', () {
      final list = buildReliabilityChecklist(ios);
      expect(list.map((i) => i.id), [
        ChecklistItemId.location,
        ChecklistItemId.preciseLocation,
      ]);
      expect(list.first.status, ChecklistStatus.warning);
      expect(list.first.action, ChecklistAction.openAppSettings);
      expect(isReliabilityReady(list), isTrue);
    });

    test('Sempre: ok', () {
      final list = buildReliabilityChecklist(
        ios.copyWith(location: LocationAccess.always),
      );
      expect(list.first.status, ChecklistStatus.ok);
    });
  });

  group('manufacturerGuide', () {
    test('cada marca tem passos; Xiaomi e Samsung tem atalho proprio', () {
      for (final m in Manufacturer.values) {
        expect(manufacturerGuide(m).steps, isNotEmpty);
      }
      expect(manufacturerGuide(Manufacturer.xiaomi).shortcuts, isNotEmpty);
      expect(manufacturerGuide(Manufacturer.samsung).shortcuts, isNotEmpty);
      expect(manufacturerGuide(Manufacturer.generic).shortcuts, isEmpty);
    });
  });
}
