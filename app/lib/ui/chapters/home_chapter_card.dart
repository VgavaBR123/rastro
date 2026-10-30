// Cartao do Inicio (F05): "Seu capitulo de outubro esta pronto", a partir do
// dia 1 do mes seguinte ate a pessoa abrir ou dispensar. Sem notificacao: a
// entrada e so este cartao.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../chapters/chapter_providers.dart';
import '../../chapters/domain/period.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

class HomeChapterCard extends ConsumerWidget {
  const HomeChapterCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(homeChapterProvider).value;
    if (month == null) return const SizedBox.shrink();
    final c = AppColors.of(context);
    final name = monthName(month.month).toLowerCase();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Semantics(
        container: true,
        child: Container(
          key: const Key('home_chapter_card'),
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
          decoration: BoxDecoration(
            color: c.extra.tint,
            borderRadius: BorderRadius.circular(AppShape.tile),
            border: Border.all(color: c.extra.fg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_stories_rounded, color: c.extra.fg),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Seu capitulo de $name esta pronto',
                      style: AppText.bodyStrong.copyWith(color: c.text),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 34),
                child: Text(
                  'Seus numeros e primeiras vezes do mes, feitos no aparelho.',
                  style: AppText.label.copyWith(color: c.textMuted),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    key: const Key('home_chapter_dismiss'),
                    style: TextButton.styleFrom(
                      foregroundColor: c.textMuted,
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: () =>
                        ref.read(chapterSeenMarkerProvider).markSeen(month),
                    child: const Text('Agora nao'),
                  ),
                  const SizedBox(width: 4),
                  TextButton(
                    key: const Key('home_chapter_open'),
                    style: TextButton.styleFrom(
                      foregroundColor: c.extra.fg,
                      minimumSize: const Size(48, 48),
                      textStyle: AppText.bodyStrong,
                    ),
                    onPressed: () => context.push(AppRoutes.monthChapter(month)),
                    child: const Text('Abrir'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
