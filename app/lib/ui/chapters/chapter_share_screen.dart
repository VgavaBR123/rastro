// Compartilhar o capitulo (F05): previa da imagem 9:16 e envio pela folha
// nativa como PNG de 1080 x 1920 (mesmo pipeline da imagem da atividade).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chapters/domain/chapter_pages.dart';
import '../../platform/activity_sharer.dart';
import '../components/big_action_button.dart';
import '../share/share_activity_screen.dart' show shareImageDirectoryProvider;
import '../share/share_card.dart' show kShareCardPixelRatio, kShareCardSize;
import '../share/share_image.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'chapter_share_card.dart';

class ChapterShareScreen extends ConsumerStatefulWidget {
  final ChapterShareData data;

  /// Nome do PNG (sem extensao), ex.: `capitulo-202610`.
  final String fileName;

  const ChapterShareScreen({
    super.key,
    required this.data,
    required this.fileName,
  });

  @override
  ConsumerState<ChapterShareScreen> createState() => _ChapterShareScreenState();
}

class _ChapterShareScreenState extends ConsumerState<ChapterShareScreen> {
  final GlobalKey _cardKey = GlobalKey();
  bool _busy = false;

  Future<void> _share() async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final path = await writeShareImage(
        boundaryKey: _cardKey,
        dir: await ref.read(shareImageDirectoryProvider)(),
        fileName: widget.fileName,
        pixelRatio: kShareCardPixelRatio,
      );
      await ref.read(activitySharerProvider).shareImage(path, text: widget.data.text);
    } on Object {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Nao foi possivel compartilhar')),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      key: const Key('chapter_share_screen'),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, AppShape.gutter, 0),
              child: Row(
                children: [
                  IconButton(
                    key: const Key('chapter_share_back'),
                    tooltip: 'Voltar',
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Compartilhar capitulo',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.screenTitle.copyWith(color: c.text),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppShape.gutter,
                  8,
                  AppShape.gutter,
                  12,
                ),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: kShareCardSize.width / kShareCardSize.height,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppShape.panel),
                      child: FittedBox(
                        child: RepaintBoundary(
                          key: _cardKey,
                          child: ChapterShareCard(
                            key: const Key('chapter_share_card'),
                            data: widget.data,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppShape.gutter,
                0,
                AppShape.gutter,
                12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'So numeros e marcos: sem mapa, horario ou titulo.',
                    textAlign: TextAlign.center,
                    style: AppText.label.copyWith(color: c.textMuted),
                  ),
                  const SizedBox(height: 10),
                  BigActionButton(
                    key: const Key('chapter_share_image'),
                    label: 'Compartilhar imagem',
                    icon: Icons.ios_share,
                    onPressed: _busy ? null : _share,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
