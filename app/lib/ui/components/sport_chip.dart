// Chip de esporte (relatorio 11, SportChip): pilula tingida, ponto na cor cheia
// e texto na cor do esporte. Tambem serve para estados ("Gravando", "GPS pronto")
// passando [role] e [label] direto.
library;

import 'package:flutter/material.dart';

import '../../core/format/activity_labels.dart';
import '../../recording/domain/recording_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class SportChip extends StatelessWidget {
  final String label;
  final RoleColors? role;
  final ActivityType? type;

  /// Texto extra depois do esporte, em textMuted ("26/10 · Belo Horizonte").
  final String? trailing;

  const SportChip({super.key, required ActivityType this.type, this.trailing})
      : label = '',
        role = null;

  const SportChip.custom({super.key, required this.label, required RoleColors this.role, this.trailing})
      : type = null;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final r = role ?? c.sport(type!);
    final text = type != null ? activityTypeLabel(type!) : label;
    final chip = Container(
      height: 27,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: ShapeDecoration(color: r.tint, shape: const StadiumBorder()),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: r.fill, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(text, style: AppText.label.copyWith(color: r.fg, fontWeight: FontWeight.w700)),
        ],
      ),
    );
    if (trailing == null) return chip;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        chip,
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            trailing!,
            style: AppText.label.copyWith(color: c.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
