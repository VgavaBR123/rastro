// Implementacao da borda de localizacao sobre o plugin `geolocator`.
//
// Clean room a partir de relatorios/03-gravacao-gps.md e 99-proposta-app.md.
// Decisoes espelhadas do estudo (defensaveis, nada secreto):
//  - alta precisao, intervalo alvo de 1 s, deslocamento minimo 0 (a decisao de
//    descartar amostra e do nosso pipeline, nao do provedor);
//  - no Android, o foreground service `location` com notificacao persistente e
//    wake lock e o NOSSO (lib/recording/service/, via flutter_foreground_task),
//    com os botoes de controle. O geolocator NAO sobe servico proprio
//    (sem foregroundNotificationConfig): sem a config, o plugin registra as
//    atualizacoes direto no processo do app, e o Android continua entregando
//    localizacao em segundo plano porque o processo tem um FGS de tipo
//    `location` iniciado com o app visivel (acesso "enquanto em uso");
//  - altitude MSL pelo MslAltitudeConverter injetado, com fallback para a
//    altitude crua (relatorio 03);
//  - no iOS, Core Location com background updates e activityType fitness.
// A conversao Position -> LocationSample fica numa funcao pura de topo
// (`mapPosition`), testavel sem o plugin.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
// AndroidSettings e AppleSettings sao
// reexportados por geolocator.dart, entao nao precisamos importar os
// sub-pacotes de plataforma diretamente.

import 'package:strava_estudo_app/platform/msl_altitude.dart';
import 'package:strava_estudo_app/recording/domain/geo.dart';
import 'package:strava_estudo_app/recording/domain/location_sample.dart';
import 'package:strava_estudo_app/recording/source/location_source.dart';
import 'package:strava_estudo_app/recording/source/monotonic_clock.dart';

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
  final double? horizontalAccuracy = (p.hasAccuracy && p.accuracy > 0)
      ? p.accuracy
      : null;

  final double? verticalAccuracy = p.hasAltitudeAccuracy
      ? p.altitudeAccuracy
      : null;

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

/// Troca a altitude da amostra pela altitude MSL do [converter], quando ele
/// devolve valor; senao mantem a crua (elipsoidal). Sem altitude, nada muda.
Future<LocationSample> withMslAltitude(
  LocationSample s,
  MslAltitudeConverter converter,
) async {
  final double? raw = s.position.altitudeMeters;
  if (raw == null) return s;
  double? msl;
  try {
    msl = await converter.toMsl(
      latitude: s.position.latitude,
      longitude: s.position.longitude,
      ellipsoidAltitudeMeters: raw,
    );
  } catch (_) {
    msl = null; // o contrato diz que nao lanca; defesa extra
  }
  if (msl == null || !msl.isFinite) return s;
  return LocationSample(
    position: GeoPoint(
      latitude: s.position.latitude,
      longitude: s.position.longitude,
      altitudeMeters: msl,
    ),
    wallClockMs: s.wallClockMs,
    monotonicMs: s.monotonicMs,
    horizontalAccuracyMeters: s.horizontalAccuracyMeters,
    verticalAccuracyMeters: s.verticalAccuracyMeters,
    speedMetersPerSecond: s.speedMetersPerSecond,
    bearingDegrees: s.bearingDegrees,
  );
}

/// Fonte de localizacao concreta baseada no plugin `geolocator`.
class GeolocatorLocationSource implements LocationSource {
  /// Forca o uso do `LocationManager` do Android no lugar do
  /// FusedLocationProvider do Play Services.
  ///
  /// Em aparelho real queremos o fused (melhor fusao de sensores e economia de
  /// bateria), por isso o padrao e false. No EMULADOR o fused nao recebe as
  /// posicoes injetadas por `adb emu geo fix` (elas entram no provedor `gps`
  /// cru), entao para testar a gravacao no emulador este flag precisa ser true.
  final bool forceLocationManager;

  /// Conversao elipsoide -> MSL. Padrao: sem conversao (altitude crua).
  final MslAltitudeConverter mslConverter;

  /// Relogio monotonico compartilhado com o acelerometro. Reiniciado a cada
  /// [positions] (a base da sessao comeca em 0).
  final MonotonicClock clock;

  GeolocatorLocationSource({
    this.forceLocationManager = false,
    this.mslConverter = const NoMslAltitudeConverter(),
    MonotonicClock? clock,
  }) : clock = clock ?? MonotonicClock();

  StreamSubscription<LocationSample>? _subscription;

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
    final controller = StreamController<LocationSample>();

    controller.onListen = () {
      // Relogio monotonico da sessao de stream: imune a ajustes do relogio de
      // parede, usado pelos deltas de tempo do filtro de aceleracao.
      clock.restart();
      _subscription =
          Geolocator.getPositionStream(locationSettings: _buildSettings())
              // Carimbo monotonico NA CHEGADA, antes da conversao assincrona.
              .map((position) => mapPosition(position, clock.nowMs))
              // asyncMap preserva a ordem das amostras mesmo com a conversao MSL
              // assincrona (a esteira e serial, relatorio 03).
              .asyncMap((sample) => withMslAltitude(sample, mslConverter))
              .listen(
                controller.add,
                onError: controller.addError,
                onDone: controller.close,
              );
    };

    controller.onCancel = () async {
      await _subscription?.cancel();
      _subscription = null;
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
          forceLocationManager: forceLocationManager,
          // Sem foregroundNotificationConfig: o servico em primeiro plano e o
          // da gravacao (RecordingService), com uma unica notificacao.
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
