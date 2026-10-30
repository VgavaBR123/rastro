// Aba Estatisticas (F05): resumo pequeno da sequencia semanal e a lista
// "Capitulos" (anos e meses fechados com dados).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../chapters/chapter_providers.dart';
import '../../chapters/domain/chapter_pages.dart' show kRestartMessage;
import '../../chapters/domain/period.dart';
import '../section_card.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// Sequencia semanal e lista de capitulos, como secoes da aba.
class ChaptersSection extends ConsumerWidget {
  const ChaptersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final streak = ref.watch(currentStreakProvider).value;
    final index = ref.watch(chapterIndexProvider).value;
    final now = ref.watch(chapterClockProvider)();
    final month = MonthKey.of(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (streak != null && streak.weeks.isNotEmpty)
          SectionCard(
            title: 'Sequencia semanal',
            padding: const EdgeInsets.all(16),
            child: Semantics(
              container: true,
              child: Column(
                key: const Key('stats_streak'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        streak.current == 1 ? '1 semana' : '${streak.current} semanas',
                        style: AppText.metricM.copyWith(color: c.ciano.fg),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'seguidas',
                          style: AppText.label.copyWith(color: c.textMuted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Coringa de ${monthName(month.month).toLowerCase()}: '
                    '${streak.jokerAvailable(month) ? 'disponivel' : 'usado'}',
                    style: AppText.body.copyWith(color: c.textMuted),
                  ),
                  if (streak.restarted) ...[
                    const SizedBox(height: 6),
                    Text(kRestartMessage, style: AppText.body.copyWith(color: c.text)),
                  ],
                ],
              ),
            ),
          ),
        if (index != null)
          SectionCard(
            key: const Key('stats_chapters'),
            title: 'Capitulos',
            child: Column(
              children: [
                for (final y in index.years)
                  _ChapterItem(
                    key: Key('chapter_item_year_$y'),
                    label: y == now.year ? '$y ate agora' : '$y',
                    hint: 'Capitulo do ano',
                    icon: Icons.calendar_today_rounded,
                    onTap: () => context.push(AppRoutes.yearChapter(y)),
                  ),
                for (final m in index.months)
                  _ChapterItem(
                    key: Key('chapter_item_month_${m.code}'),
                    label: '${monthName(m.month)} de ${m.year}',
                    hint: 'Capitulo do mes',
                    icon: Icons.auto_stories_rounded,
                    onTap: () => context.push(AppRoutes.monthChapter(m)),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ChapterItem extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final VoidCallback onTap;

  const _ChapterItem({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      button: true,
      label: '$hint: $label',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppShape.card),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(icon, size: 20, color: c.extra.fg),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(label, style: AppText.bodyStrong.copyWith(color: c.text)),
                ),
                Icon(Icons.chevron_right_rounded, color: c.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
