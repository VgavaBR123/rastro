// Metrica com rotulo, valor e unidade (relatorio 11, MetricTile). O valor vem
// na cor da funcao; a variante em bloco ganha o fundo tingido.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final RoleColors role;

  /// Estilo do valor; padrao metricS.
  final TextStyle? valueStyle;

  /// Bloco com fundo tingido, raio 16 e padding 12.
  final bool block;

  final CrossAxisAlignment alignment;

  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.role,
    this.unit,
    this.valueStyle,
    this.block = false,
    this.alignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final muted = AppText.label.copyWith(color: c.textMuted);
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignment,
      children: [
        Text(label, style: muted, maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(children: [
            TextSpan(text: value, style: (valueStyle ?? AppText.metricS).copyWith(color: role.fg)),
            if (unit != null && unit!.isNotEmpty) TextSpan(text: ' $unit', style: muted),
          ]),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
    if (!block) return content;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: role.tint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: content,
    );
  }
}
