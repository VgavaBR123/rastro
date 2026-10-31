// Pecas que mudam de cara conforme a plataforma (INI-16): no iOS seguem o
// sistema (chevron de voltar, acoes de dialogo Cupertino), no Android o
// Material. As cores continuam as do tema.
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// True quando o tema e de plataforma Apple (iOS ou macOS).
bool isCupertinoPlatform(BuildContext context) =>
    switch (Theme.of(context).platform) {
      TargetPlatform.iOS || TargetPlatform.macOS => true,
      _ => false,
    };

/// Icone de voltar igual ao do BackButton do AppBar (o mesmo de Ajustes):
/// chevron no iOS, seta no Android. Para botoes de voltar desenhados a mao.
IconData adaptiveBackIcon(BuildContext context) => isCupertinoPlatform(context)
    ? Icons.arrow_back_ios_new_rounded
    : Icons.arrow_back;

/// Acao de um AlertDialog.adaptive: CupertinoDialogAction no iOS e, no
/// Android, FilledButton para a acao principal ou TextButton para as demais.
/// [destructive] pinta com danger nas duas plataformas.
class AdaptiveDialogAction extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;

  /// Acao principal do dialogo (negrito no iOS, preenchida no Android).
  final bool primary;

  /// Acao que apaga ou desfaz algo.
  final bool destructive;

  const AdaptiveDialogAction({
    super.key,
    required this.onPressed,
    required this.child,
    this.primary = false,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    if (isCupertinoPlatform(context)) {
      return CupertinoDialogAction(
        onPressed: onPressed,
        isDefaultAction: primary,
        isDestructiveAction: destructive,
        textStyle: TextStyle(color: destructive ? c.danger : c.primaryText),
        child: child,
      );
    }
    if (primary && !destructive) {
      return FilledButton(onPressed: onPressed, child: child);
    }
    return TextButton(
      style: destructive
          ? TextButton.styleFrom(foregroundColor: c.danger)
          : null,
      onPressed: onPressed,
      child: child,
    );
  }
}
