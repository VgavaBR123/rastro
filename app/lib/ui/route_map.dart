// Mapa real da rota com MapLibre (tiles vetoriais do OpenFreeMap, dados
// OpenStreetMap, sem chave de API; estilos em map_style.dart). Clean room a
// partir de relatorios/99-proposta-app.md ("maps: MapLibre atras de interface").
//
// So Android/iOS tem o mapa nativo. Nos testes (rodam no host) e em outras
// plataformas, cai no RoutePreview (CustomPainter), com a mesma entrada.
library;

import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../recording/domain/geo.dart';
import 'map_style.dart';
import 'route_preview.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

/// Menor lado (graus) da caixa de enquadramento: evita zoom infinito numa
/// rota de um ponto so ou parada no lugar (~110 m).
const double kMinBoundsSpanDegrees = 0.001;

/// Zoom de rua ao centralizar na posicao atual.
const double kUserZoom = 15;

const String _sourceId = 'route';
const String _layerId = 'route-line';
const String _haloLayerId = 'route-halo';
const String _startSourceId = 'route-start';
const String _startLayerId = 'route-start-dot';
const String _userSourceId = 'user-position';
const String _userLayerId = 'user-position-dot';

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

/// O ponto de partida como FeatureCollection GeoJSON (vazia sem pontos).
Map<String, dynamic> startFeatureCollection(List<GeoPoint> route) =>
    pointFeatureCollection(route.isEmpty ? null : route.first);

/// Um ponto como FeatureCollection GeoJSON (vazia com null). Funcao pura.
Map<String, dynamic> pointFeatureCollection(GeoPoint? p) => {
      'type': 'FeatureCollection',
      'features': [
        if (p != null)
          {
            'type': 'Feature',
            'properties': <String, dynamic>{},
            'geometry': {
              'type': 'Point',
              'coordinates': [p.longitude, p.latitude],
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

  /// Altura fixa; null ocupa todo o espaco do pai (mapa em tela cheia).
  final double? height;

  /// Cor da rota; padrao a cor primaria. As telas passam a cor do esporte.
  final Color? color;

  /// Raio dos cantos; 0 no mapa em tela cheia.
  final double borderRadius;

  /// Texto enquanto nao ha pontos.
  final String emptyLabel;

  /// Posicao atual (tela Gravar): sem rota, a camera centraliza nela e
  /// desenha um ponto ciano.
  final GeoPoint? userLocation;

  /// Muda a cada pedido de recentralizar (toque no chip de GPS).
  final int recenterRequest;

  const RouteMap({
    super.key,
    required this.route,
    this.mode = RouteMapMode.fit,
    this.height = 260,
    this.color,
    this.borderRadius = AppShape.tile,
    this.emptyLabel = 'Aguardando GPS...',
    this.userLocation,
    this.recenterRequest = 0,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final lineColor = color ?? c.primary;
    final brightness = Theme.of(context).brightness;
    // So o mapa nativo le a escolha de estilo (o fallback roda sem ProviderScope).
    final Widget map = nativeMapSupported
        ? Consumer(
            builder: (_, ref, _) => _NativeRouteMap(
              route: route,
              mode: mode,
              styleUrl: effectiveMapStyle(ref.watch(mapStyleChoiceProvider), brightness).url,
              color: lineColor,
              dotColor: c.ciano.fill,
              dotRing: c.surface,
              userLocation: userLocation,
              recenterRequest: recenterRequest,
            ),
          )
        : ColoredBox(
            color: c.map,
            child: LayoutBuilder(
              builder: (_, box) => RoutePreview(
                key: const Key('route_map_fallback'),
                route: route.isEmpty && userLocation != null ? [userLocation!] : route,
                color: lineColor,
                height: box.maxHeight.isFinite ? box.maxHeight : 220,
                halo: true,
                showStart: true,
                emptyLabel: emptyLabel,
                compactWhenEmpty: false,
              ),
            ),
          );
    final clipped = borderRadius == 0
        ? map
        : ClipRRect(borderRadius: BorderRadius.circular(borderRadius), child: map);
    if (height == null) return SizedBox.expand(child: clipped);
    return SizedBox(height: height, width: double.infinity, child: clipped);
  }
}

class _NativeRouteMap extends StatefulWidget {
  final List<GeoPoint> route;
  final RouteMapMode mode;
  final String styleUrl;
  final Color color;
  final Color dotColor;
  final Color dotRing;
  final GeoPoint? userLocation;
  final int recenterRequest;
  const _NativeRouteMap({
    required this.route,
    required this.mode,
    required this.styleUrl,
    required this.color,
    required this.dotColor,
    required this.dotRing,
    required this.userLocation,
    required this.recenterRequest,
  });

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
    if (widget.styleUrl != old.styleUrl) {
      // Trocar o estilo apaga fontes e camadas; o onStyleLoaded redesenha.
      _styleReady = false;
      return;
    }
    if (widget.route.length != _drawnPoints) _sync();
    if (widget.userLocation != old.userLocation ||
        widget.recenterRequest != old.recenterRequest) {
      _syncUser();
    }
  }

  /// Chamado no primeiro estilo e a cada troca de estilo: redesenha tudo.
  Future<void> _onStyleLoaded() async {
    final c = _controller;
    if (c == null) return;
    final style = widget.styleUrl;
    final color = _hex(widget.color);
    try {
      await c.addGeoJsonSource(_sourceId, routeFeatureCollection(widget.route));
      // Relatorio 11: traco de 4,5 na cor do esporte sobre um halo de 12 a ~20%.
      await c.addLineLayer(
        _sourceId,
        _haloLayerId,
        LineLayerProperties(
          lineColor: color,
          lineWidth: 12,
          lineOpacity: 0.2,
          lineCap: 'round',
          lineJoin: 'round',
        ),
      );
      await c.addLineLayer(
        _sourceId,
        _layerId,
        LineLayerProperties(
          lineColor: color,
          lineWidth: 4.5,
          lineCap: 'round',
          lineJoin: 'round',
        ),
      );
      // Ponto de partida e posicao atual em ciano.
      await c.addGeoJsonSource(_startSourceId, startFeatureCollection(widget.route));
      await c.addCircleLayer(_startSourceId, _startLayerId, _dot(5));
      await c.addGeoJsonSource(_userSourceId, pointFeatureCollection(_userDot));
      await c.addCircleLayer(_userSourceId, _userLayerId, _dot(7));
    } catch (_) {
      // Estilo trocado no meio do desenho: o proximo onStyleLoaded refaz.
      return;
    }
    if (!mounted || style != widget.styleUrl) return;
    final firstLoad = _drawnPoints < 0;
    _styleReady = true;
    _drawnPoints = widget.route.length;
    // Na troca de estilo a camera fica onde o usuario deixou.
    if (firstLoad) await _moveCamera(animate: false);
  }

  CircleLayerProperties _dot(double radius) => CircleLayerProperties(
        circleColor: _hex(widget.dotColor),
        circleRadius: radius,
        circleStrokeColor: _hex(widget.dotRing),
        circleStrokeWidth: 2,
      );

  /// Ponto da posicao atual: so enquanto nao ha rota.
  GeoPoint? get _userDot => widget.route.isEmpty ? widget.userLocation : null;

  Future<void> _sync() async {
    final c = _controller;
    if (c == null || !_styleReady) return;
    final before = _drawnPoints;
    _drawnPoints = widget.route.length;
    try {
      await c.setGeoJsonSource(_sourceId, routeFeatureCollection(widget.route));
      if (before <= 0) {
        await c.setGeoJsonSource(_startSourceId, startFeatureCollection(widget.route));
        await c.setGeoJsonSource(_userSourceId, pointFeatureCollection(_userDot));
      }
    } catch (_) {
      return;
    }
    await _moveCamera(animate: true);
  }

  Future<void> _syncUser() async {
    final c = _controller;
    if (c == null || !_styleReady) return;
    try {
      await c.setGeoJsonSource(_userSourceId, pointFeatureCollection(_userDot));
    } catch (_) {
      return;
    }
    await _moveCamera(animate: true);
  }

  Future<void> _moveCamera({required bool animate}) async {
    final c = _controller;
    final route = widget.route;
    final user = widget.userLocation;
    if (c == null) return;
    final CameraUpdate update;
    if (route.isEmpty) {
      if (user == null) return;
      update = CameraUpdate.newLatLngZoom(LatLng(user.latitude, user.longitude), kUserZoom);
    } else if (widget.mode == RouteMapMode.follow) {
      final last = route.last;
      update = CameraUpdate.newLatLngZoom(LatLng(last.latitude, last.longitude), 16);
    } else {
      update = CameraUpdate.newLatLngBounds(
        routeBounds(route)!,
        left: 32, top: 32, right: 32, bottom: 32,
      );
    }
    try {
      if (animate) {
        await c.animateCamera(update);
      } else {
        await c.moveCamera(update);
      }
    } catch (_) {
      // Mapa descartado no meio da animacao.
    }
  }

  @override
  Widget build(BuildContext context) {
    final first = widget.route.isEmpty ? widget.userLocation : widget.route.first;
    return MapLibreMap(
      styleString: widget.styleUrl,
      initialCameraPosition: CameraPosition(
        // Sem pontos nem posicao: visao ampla ate o primeiro fix chegar.
        target: first == null
            ? const LatLng(-15.8, -47.9)
            : LatLng(first.latitude, first.longitude),
        zoom: first == null ? 3 : kUserZoom,
      ),
      onMapCreated: (c) => _controller = c,
      onStyleLoadedCallback: _onStyleLoaded,
      // O mapa pode ficar dentro de uma tela rolavel: gestos so com intencao clara.
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      myLocationEnabled: false,
    );
  }

  static String _hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
}
