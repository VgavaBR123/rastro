// Leitura pontual da posicao (tela Gravar centraliza o mapa antes de gravar).
// Nao e o stream da gravacao: so a ultima posicao conhecida e um fix atual.
// Respeita o FORCE_LOCATION_MANAGER como a GeolocatorLocationSource (no
// emulador o fused nao recebe os fixes de `adb emu geo fix`).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../app/providers.dart' show kForceLocationManager;
import '../domain/geo.dart';

abstract class CurrentPositionSource {
  /// Se ha servico ligado e permissao de uso. Com [request], pede a permissao
  /// quando ainda nao foi negada de vez.
  Future<bool> hasAccess({bool request = false});

  /// Ultima posicao conhecida (rapida, pode ser velha); null sem nenhuma.
  Future<GeoPoint?> lastKnown();

  /// Um fix atual; null se nao vier a tempo.
  Future<GeoPoint?> current();
}

class GeolocatorCurrentPosition implements CurrentPositionSource {
  final bool forceLocationManager;
  final Duration timeout;

  const GeolocatorCurrentPosition({
    this.forceLocationManager = false,
    this.timeout = const Duration(seconds: 15),
  });

  @override
  Future<bool> hasAccess({bool request = false}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return false;
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied && request) {
        p = await Geolocator.requestPermission();
      }
      return p == LocationPermission.whileInUse || p == LocationPermission.always;
    } catch (_) {
      return false; // sem plugin (testes no host) ou erro do provedor
    }
  }

  @override
  Future<GeoPoint?> lastKnown() async {
    try {
      final p = await Geolocator.getLastKnownPosition(
        forceAndroidLocationManager: forceLocationManager,
      );
      return p == null ? null : _point(p);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<GeoPoint?> current() async {
    try {
      final p = await Geolocator.getCurrentPosition(locationSettings: _settings());
      return _point(p);
    } catch (_) {
      return null; // timeout, sem permissao ou sem provedor
    }
  }

  LocationSettings _settings() => defaultTargetPlatform == TargetPlatform.android
      ? AndroidSettings(
          accuracy: LocationAccuracy.high,
          forceLocationManager: forceLocationManager,
          timeLimit: timeout,
        )
      : LocationSettings(accuracy: LocationAccuracy.high, timeLimit: timeout);

  static GeoPoint _point(Position p) =>
      GeoPoint(latitude: p.latitude, longitude: p.longitude);
}

/// Fonte da posicao pontual; os testes sobrescrevem com uma falsa.
final currentPositionSourceProvider = Provider<CurrentPositionSource>(
  (ref) => const GeolocatorCurrentPosition(forceLocationManager: kForceLocationManager),
);
