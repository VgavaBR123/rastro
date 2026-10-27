// Pecas de layout comuns a Voce, Estatisticas, Configuracoes e conta:
// titulo de tela, secao em cartao surface (raio 22) e o corte de "12.50 km"
// em valor e unidade para o MetricTile.
library;

import 'package:flutter/material.dart';

import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'theme/app_typography.dart';

/// Titulo grande da tela (screenTitle), com uma linha opcional embaixo.
class ScreenTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const ScreenTitle(this.title, {super.key, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.screenTitle.copyWith(color: c.text)),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: AppText.body.copyWith(color: c.textMuted),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Secao: titulo opcional (sectionTitle) e o conteudo num cartao surface com
/// borda line e raio 22.
class SectionCard extends StatelessWidget {
  final String? title;
  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Cor do titulo; padrao text (a zona de perigo usa danger).
  final Color? titleColor;

  const SectionCard({
    super.key,
    this.title,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                title!,
                style: AppText.sectionTitle.copyWith(
                  color: titleColor ?? c.text,
                ),
              ),
            ),
          Material(
            color: c.surface,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppShape.card),
              side: BorderSide(color: c.line),
            ),
            child: Padding(padding: padding, child: child),
          ),
        ],
      ),
    );
  }
}

/// Divisor entre linhas de um [SectionCard].
class SectionDivider extends StatelessWidget {
  const SectionDivider({super.key});

  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    indent: AppShape.gutter,
    endIndent: AppShape.gutter,
    color: AppColors.of(context).line,
  );
}

