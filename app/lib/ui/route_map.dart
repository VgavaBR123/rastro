// Mapa real da rota com MapLibre (tiles vetoriais do OpenFreeMap, dados
// OpenStreetMap, sem chave de API). Clean room a partir de
// relatorios/99-proposta-app.md ("maps: MapLibre atras de interface").
//
// So Android/iOS tem o mapa nativo. Nos testes (rodam no host) e em outras
// plataformas, cai no RoutePreview (CustomPainter), com a mesma entrada.
library;

import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../recording/domain/geo.dart';
import 'route_preview.dart';

/// Estilo do mapa: OpenFreeMap Liberty (gratuito, sem chave, OSM).
const String kMapStyleUrl = MapLibreStyles.openfreemapLiberty;

/// Menor lado (graus) da caixa de enquadramento: evita zoom infinito numa
/// rota de um ponto so ou parada no lugar (~110 m).
const double kMinBoundsSpanDegrees = 0.001;

const String _sourceId = 'route';
const String _layerId = 'route-line';

/// A rota como FeatureCollection GeoJSON (ordem [lon, lat]). Funcao pura.
Map<String, dynamic> routeFeatureCollection(List<GeoPoint> route) => {
      'type': 'FeatureCollection',
      'features': [
        if (route.length >= 2)
          {
            'type': 'Feature',
            'properties': <String, dynamic>{},
            'geometry': {
              'type': 'LineString',
              'coordinates': [
                for (final p in route) [p.longitude, p.latitude],
              ],
            },
          },
      ],
    };

/// Caixa que envolve a rota, com lado minimo [kMinBoundsSpanDegrees].
/// Null sem pontos. Funcao pura.
LatLngBounds? routeBounds(List<GeoPoint> route) {
  if (route.isEmpty) return null;
  var minLat = route.first.latitude, maxLat = minLat;
  var minLon = route.first.longitude, maxLon = minLon;
  for (final p in route) {
    minLat = math.min(minLat, p.latitude);
    maxLat = math.max(maxLat, p.latitude);
    minLon = math.min(minLon, p.longitude);
    maxLon = math.max(maxLon, p.longitude);
  }
  double grow(double span) => math.max(0, kMinBoundsSpanDegrees - span) / 2;
  final dLat = grow(maxLat - minLat), dLon = grow(maxLon - minLon);
  return LatLngBounds(
    southwest: LatLng(minLat - dLat, minLon - dLon),
    northeast: LatLng(maxLat + dLat, maxLon + dLon),
  );
}

/// Se o mapa nativo existe nesta plataforma.
bool get nativeMapSupported =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS);

enum RouteMapMode {
  /// Gravacao: segue o ultimo ponto.
  follow,

  /// Detalhe: enquadra a rota inteira.
  fit,
}

class RouteMap extends StatelessWidget {
  final List<GeoPoint> route;
  final RouteMapMode mode;
  final double height;

  const RouteMap({
    super.key,
    required this.route,
    this.mode = RouteMapMode.fit,
    this.height = 260,
  });

  @override
  Widget build(BuildContext context) {
    if (!nativeMapSupported) return RoutePreview(route: route);
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _NativeRouteMap(route: route, mode: mode),
      ),
    );
  }
}

class _NativeRouteMap extends StatefulWidget {
  final List<GeoPoint> route;
  final RouteMapMode mode;
  const _NativeRouteMap({required this.route, required this.mode});

  @override
  State<_NativeRouteMap> createState() => _NativeRouteMapState();
}

class _NativeRouteMapState extends State<_NativeRouteMap> {
  MapLibreMapController? _controller;
  bool _styleReady = false;
  int _drawnPoints = -1;

  @override
  void didUpdateWidget(_NativeRouteMap old) {
    super.didUpdateWidget(old);
    if (widget.route.length != _drawnPoints) _sync();
  }

  Future<void> _onStyleLoaded() async {
    final c = _controller;
    if (c == null) return;
    final color = _hex(Theme.of(context).colorScheme.primary);
    await c.addGeoJsonSource(_sourceId, routeFeatureCollection(widget.route));
    await c.addLineLayer(
      _sourceId,
      _layerId,
      LineLayerProperties(
        lineColor: color,
        lineWidth: 5,
        lineCap: 'round',
        lineJoin: 'round',
      ),
    );
    _styleReady = true;
    _drawnPoints = widget.route.length;
    await _moveCamera(animate: false);
  }

  Future<void> _sync() async {
    final c = _controller;
    if (c == null || !_styleReady) return;
    _drawnPoints = widget.route.length;
    await c.setGeoJsonSource(_sourceId, routeFeatureCollection(widget.route));
    await _moveCamera(animate: true);
  }

  Future<void> _moveCamera({required bool animate}) async {
    final c = _controller;
    final route = widget.route;
    if (c == null || route.isEmpty) return;
    final CameraUpdate update;
    if (widget.mode == RouteMapMode.follow) {
      final last = route.last;
      update = CameraUpdate.newLatLngZoom(LatLng(last.latitude, last.longitude), 16);
    } else {
      update = CameraUpdate.newLatLngBounds(
        routeBounds(route)!,
        left: 32, top: 32, right: 32, bottom: 32,
      );
    }
    if (animate) {
      await c.animateCamera(update);
    } else {
      await c.moveCamera(update);
    }
  }

  @override
  Widget build(BuildContext context) {
    final first = widget.route.isEmpty ? null : widget.route.first;
    return MapLibreMap(
      styleString: kMapStyleUrl,
      initialCameraPosition: CameraPosition(
        // Sem pontos ainda: visao ampla ate o primeiro fix chegar.
        target: first == null
            ? const LatLng(-15.8, -47.9)
            : LatLng(first.latitude, first.longitude),
        zoom: first == null ? 3 : 15,
      ),
      onMapCreated: (c) => _controller = c,
      onStyleLoadedCallback: _onStyleLoaded,
      // O mapa fica dentro de uma tela rolavel: gestos so com intencao clara.
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      myLocationEnabled: false,
    );
  }

  static String _hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
}
