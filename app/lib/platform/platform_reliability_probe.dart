// Implementacao real do [ReliabilityProbe] (F01).
//  - Bateria: isencao de otimizacao pelo flutter_foreground_task (Android).
//  - Localizacao e precisao: geolocator (Android e iOS).
//  - Notificacoes: flutter_foreground_task (Android; no iOS a gravacao nao usa
//    notificacao).
//  - Fabricante e telas de ajuste dele: canal nativo `stravaestudo/device`
//    (DeviceSettingsChannel.kt). No iOS o canal nao existe e tudo cai no
//    fallback.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

import '../recording/domain/reliability_checklist.dart';
import 'reliability_probe.dart';

/// Canal nativo com o fabricante do aparelho e a abertura de telas de ajuste.
class DeviceSettingsChannel {
  const DeviceSettingsChannel({this.channel = defaultChannel});

  static const String channelName = 'stravaestudo/device';
  static const MethodChannel defaultChannel = MethodChannel(channelName);

  final MethodChannel channel;

  /// Build.MANUFACTURER no Android; null fora dele.
  Future<String?> manufacturer() async {
    try {
      return await channel.invokeMethod<String>('manufacturer');
    } catch (_) {
      return null;
    }
  }

  /// Abre uma tela de outro app (ajuste do fabricante). False se nao existe.
  Future<bool> openComponent(ManufacturerShortcut s) async {
    try {
      final ok = await channel.invokeMethod<bool>('openComponent', {
        'package': s.packageName,
        'class': s.className,
      });
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }
}

LocationAccess locationAccessFrom(LocationPermission p) => switch (p) {
  LocationPermission.always => LocationAccess.always,
  LocationPermission.whileInUse => LocationAccess.whileInUse,
  LocationPermission.denied => LocationAccess.denied,
  LocationPermission.deniedForever => LocationAccess.deniedForever,
  LocationPermission.unableToDetermine => LocationAccess.unknown,
};

class PlatformReliabilityProbe implements ReliabilityProbe {
  final DeviceSettingsChannel device;
  const PlatformReliabilityProbe({this.device = const DeviceSettingsChannel()});

  bool get _android => defaultTargetPlatform == TargetPlatform.android;
  bool get _ios => defaultTargetPlatform == TargetPlatform.iOS;

  static Future<T?> _safe<T>(Future<T> Function() f) async {
    try {
      return await f();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ReliabilitySnapshot> read() async {
    final permission = await _safe(Geolocator.checkPermission);
    final accuracy = await _safe(Geolocator.getLocationAccuracy);
    final granted =
        permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
    return ReliabilitySnapshot(
      platform: _android
          ? DevicePlatform.android
          : _ios
          ? DevicePlatform.ios
          : DevicePlatform.other,
      manufacturer: _android ? await device.manufacturer() : null,
      batteryOptimizationIgnored: _android
          ? await _safe(
              () => FlutterForegroundTask.isIgnoringBatteryOptimizations,
            )
          : null,
      location: permission == null
          ? LocationAccess.unknown
          : locationAccessFrom(permission),
      // Sem permissao nao da para saber a precisao.
      preciseLocation: !granted || accuracy == null
          ? null
          : accuracy == LocationAccuracyStatus.precise,
      notificationsGranted: _android
          ? await _safe(
              () async =>
                  await FlutterForegroundTask.checkNotificationPermission() ==
                  NotificationPermission.granted,
            )
          : null,
    );
  }

  @override
  Future<bool> run(ChecklistAction action) async {
    switch (action) {
      case ChecklistAction.none:
        return false;
      case ChecklistAction.openBatterySettings:
        return await _safe(
              FlutterForegroundTask.openIgnoreBatteryOptimizationSettings,
            ) ??
            false;
      case ChecklistAction.requestLocation:
        final p = await _safe(Geolocator.requestPermission);
        return p != null;
      case ChecklistAction.openAppSettings:
        return await _safe(Geolocator.openAppSettings) ?? false;
      case ChecklistAction.requestNotifications:
        final p = await _safe(
          FlutterForegroundTask.requestNotificationPermission,
        );
        // Negada de vez: o pedido nao aparece mais; so pelos ajustes.
        if (p == NotificationPermission.granted) return true;
        return await _safe(Geolocator.openAppSettings) ?? false;
      case ChecklistAction.openManufacturerSettings:
        final guide = manufacturerGuide(
          detectManufacturer(await device.manufacturer()),
        );
        for (final s in guide.shortcuts) {
          if (await device.openComponent(s)) return true;
        }
        return await _safe(Geolocator.openAppSettings) ?? false;
    }
  }
}
