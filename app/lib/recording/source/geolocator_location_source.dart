// Implementacao da borda de localizacao sobre o plugin `geolocator`.
//
// Clean room a partir de relatorios/03-gravacao-gps.md e 99-proposta-app.md.
// Decisoes espelhadas do estudo (defensaveis, nada secreto):
//  - alta precisao, intervalo alvo de 1 s, deslocamento minimo 0 (a decisao de
//    descartar amostra e do nosso pipeline, nao do provedor);
//  - no Android, foreground service `location` com notificacao persistente e
//    wake lock, para manter o GPS com o app fora da tela (Android 14+);
//  - no iOS, Core Location com background updates e activityType fitness.
// A conversao Position -> LocationSample fica numa funcao pura de topo
// (`mapPosition`), testavel sem o plugin.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
// AndroidSettings, AppleSettings e ForegroundNotificationConfig sao
// reexportados por geolocator.dart, entao nao precisamos importar os
// sub-pacotes de plataforma diretamente.

import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/location_sample.dart';
import 'package:strava_estudo_app/recording/source/location_source.dart';

/// Converte uma [Position] do geolocator numa [LocationSample] do dominio.
///
/// Funcao PURA, de topo e sem dependencia de I/O ou de estado do plugin, para
/// poder ser testada isoladamente. As flags `has*` da [Position] carregam a
/// distincao que o nosso modelo precisa (ver location_sample.dart): "o provedor
/// nao informou" (flag false -> null) vs. "informou zero" (flag true -> 0.0).
/// O [monotonicMs] vem de fora porque o relogio monotonico e responsabilidade
/// de quem consome o stream, nao da amostra individual.
LocationSample mapPosition(Position p, int monotonicMs) {
  // Altitude: so repassa quando medida; o dominio ja assume MSL/geoide, mas a
  // correcao elipsoidal->MSL e estagio posterior do pipeline.
  final double? altitude = p.hasAltitude ? p.altitude : null;

  // Precisao horizontal: null quando nao informada; tambem tratamos <= 0 como
  // desconhecida (sentinela), coerente com o portao de sanidade do pipeline.
  final double? horizontalAccuracy =
      (p.hasAccuracy && p.accuracy > 0) ? p.accuracy : null;

  final double? verticalAccuracy =
      p.hasAltitudeAccuracy ? p.altitudeAccuracy : null;

  final double? speed = p.hasSpeed ? p.speed : null;

  // `heading` carrega o course-over-ground (rumo de deslocamento).
  final double? bearing = p.hasHeading ? p.heading : null;

  return LocationSample(
    position: GeoPoint(
      latitude: p.latitude,
      longitude: p.longitude,
      altitudeMeters: altitude,
    ),
    horizontalAccuracyMeters: horizontalAccuracy,
    verticalAccuracyMeters: verticalAccuracy,
    speedMetersPerSecond: speed,
    bearingDegrees: bearing,
    wallClockMs: p.timestamp.millisecondsSinceEpoch,
    monotonicMs: monotonicMs,
  );
}

/// Fonte de localizacao concreta baseada no plugin `geolocator`.
class GeolocatorLocationSource implements LocationSource {
  StreamSubscription<Position>? _subscription;

  @override
  Future<bool> ensurePermission() async {
    // Sem servico de localizacao ligado, nem adianta pedir permissao.
    if (!await Geolocator.isLocationServiceEnabled()) {
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // Aceita somente permissao suficiente para gravar.
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  @override
  Stream<LocationSample> positions() {
    // Relogio monotonico da sessao de stream: imune a ajustes do relogio de
    // parede, usado pelos deltas de tempo do filtro de aceleracao.
    final stopwatch = Stopwatch()..start();

    final controller = StreamController<LocationSample>();

    controller.onListen = () {
      _subscription = Geolocator.getPositionStream(
        locationSettings: _buildSettings(),
      ).listen(
        (position) =>
            controller.add(mapPosition(position, stopwatch.elapsedMilliseconds)),
        onError: controller.addError,
        onDone: controller.close,
      );
    };

    controller.onCancel = () async {
      await _subscription?.cancel();
      _subscription = null;
      stopwatch.stop();
    };

    return controller.stream;
  }

  @override
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  /// Monta os ajustes de localizacao por plataforma.
  LocationSettings _buildSettings() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
          intervalDuration: const Duration(seconds: 1),
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationTitle: 'Gravando atividade',
            notificationText: 'Registrando sua rota',
            enableWakeLock: true,
          ),
        );
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return AppleSettings(
          accuracy: LocationAccuracy.best,
          activityType: ActivityType.fitness,
          distanceFilter: 0,
          pauseLocationUpdatesAutomatically: false,
          allowBackgroundLocationUpdates: true,
          showBackgroundLocationIndicator: true,
        );
      default:
        return const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        );
    }
  }
}
