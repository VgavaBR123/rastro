// Botao grande de acao (relatorio 11, BigActionButton): pilula de 64 a 80 com
// icone e texto fortes. A variante [BigActionVariant.hold] so dispara depois de
// segurar (Encerrar), para evitar toque acidental com o braco em movimento.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum BigActionVariant {
  /// Cor primaria (Salvar).
  primary,

  /// Cor cheia de uma funcao: esporte (Iniciar), tempo (Pausar), dist (Retomar).
  role,

  /// Neutro surface2 com borda e subtitulo "Segure para confirmar" (Encerrar).
  hold,

  /// Contorno danger (Descartar).
  danger,
}

class BigActionButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final BigActionVariant variant;

  /// Cor para a variante [BigActionVariant.role].
  final RoleColors? role;

  final double height;

  /// Quanto tempo segurar na variante hold.
  final Duration holdDuration;

  /// Subtitulo da variante hold.
  final String holdHint;

  const BigActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = BigActionVariant.primary,
    this.role,
    this.height = 64,
    this.holdDuration = const Duration(milliseconds: 1200),
    this.holdHint = 'Segure para confirmar',
  }) : assert(variant != BigActionVariant.role || role != null);

  @override
  State<BigActionButton> createState() => _BigActionButtonState();
}

class _BigActionButtonState extends State<BigActionButton> with SingleTickerProviderStateMixin {
  late final AnimationController _hold =
      AnimationController(vsync: this, duration: widget.holdDuration)
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) {
            widget.onPressed?.call();
            _hold.value = 0;
          }
        });

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final enabled = widget.onPressed != null;
    final (Color bg, Color fg, BorderSide side, Color? glow) = switch (widget.variant) {
      BigActionVariant.primary => (c.primary, c.onPrimary, BorderSide.none, c.primary),
      BigActionVariant.role => (widget.role!.fill, c.onFill, BorderSide.none, widget.role!.fill),
      BigActionVariant.hold => (c.surface2, c.text, BorderSide(color: c.line), null),
      BigActionVariant.danger => (Colors.transparent, c.danger, BorderSide(color: c.danger, width: 1.5), null),
    };
    final isHold = widget.variant == BigActionVariant.hold;

    final label = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, color: fg, size: 26),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.label, style: AppText.action.copyWith(color: fg), maxLines: 1),
              if (isHold)
                Text(widget.holdHint, style: AppText.label.copyWith(color: c.textMuted)),
            ],
          ),
        ),
      ],
    );

    final shape = StadiumBorder(side: side);
    Widget button = Material(
      color: Colors.transparent,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: ShapeDecoration(color: bg, shape: shape),
        child: InkWell(
          customBorder: shape,
          onTap: !enabled || isHold ? null : widget.onPressed,
          onTapDown: enabled && isHold ? (_) => _hold.forward() : null,
          onTapUp: isHold ? (_) => _hold.reverse() : null,
          onTapCancel: isHold ? () => _hold.reverse() : null,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (isHold)
                AnimatedBuilder(
                  animation: _hold,
                  builder: (_, _) => FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _hold.value,
                    child: ColoredBox(color: c.tempo.tint),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Center(child: label),
              ),
            ],
          ),
        ),
      ),
    );

    button = Semantics(
      button: true,
      enabled: enabled,
      label: isHold ? '${widget.label}, ${widget.holdHint.toLowerCase()}' : widget.label,
      excludeSemantics: true,
      onTap: enabled ? widget.onPressed : null,
      child: SizedBox(height: widget.height, width: double.infinity, child: button),
    );

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: DecoratedBox(
        decoration: glow == null || !enabled
            ? const BoxDecoration()
            : ShapeDecoration(
                shape: const StadiumBorder(),
                shadows: [
                  BoxShadow(color: glow.withValues(alpha: 0.32), blurRadius: 28, offset: const Offset(0, 10)),
                ],
              ),
        child: button,
      ),
    );
  }
}
