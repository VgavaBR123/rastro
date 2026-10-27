// Anel multicolorido (botao Gravar e avatar do perfil): gradiente de varredura
// comecando em 200 graus, na ordem de `AppColors.ringColors`.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class GradientRing extends StatelessWidget {
  final Widget child;
  final double width;
  final BorderRadius borderRadius;

  const GradientRing({
    super.key,
    required this.child,
    this.width = 2,
    this.borderRadius = const BorderRadius.all(Radius.circular(999)),
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: SweepGradient(
          colors: c.ringColors,
          transform: const GradientRotation(200 * math.pi / 180),
        ),
      ),
      child: Padding(padding: EdgeInsets.all(width), child: child),
    );
  }
}
