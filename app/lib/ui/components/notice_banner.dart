// Aviso em faixa (Gravacao blindada, F01): icone, titulo, texto e uma acao
// opcional. Fundo tingido e borda na cor da funcao (tokens do tema).
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

class NoticeBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  /// Cor de destaque (borda e icone).
  final Color accent;

  /// Fundo; padrao surface.
  final Color? background;

  final String? actionLabel;
  final VoidCallback? onAction;
  final Key? actionKey;

  const NoticeBanner({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.accent,
    this.background,
    this.actionLabel,
    this.onAction,
    this.actionKey,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
        decoration: BoxDecoration(
          color: background ?? c.surface,
          borderRadius: BorderRadius.circular(AppShape.tile),
          border: Border.all(color: accent),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: accent, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppText.bodyStrong.copyWith(color: c.text),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: AppText.label.copyWith(color: c.textMuted),
                  ),
                ],
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(width: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
                child: TextButton(
                  key: actionKey,
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: c.text,
                    minimumSize: const Size(44, 44),
                    textStyle: AppText.bodyStrong,
                  ),
                  child: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
