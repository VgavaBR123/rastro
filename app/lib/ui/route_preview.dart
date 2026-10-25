// Visualizacao simples da rota (polyline) com CustomPainter, sem dependencia de
// mapa nativo. Para o MVP: mostra o traçado normalizado na area disponivel.
// Upgrade futuro (etapa 99): MapLibre com tiles reais (exige toolchain JDK 21).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../recording/domain/geo.dart';

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
  const RoutePreview({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: CustomPaint(
        painter: _RoutePainter(route, Theme.of(context).colorScheme.primary),
        child: route.isEmpty
            ? const Center(child: Text('Aguardando GPS...'))
            : const SizedBox.expand(),
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  final List<GeoPoint> route;
  final Color color;
  _RoutePainter(this.route, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final offsets = projectRoute(route, size);
    if (offsets.length < 2) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (final o in offsets.skip(1)) {
      path.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_RoutePainter old) => old.route.length != route.length;
}
