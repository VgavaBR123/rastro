// Visualizacao simples da rota (polyline) com CustomPainter, sem dependencia de
// mapa nativo: mostra o tracado normalizado na area disponivel. Usada pelo
// RouteMap onde nao ha mapa nativo (testes no host, plataformas sem MapLibre)
// e como miniatura da rota no ActivityCard (cor do esporte, halo e partida).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../recording/domain/geo.dart';
import 'theme/app_colors.dart';
import 'theme/app_typography.dart';

/// Projeta os pontos (lat/lon) para offsets de tela dentro de [size],
/// preservando a proporcao e aplicando [padding]. Funcao pura (testavel).
/// Projecao equiretangular local (boa para trajetos curtos):
/// x ~ lon*cos(latMedia), y ~ lat (invertido no eixo de tela).
List<Offset> projectRoute(List<GeoPoint> points, Size size, {double padding = 12}) {
  if (points.isEmpty) return const [];
  final latMean =
      points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
  final cosLat = math.cos(latMean * math.pi / 180.0);

  final xs = points.map((p) => p.longitude * cosLat).toList();
  final ys = points.map((p) => p.latitude).toList();

  final minX = xs.reduce(math.min), maxX = xs.reduce(math.max);
  final minY = ys.reduce(math.min), maxY = ys.reduce(math.max);
  final spanX = maxX - minX;
  final spanY = maxY - minY;

  final w = size.width - 2 * padding;
  final h = size.height - 2 * padding;
  final scaleX = spanX > 0 ? w / spanX : 0.0;
  final scaleY = spanY > 0 ? h / spanY : 0.0;
  final scale = _uniformScale(scaleX, scaleY);

  final drawnW = spanX * scale;
  final drawnH = spanY * scale;
  final offX = padding + (w - drawnW) / 2;
  final offY = padding + (h - drawnH) / 2;

  final out = <Offset>[];
  for (var i = 0; i < points.length; i++) {
    final x = offX + (xs[i] - minX) * scale;
    final y = offY + (maxY - ys[i]) * scale; // inverte latitude no eixo de tela
    out.add(Offset(x, y));
  }
  return out;
}

/// Menor escala positiva entre os eixos (mantem proporcao, cabe nos dois).
double _uniformScale(double a, double b) {
  if (a <= 0) return b <= 0 ? 1.0 : b;
  if (b <= 0) return a;
  return math.min(a, b);
}

class RoutePreview extends StatelessWidget {
  final List<GeoPoint> route;

  /// Cor do traco; padrao a cor primaria do tema.
  final Color? color;

  final double height;

  /// Halo largo e translucido sob o traco (miniatura do cartao).
  final bool halo;

  /// Ponto ciano no inicio da rota.
  final bool showStart;

  /// Texto quando ainda nao ha pontos.
  final String emptyLabel;

  const RoutePreview({
    super.key,
    required this.route,
    this.color,
    this.height = 220,
    this.halo = false,
    this.showStart = false,
    this.emptyLabel = 'Aguardando GPS...',
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _RoutePainter(
          route,
          color ?? c.primary,
          halo: halo,
          start: showStart ? c.ciano.fill : null,
          startRing: c.surface,
        ),
        child: route.isEmpty
            ? Center(
                child: Text(emptyLabel, style: AppText.label.copyWith(color: c.textMuted)),
              )
            : const SizedBox.expand(),
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  final List<GeoPoint> route;
  final Color color;
  final bool halo;
  final Color? start;
  final Color startRing;
  _RoutePainter(this.route, this.color, {this.halo = false, this.start, required this.startRing});

  @override
  void paint(Canvas canvas, Size size) {
    final offsets = projectRoute(route, size);
    if (offsets.length < 2) return;
    final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (final o in offsets.skip(1)) {
      path.lineTo(o.dx, o.dy);
    }
    Paint stroke(Color c, double w) => Paint()
      ..color = c
      ..strokeWidth = w
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    // Relatorio 11: traco de 4,5 sobre um halo de 12 na propria cor a ~20%.
    if (halo) canvas.drawPath(path, stroke(color.withValues(alpha: 0.2), 12));
    canvas.drawPath(path, stroke(color, halo ? 4.5 : 4));
    if (start != null) {
      canvas.drawCircle(offsets.first, 6.5, Paint()..color = startRing);
      canvas.drawCircle(offsets.first, 4.5, Paint()..color = start!);
    }
  }

  @override
  bool shouldRepaint(_RoutePainter old) =>
      old.route.length != route.length ||
      old.color != color ||
      old.halo != halo ||
      old.start != start ||
      old.startRing != startRing;
}
