// Novo local protegido no mapa (F02): a pessoa arrasta o mapa ate o ponto
// (mira fixa no centro), da um nome e escolhe o raio. Fora do Android/iOS
// (testes no host) o mapa nativo nao existe e a tela mostra campos de
// latitude e longitude.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../app/providers.dart';
import '../../core/format/measures.dart';
import '../../privacy/domain/privacy_zone.dart';
import '../../privacy/privacy_providers.dart';
import '../../recording/domain/geo.dart';
import '../components/big_action_button.dart';
import '../components/segmented_selector.dart';
import '../map_style.dart';
import '../route_map.dart';
import '../section_card.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// Raios oferecidos ao criar uma zona (o corte usa ainda o raio aleatorio
/// de 200 a 600 m por atividade, o maior dos dois).
const List<int> kZoneRadiusOptions = [200, 400, 800];

/// Zoom minimo do mapa para salvar: abaixo disso a mira cobre bairros
/// inteiros (e o mapa sem ponto inicial abre no pais todo).
const double kMinZonePickZoom = 13;

/// Gestos do mapa de escolha: o mapa fica dentro de uma lista que rola, e
/// sem um reconhecedor "ansioso" a lista ganha os arrastos verticais e a
/// pessoa nao consegue mover o mapa.
Set<Factory<OneSequenceGestureRecognizer>> zonePickerGestureRecognizers() => {
  Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
};

/// Erro para mostrar ao salvar o ponto do mapa; null se da para salvar.
String? validateMapPick(GeoPoint? center, double? zoom) {
  if (center == null || zoom == null) {
    return 'Arraste o mapa ate o local antes de salvar.';
  }
  if (zoom < kMinZonePickZoom) {
    return 'Aproxime o mapa ate o local antes de salvar.';
  }
  return null;
}

/// Le uma coordenada digitada (aceita virgula); null se invalida ou fora de
/// [-limit, limit].
double? parseCoordinate(String raw, {required double limit}) {
  final v = double.tryParse(raw.trim().replaceAll(',', '.'));
  if (v == null || !v.isFinite || v < -limit || v > limit) return null;
  return v;
}

class AddZoneScreen extends ConsumerStatefulWidget {
  /// Onde o mapa abre (inicio da atividade mais recente); null = visao ampla.
  final GeoPoint? initialCenter;

  /// Forca os campos de coordenada mesmo com mapa nativo (testes).
  final bool forceCoordinateFields;

  const AddZoneScreen({
    super.key,
    this.initialCenter,
    this.forceCoordinateFields = false,
  });

  @override
  ConsumerState<AddZoneScreen> createState() => _AddZoneScreenState();
}

class _AddZoneScreenState extends ConsumerState<AddZoneScreen> {
  final TextEditingController _label = TextEditingController();
  late final TextEditingController _lat = TextEditingController(
    text: widget.initialCenter?.latitude.toStringAsFixed(6) ?? '',
  );
  late final TextEditingController _lon = TextEditingController(
    text: widget.initialCenter?.longitude.toStringAsFixed(6) ?? '',
  );
  int _radius = kZoneRadiusOptions.first;
  GeoPoint? _mapCenter;
  double? _mapZoom;
  String? _mapError;
  String? _latError;
  String? _lonError;
  bool _busy = false;

  bool get _useMap => nativeMapSupported && !widget.forceCoordinateFields;

  @override
  void initState() {
    super.initState();
    _mapCenter = widget.initialCenter;
    if (widget.initialCenter != null) _mapZoom = kUserZoom;
  }

  @override
  void dispose() {
    _label.dispose();
    _lat.dispose();
    _lon.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    GeoPoint? point;
    if (_useMap) {
      final error = validateMapPick(_mapCenter, _mapZoom);
      setState(() => _mapError = error);
      if (error == null) point = _mapCenter;
    } else {
      final lat = parseCoordinate(_lat.text, limit: 90);
      final lon = parseCoordinate(_lon.text, limit: 180);
      setState(() {
        _latError = lat == null ? 'Coordenada invalida' : null;
        _lonError = lon == null ? 'Coordenada invalida' : null;
      });
      if (lat != null && lon != null) {
        point = GeoPoint(latitude: lat, longitude: lon);
      }
    }
    if (point == null) return;
    setState(() => _busy = true);
    try {
      // Nome vazio: o repositorio usa "Local protegido" (nunca "Casa", que a
      // deteccao automatica usa para saber se a casa ja esta protegida).
      await ref
          .read(privacyRepositoryProvider)
          .addZone(
            PrivacyZone(
              latitude: point.latitude,
              longitude: point.longitude,
              radiusMeters: _radius.toDouble(),
              label: _label.text.trim(),
            ),
          );
    } catch (e) {
      debugPrint('Falha ao salvar local protegido: $e');
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nao foi possivel salvar o local. Tente de novo.'),
        ),
      );
      return;
    }
    ref.invalidate(privacyZonesProvider);
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final metric = ref.watch(settingsProvider).useMetric;
    final muted = AppText.label.copyWith(color: c.textMuted);
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        top: false,
        child: Column(
          key: const Key('add_zone_screen'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppShape.gutter,
                  0,
                  AppShape.gutter,
                  16,
                ),
                children: [
                  const ScreenTitle('Novo local protegido'),
                  if (_useMap) ...[
                    _ZonePickerMap(
                      initialCenter: widget.initialCenter,
                      onCameraChanged: (p, zoom) {
                        _mapCenter = p;
                        _mapZoom = zoom;
                        if (_mapError != null &&
                            validateMapPick(p, zoom) == null) {
                          setState(() => _mapError = null);
                        }
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                      child: Text(
                        'Arraste o mapa ate o local, sob a mira.',
                        style: muted,
                      ),
                    ),
                    if (_mapError != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                        child: Text(
                          _mapError!,
                          key: const Key('zone_map_error'),
                          style: AppText.label.copyWith(color: c.danger),
                        ),
                      ),
                  ] else ...[
                    Text('Latitude', style: muted),
                    const SizedBox(height: 6),
                    TextField(
                      key: const Key('zone_lat'),
                      controller: _lat,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: InputDecoration(errorText: _latError),
                    ),
                    const SizedBox(height: 12),
                    Text('Longitude', style: muted),
                    const SizedBox(height: 6),
                    TextField(
                      key: const Key('zone_lon'),
                      controller: _lon,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: InputDecoration(errorText: _lonError),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text('Nome', style: muted),
                  const SizedBox(height: 6),
                  TextField(
                    key: const Key('zone_label'),
                    controller: _label,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Casa, trabalho...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Raio', style: muted),
                  const SizedBox(height: 6),
                  SegmentedSelector<int>(
                    options: [
                      for (final r in kZoneRadiusOptions)
                        SegmentOption(
                          key: Key('zone_radius_$r'),
                          value: r,
                          label: formatDistance(r.toDouble(), metric: metric),
                          role: c.subida,
                        ),
                    ],
                    selected: _radius,
                    onChanged: _busy
                        ? null
                        : (r) => setState(() => _radius = r),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                    child: Text(
                      'Cada atividade ainda corta num raio sorteado entre 200 e 600 m, '
                      'para o centro nao aparecer.',
                      style: muted,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppShape.gutter,
                8,
                AppShape.gutter,
                16,
              ),
              child: BigActionButton(
                key: const Key('zone_save'),
                label: 'Salvar local',
                icon: Icons.check_rounded,
                onPressed: _busy ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mapa com mira fixa no centro; avisa o centro e o zoom da camera quando
/// para.
class _ZonePickerMap extends ConsumerStatefulWidget {
  final GeoPoint? initialCenter;
  final void Function(GeoPoint center, double zoom) onCameraChanged;
  const _ZonePickerMap({
    required this.initialCenter,
    required this.onCameraChanged,
  });

  @override
  ConsumerState<_ZonePickerMap> createState() => _ZonePickerMapState();
}

class _ZonePickerMapState extends ConsumerState<_ZonePickerMap> {
  MapLibreMapController? _controller;

  void _onIdle() {
    final camera = _controller?.cameraPosition;
    if (camera == null) return;
    widget.onCameraChanged(
      GeoPoint(
        latitude: camera.target.latitude,
        longitude: camera.target.longitude,
      ),
      camera.zoom,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final start = widget.initialCenter;
    final style = effectiveMapStyle(
      ref.watch(mapStyleChoiceProvider),
      Theme.of(context).brightness,
    ).url;
    return SizedBox(
      height: 320,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppShape.panel),
        child: Stack(
          fit: StackFit.expand,
          children: [
            MapLibreMap(
              styleString: style,
              initialCameraPosition: CameraPosition(
                target: start == null
                    ? const LatLng(-15.8, -47.9)
                    : LatLng(start.latitude, start.longitude),
                zoom: start == null ? 3 : kUserZoom,
              ),
              trackCameraPosition: true,
              // Dentro da lista que rola: o mapa precisa ganhar os arrastos.
              gestureRecognizers: zonePickerGestureRecognizers(),
              onMapCreated: (ctrl) => _controller = ctrl,
              onCameraIdle: _onIdle,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
              myLocationEnabled: false,
            ),
            IgnorePointer(
              child: Center(
                child: Icon(
                  Icons.add_circle_outline_rounded,
                  size: AppIconSize.crosshair,
                  color: c.subida.fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
