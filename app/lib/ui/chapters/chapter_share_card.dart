// Imagem do capitulo (F05): formato 9:16 como a da atividade, com o titulo
// do capitulo, os totais, ate 3 marcos e a marca d'agua discreta "Rastro".
// Nunca mapa, rota, horario, titulo ou descricao de atividade (o
// ChapterShareData nem tem esses dados) e nunca pace. Sempre com os tokens do
// tema escuro, para sair igual em qualquer tema do app.
library;

import 'package:flutter/material.dart';

import '../../chapters/domain/chapter_pages.dart';
import '../share/share_card.dart' show kShareBrand, kShareCardSize;
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'chapter_style.dart';

class ChapterShareCard extends StatelessWidget {
  final ChapterShareData data;
  const ChapterShareCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.dark,
      child: Builder(builder: (context) => _content(AppColors.of(context))),
    );
  }

  Widget _content(AppColors c) {
    return SizedBox.fromSize(
      size: kShareCardSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [c.surface, c.bg],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.subheading,
                style: AppText.label.copyWith(color: c.primaryText),
              ),
              const SizedBox(height: 6),
              Text(
                data.heading,
                key: const Key('chapter_share_heading'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.screenTitle.copyWith(color: c.text),
              ),
              const SizedBox(height: 28),
              for (var i = 0; i < data.stats.length; i += 2) ...[
                if (i > 0) const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _stat(c, data.stats[i])),
                    const SizedBox(width: 16),
                    Expanded(
                      child: i + 1 < data.stats.length
                          ? _stat(c, data.stats[i + 1])
                          : const SizedBox(),
                    ),
                  ],
                ),
              ],
              const Spacer(),
              if (data.milestones.isNotEmpty) ...[
                Text(
                  'Primeiras vezes',
                  style: AppText.label.copyWith(color: c.textMuted),
                ),
                const SizedBox(height: 8),
                for (final m in data.milestones)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      key: const Key('chapter_share_milestone'),
                      children: [
                        Icon(Icons.flag_rounded, size: 18, color: c.extra.fg),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            m,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.bodyStrong.copyWith(color: c.text),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
              ],
              // Marca d'agua discreta.
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: c.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    kShareBrand,
                    key: const Key('chapter_share_brand'),
                    style: AppText.label.copyWith(color: c.textMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(AppColors c, ChapterStat s) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(s.label, style: AppText.label.copyWith(color: c.textMuted)),
      const SizedBox(height: 2),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          s.value,
          style: AppText.metricM.copyWith(color: chapterRole(c, s).fg),
        ),
      ),
    ],
  );
}
