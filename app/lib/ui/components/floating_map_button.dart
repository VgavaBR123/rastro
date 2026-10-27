// Botao sobre o mapa (relatorio 11, FloatingMapButton): fundo navBg com
// desfoque e borda navLine. Com [label], vira pilula com icone e texto.
library;

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class FloatingMapButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final String? label;
  final VoidCallback? onPressed;

  /// Cor do icone; padrao text.
  final Color? iconColor;

  const FloatingMapButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.label,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final shape = StadiumBorder(side: BorderSide(color: c.navLine));
    return Tooltip(
      message: tooltip,
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: const StadiumBorder()),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Material(
            color: c.navBg,
            shape: shape,
            child: InkWell(
              onTap: onPressed,
              customBorder: shape,
              child: SizedBox(
                height: 44,
                width: label == null ? 44 : null,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: label == null ? 0 : 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 20, color: iconColor ?? c.text),
                      if (label != null) ...[
                        const SizedBox(width: 8),
                        Text(label!, style: AppText.label.copyWith(color: iconColor ?? c.text)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
