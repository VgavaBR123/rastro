// Capitulo do mes ou do ano (F05): paginas estilo story. Tocar na metade
// direita (ou em Avancar) avanca, na esquerda (ou em Voltar) recua, Fechar
// sai. A ultima pagina tem Compartilhar. Os textos vem prontos do dominio
// (chapter_pages.dart): so numeros agregados e marcos, sem mapa, rota,
// horario, titulo ou descricao; no Modo Gentil, sem pace.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../chapters/chapter_providers.dart';
import '../../chapters/domain/chapter_pages.dart';
import '../../chapters/domain/period.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'chapter_share_screen.dart';
import 'chapter_style.dart';

/// Qual capitulo abrir.
sealed class ChapterSource {
  const ChapterSource();
  const factory ChapterSource.month(MonthKey month) = MonthChapterSource;
  const factory ChapterSource.year(int year) = YearChapterSource;
}

class MonthChapterSource extends ChapterSource {
  final MonthKey month;
  const MonthChapterSource(this.month);
}

class YearChapterSource extends ChapterSource {
  final int year;
  const YearChapterSource(this.year);
}

class ChapterScreen extends ConsumerStatefulWidget {
  final ChapterSource source;
  const ChapterScreen({super.key, required this.source});

  @override
  ConsumerState<ChapterScreen> createState() => _ChapterScreenState();
}

class _ChapterScreenState extends ConsumerState<ChapterScreen> {
  @override
  void initState() {
    super.initState();
    // Abrir o capitulo do mes (pelo cartao ou pela lista) conta como visto:
    // o cartao do Inicio some. So depois que o capitulo chega de fato: se
    // falhar ao montar, o cartao continua. So avanca, entao um mes antigo
    // nao atrapalha.
    final s = widget.source;
    if (s is MonthChapterSource) {
      ref.listenManual(monthChapterProvider(s.month), (_, next) {
        if (_marked || next is! AsyncData) return;
        _marked = true;
        ref.read(chapterSeenMarkerProvider).markSeen(s.month);
      }, fireImmediately: true);
    }
  }

  bool _marked = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final settings = ref.watch(settingsProvider);
    final gentle = settings.gentleMode;
    final metric = settings.useMetric;

    final AsyncValue<(String, List<ChapterPage>, ChapterShareData, String)> data =
        switch (widget.source) {
          MonthChapterSource(:final month) =>
            ref.watch(monthChapterProvider(month)).whenData(
              (ch) => (
                'Capitulo de ${monthName(month.month).toLowerCase()} de ${month.year}',
                monthChapterPages(ch, gentle: gentle, metric: metric),
                monthShareData(ch, metric: metric),
                'capitulo-${month.code}',
              ),
            ),
          YearChapterSource(:final year) =>
            ref.watch(yearChapterProvider(year)).whenData(
              (ch) => (
                ch.partial ? 'Capitulo de $year ate agora' : 'Capitulo de $year',
                yearChapterPages(ch, gentle: gentle, metric: metric),
                yearShareData(ch, metric: metric),
                'capitulo-$year',
              ),
            ),
        };

    return Scaffold(
      key: const Key('chapter_screen'),
      backgroundColor: c.bg,
      body: SafeArea(
        child: switch (data) {
          AsyncData(value: (final heading, final pages, final share, final file)) =>
            ChapterStoryView(
              heading: heading,
              pages: pages,
              onClose: () => Navigator.of(context).maybePop(),
              onShare: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ChapterShareScreen(data: share, fileName: file),
                ),
              ),
            ),
          AsyncError() => _Message(
            text: 'Nao foi possivel montar o capitulo',
            onClose: () => Navigator.of(context).maybePop(),
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  final VoidCallback onClose;
  const _Message({required this.text, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: _CloseButton(onClose: onClose),
        ),
        Expanded(
          child: Center(
            child: Text(
              text,
              key: const Key('chapter_error'),
              style: AppText.body.copyWith(color: c.danger),
            ),
          ),
        ),
      ],
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onClose;
  const _CloseButton({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return IconButton(
      key: const Key('chapter_close'),
      tooltip: 'Fechar',
      color: c.text,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      icon: const Icon(Icons.close_rounded),
      onPressed: onClose,
    );
  }
}

/// As paginas com a barra de progresso, os toques nas laterais e os botoes.
class ChapterStoryView extends StatefulWidget {
  final String heading;
  final List<ChapterPage> pages;
  final VoidCallback onClose;
  final VoidCallback onShare;

  const ChapterStoryView({
    super.key,
    required this.heading,
    required this.pages,
    required this.onClose,
    required this.onShare,
  });

  @override
  State<ChapterStoryView> createState() => _ChapterStoryViewState();
}

class _ChapterStoryViewState extends State<ChapterStoryView> {
  int _index = 0;

  bool get _isLast => _index >= widget.pages.length - 1;

  void _next() {
    if (!_isLast) setState(() => _index++);
  }

  void _prev() {
    if (_index > 0) setState(() => _index--);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final pages = widget.pages;
    final page = pages[_index];
    final buttonSize = const Size(48, 48);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppShape.gutter, 10, AppShape.gutter, 0),
          child: Semantics(
            label: 'Pagina ${_index + 1} de ${pages.length}',
            child: ExcludeSemantics(
              child: Row(
                children: [
                  for (var i = 0; i < pages.length; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        key: Key('chapter_progress_$i'),
                        height: 4,
                        decoration: BoxDecoration(
                          color: i <= _index ? c.primary : c.line,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppShape.gutter, 4, 4, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.heading,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label.copyWith(color: c.textMuted),
                ),
              ),
              _CloseButton(onClose: widget.onClose),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) => GestureDetector(
              key: const Key('chapter_tap_area'),
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) =>
                  d.localPosition.dx < box.maxWidth / 3 ? _prev() : _next(),
              child: _PageBody(key: Key('chapter_page_${page.kind.name}'), page: page),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppShape.gutter, 8, AppShape.gutter, 16),
          child: Row(
            children: [
              if (_index > 0)
                TextButton.icon(
                  key: const Key('chapter_prev'),
                  style: TextButton.styleFrom(
                    foregroundColor: c.textMuted,
                    minimumSize: buttonSize,
                  ),
                  onPressed: _prev,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Voltar'),
                ),
              const Spacer(),
              if (_isLast)
                FilledButton.icon(
                  key: const Key('chapter_share'),
                  style: FilledButton.styleFrom(minimumSize: buttonSize),
                  onPressed: widget.onShare,
                  icon: const Icon(Icons.ios_share),
                  label: const Text('Compartilhar'),
                )
              else
                FilledButton.icon(
                  key: const Key('chapter_next'),
                  style: FilledButton.styleFrom(minimumSize: buttonSize),
                  onPressed: _next,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Avancar'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Uma pagina: titulo, linhas de texto e os numeros em blocos tingidos. Um
/// unico rotulo para o leitor de tela, anunciado quando a pagina muda.
class _PageBody extends StatelessWidget {
  final ChapterPage page;
  const _PageBody({super.key, required this.page});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final milestones = page.kind == ChapterPageKind.milestones;
    final opening = page.kind == ChapterPageKind.opening;
    return Semantics(
      container: true,
      liveRegion: true,
      label: page.semanticsLabel,
      excludeSemantics: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppShape.gutter, 24, AppShape.gutter, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              page.title,
              style: (opening ? AppText.metricL : AppText.screenTitle).copyWith(
                color: opening ? c.primaryText : c.text,
              ),
            ),
            const SizedBox(height: 14),
            for (final line in page.lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: milestones
                    ? Row(
                        children: [
                          Icon(Icons.flag_rounded, size: 22, color: c.extra.fg),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              line,
                              style: AppText.bodyStrong.copyWith(color: c.text),
                            ),
                          ),
                        ],
                      )
                    : Text(line, style: AppText.body.copyWith(color: c.text)),
              ),
            if (page.stats.isNotEmpty) ...[
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, box) {
                  final w = (box.maxWidth - 10) / 2;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final s in page.stats)
                        SizedBox(width: w, child: _StatTile(stat: s)),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final ChapterStat stat;
  const _StatTile({required this.stat});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final role = chapterRole(c, stat);
    final muted = AppText.label.copyWith(color: c.textMuted);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: role.tint,
        borderRadius: BorderRadius.circular(AppShape.tile),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(stat.label, style: muted, maxLines: 2),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(stat.value, style: AppText.metricM.copyWith(color: role.fg)),
          ),
          if (stat.detail != null) ...[
            const SizedBox(height: 2),
            Text(stat.detail!, style: muted),
          ],
        ],
      ),
    );
  }
}
