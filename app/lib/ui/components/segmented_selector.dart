// Seletor segmentado (relatorio 11, SegmentedSelector): fundo surface com borda,
// opcoes de 44 e a selecionada tingida na cor da propria opcao.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class SegmentOption<T> {
  final T value;
  final String label;
  final RoleColors role;
  final IconData? icon;
  final Key? key;
  const SegmentOption({required this.value, required this.label, required this.role, this.icon, this.key});
}

class SegmentedSelector<T> extends StatelessWidget {
  final List<SegmentOption<T>> options;
  final T selected;
  final ValueChanged<T>? onChanged;

  const SegmentedSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: c.line),
      ),
      child: Row(
        children: [
          for (final o in options)
            Expanded(
              child: _Segment<T>(
                option: o,
                selected: o.value == selected,
                onTap: onChanged == null ? null : () => onChanged!(o.value),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  final SegmentOption<T> option;
  final bool selected;
  final VoidCallback? onTap;
  const _Segment({required this.option, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final fg = selected ? option.role.fg : c.textMuted;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        key: option.key,
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          // Minimo de 44 (toque); cresce com a fonte do sistema.
          constraints: const BoxConstraints(minHeight: 44),
          decoration: ShapeDecoration(
            color: selected ? option.role.tint : Colors.transparent,
            shape: const StadiumBorder(),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          // GRA-08: em vez de reticencias ("Caminh..."), icone e rotulo
          // encolhem juntos ate caber no segmento (iPhone de 390 pt, fonte
          // maior). Com espaco sobrando ficam no tamanho do tema.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (option.icon != null) ...[
                  Icon(option.icon, size: 18, color: fg),
                  const SizedBox(width: 6),
                ],
                Text(
                  option.label,
                  maxLines: 1,
                  style: AppText.bodyStrong.copyWith(
                    color: fg,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
