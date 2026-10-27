// Grafico do perfil de elevacao (CustomPainter proprio, sem biblioteca).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../activity/elevation_profile.dart';
import '../core/format/measures.dart';

/// Rotulo do eixo de distancia: sempre em km ou mi, uma casa decimal
/// ("0 km", "1.5 km", "0.9 mi").
String formatAxisDistance(double meters, {required bool metric}) {
  final unit = metric ? 'km' : 'mi';
  if (!meters.isFinite || meters <= 0) return '0 $unit';
  final v = meters / (metric ? 1000.0 : 1609.344);
  return '${v.toStringAsFixed(1)} $unit';
}

/// Secao do detalhe com o perfil: titulo, ganho, min/max e o grafico.
class ElevationSection extends StatelessWidget {
  final ElevationProfile profile;
  final bool metric;

  const ElevationSection({
    super.key,
    required this.profile,
    required this.metric,
  });

  @override
  Widget build(BuildContext context) {
    final grey = const TextStyle(color: Colors.grey);
    return Column(
      key: const Key('elevationSection'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Elevacao',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Ganho', style: grey),
            Text(
              formatElevation(profile.gainMeters, metric: metric),
              key: const Key('elevationGain'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 140,
                child: CustomPaint(
                  key: const Key('elevationChart'),
                  painter: ElevationChartPainter(
                    profile: profile,
                    fillColor: Theme.of(context).colorScheme.primary
                        .withValues(alpha: 0.25),
                    lineColor: Theme.of(context).colorScheme.primary,
                    gridColor: Colors.grey.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 140,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatElevation(profile.maxAltitudeMeters, metric: metric),
                    key: const Key('elevationMax'),
                    style: grey,
                  ),
                  Text(
                    formatElevation(profile.minAltitudeMeters, metric: metric),
                    key: const Key('elevationMin'),
                    style: grey,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              formatAxisDistance(profile.startDistanceMeters, metric: metric),
              key: const Key('elevationStartDistance'),
              style: grey,
            ),
            Text(
              formatAxisDistance(profile.endDistanceMeters, metric: metric),
              key: const Key('elevationEndDistance'),
              style: grey,
            ),
          ],
        ),
      ],
    );
  }
}

/// Desenha a area preenchida sob a curva de altitude por distancia.
class ElevationChartPainter extends CustomPainter {
  final ElevationProfile profile;
  final Color fillColor;
  final Color lineColor;
  final Color gridColor;

  ElevationChartPainter({
    required this.profile,
    required this.fillColor,
    required this.lineColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pts = profile.points;
    if (pts.length < 2 || size.isEmpty) return;

    final x0 = profile.startDistanceMeters;
    final dx = math.max(profile.endDistanceMeters - x0, 1e-6);
    // Folga vertical para a curva nao encostar nas bordas; serie plana ganha
    // uma faixa minima para nao dividir por zero.
    var lo = profile.minAltitudeMeters;
    var hi = profile.maxAltitudeMeters;
    final span = math.max(hi - lo, 1.0);
    lo -= span * 0.1;
    hi = lo + span * 1.2;
    final dy = hi - lo;

    Offset map(ElevationSample s) => Offset(
      (s.distanceMeters - x0) / dx * size.width,
      size.height - (s.altitudeMeters - lo) / dy * size.height,
    );

    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      grid,
    );
    canvas.drawLine(Offset.zero, Offset(size.width, 0), grid);

    final line = Path();
    final first = map(pts.first);
    line.moveTo(first.dx, first.dy);
    for (var i = 1; i < pts.length; i++) {
      final p = map(pts[i]);
      line.lineTo(p.dx, p.dy);
    }
    final area = Path.from(line)
      ..lineTo(map(pts.last).dx, size.height)
      ..lineTo(first.dx, size.height)
      ..close();

    canvas.drawPath(area, Paint()..color = fillColor);
    canvas.drawPath(
      line,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(ElevationChartPainter old) =>
      old.profile != profile ||
      old.fillColor != fillColor ||
      old.lineColor != lineColor ||
      old.gridColor != gridColor;
}
