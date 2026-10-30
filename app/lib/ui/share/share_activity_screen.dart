// Tela Compartilhar: previa do ShareCard no formato 9:16, escolha do estilo
// (Cartao ou Transparente) e envio pela folha nativa como imagem PNG de
// 1080 x 1920, ou so o resumo em texto.
library;

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../activity/activity_providers.dart';
import '../../app/providers.dart';
import '../../core/format/activity_labels.dart';
import '../../persistence/database.dart';
import '../../platform/activity_sharer.dart';
import '../../privacy/privacy_providers.dart';
import '../../privacy/privacy_repository.dart';
import '../components/big_action_button.dart';
import '../components/segmented_selector.dart';
import '../components/sport_chip.dart';
import '../privacy/routine_warning_banner.dart';
import '../share_activity.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'share_card.dart';

/// Pasta onde a imagem e gravada antes de ir para a folha. No Android tem
/// que ficar em `cache/share/` (res/xml/share_paths.xml). Os testes trocam
/// por uma pasta temporaria.
final shareImageDirectoryProvider = Provider<Future<Directory> Function()>(
  (ref) =>
      () async => Directory('${(await getTemporaryDirectory()).path}/share'),
);

class ShareActivityScreen extends ConsumerStatefulWidget {
  final Activity activity;
  const ShareActivityScreen({super.key, required this.activity});

  @override
  ConsumerState<ShareActivityScreen> createState() =>
      _ShareActivityScreenState();
}

class _ShareActivityScreenState extends ConsumerState<ShareActivityScreen> {
  final GlobalKey _cardKey = GlobalKey();
  ShareCardStyle _style = ShareCardStyle.card;
  bool _busy = false;

  /// Privacidade (F02): quanto da atividade aparece na imagem.
  ShareRouteMode _mode = ShareRouteMode.trimmed;

  /// Trecho completo, so depois de confirmar.
  bool _revealFull = false;

  Future<void> _confirmReveal() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final c = AppColors.of(ctx);
        return AlertDialog(
          key: const Key('reveal_dialog'),
          title: const Text('Mostrar o trajeto completo?'),
          content: const Text(
            'O inicio e o fim podem revelar onde voce mora ou trabalha. '
            'A imagem vai sair com o trajeto inteiro.',
          ),
          actions: [
            TextButton(
              key: const Key('reveal_cancel'),
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Manter oculto'),
            ),
            TextButton(
              key: const Key('reveal_confirm'),
              style: TextButton.styleFrom(foregroundColor: c.danger),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Mostrar'),
            ),
          ],
        );
      },
    );
    if (ok == true && mounted) setState(() => _revealFull = true);
  }

  Activity get _a => widget.activity;

  /// Desenha o cartao a [kShareCardPixelRatio] e grava o PNG. Uma imagem por
  /// vez na pasta: as anteriores sao apagadas.
  Future<String> _writeImage() async {
    final boundary =
        _cardKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: kShareCardPixelRatio);
    final ByteData? bytes;
    try {
      bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    } finally {
      image.dispose();
    }
    if (bytes == null) throw StateError('falha ao codificar a imagem');

    final dir = await ref.read(shareImageDirectoryProvider)();
    if (await dir.exists()) {
      await for (final old in dir.list()) {
        if (old is File) await old.delete();
      }
    } else {
      await dir.create(recursive: true);
    }
    final file = File('${dir.path}/rastro-${_a.guid}.png');
    await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    return file.path;
  }

  Future<void> _share({required bool image}) async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final text = shareTextFor(_a, metric: ref.read(settingsProvider).useMetric);
    final sharer = ref.read(activitySharerProvider);
    try {
      if (image) {
        await sharer.shareImage(await _writeImage(), text: text);
      } else {
        await sharer.shareText(text);
      }
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

  /// Etiqueta "Inicio e fim ocultos" e o botao de mostrar o trecho completo
  /// (ou de voltar a esconder).
  Widget _privacyTag(AppColors c) {
    final link = TextButton.styleFrom(
      foregroundColor: c.ciano.fg,
      minimumSize: const Size(44, 44),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _revealFull
                    ? SportChip.custom(
                        key: const Key('share_full_tag'),
                        label: 'Trajeto completo visivel',
                        role: c.tempo,
                      )
                    : SportChip.custom(
                        key: const Key('share_hidden_tag'),
                        label: 'Inicio e fim ocultos',
                        role: c.subida,
                      ),
              ),
            ),
          ),
          _revealFull
              ? TextButton(
                  key: const Key('share_hide_again'),
                  style: link,
                  onPressed: _busy
                      ? null
                      : () => setState(() => _revealFull = false),
                  child: const Text('Ocultar de novo'),
                )
              : TextButton(
                  key: const Key('share_reveal_full'),
                  style: link,
                  onPressed: _busy ? null : _confirmReveal,
                  child: const Text('Mostrar completo'),
                ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final private =
        ref.watch(visibleRouteProvider(_a.guid)).value ?? PrivateRoute.empty;
    final routine =
        ref.watch(routineWarningForActivityProvider(_a.guid)).value ?? false;
    final trimmed = private.trim.hidesAnything;
    final route = _revealFull ? private.full : private.points;
    final profile = ref.watch(activityElevationProfileProvider(_a.guid)).value;
    final data = ShareCardData(
      title: displayActivityTitle(
        _a.title,
        _a.activityType,
        DateTime.fromMillisecondsSinceEpoch(_a.startTimestampMs),
      ),
      type: _a.activityType,
      startTimestampMs: _a.startTimestampMs,
      distanceMeters: _a.distanceMeters,
      timerMs: _a.timerTimeMs,
      gainMeters: profile?.gainMeters,
      route: route,
      metric: ref.watch(settingsProvider).useMetric,
      showRoute: _mode == ShareRouteMode.trimmed,
      showHeader: _mode != ShareRouteMode.metricsOnly,
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, AppShape.gutter, 0),
              child: Row(
                children: [
                  IconButton(
                    key: const Key('share_back'),
                    tooltip: 'Voltar',
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Compartilhar',
                    style: AppText.screenTitle.copyWith(color: c.text),
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
                      child: CustomPaint(
                        // Xadrez so atras do Transparente, para mostrar o que
                        // fica sem fundo; nao entra na imagem.
                        painter: _style == ShareCardStyle.transparent
                            ? _CheckerPainter(c.surface, c.surface2)
                            : null,
                        child: FittedBox(
                          child: RepaintBoundary(
                            key: _cardKey,
                            child: ShareCard(
                              key: const Key('share_card'),
                              data: data,
                              style: _style,
                            ),
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
                  if (trimmed && _mode == ShareRouteMode.trimmed)
                    _privacyTag(c),
                  if (routine)
                    const Padding(
                      key: Key('share_routine_warning'),
                      padding: EdgeInsets.only(bottom: 8),
                      child: RoutineWarningBanner(),
                    ),
                  SegmentedSelector<ShareRouteMode>(
                    key: const Key('share_privacy'),
                    options: [
                      for (final m in ShareRouteMode.values)
                        SegmentOption(
                          key: Key('share_privacy_${m.name}'),
                          value: m,
                          label: m.label,
                          role: c.subida,
                        ),
                    ],
                    selected: _mode,
                    onChanged: _busy ? null : (m) => setState(() => _mode = m),
                  ),
                  const SizedBox(height: 8),
                  SegmentedSelector<ShareCardStyle>(
                    key: const Key('share_style'),
                    options: [
                      for (final s in ShareCardStyle.values)
                        SegmentOption(
                          key: Key('share_style_${s.name}'),
                          value: s,
                          label: s.label,
                          icon: s.icon,
                          role: c.ciano,
                        ),
                    ],
                    selected: _style,
                    onChanged: _busy ? null : (s) => setState(() => _style = s),
                  ),
                  const SizedBox(height: 12),
                  BigActionButton(
                    key: const Key('share_image'),
                    label: 'Compartilhar imagem',
                    icon: Icons.ios_share,
                    onPressed: _busy ? null : () => _share(image: true),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    key: const Key('share_text_only'),
                    style: TextButton.styleFrom(
                      foregroundColor: c.ciano.fg,
                      minimumSize: const Size(44, 44),
                    ),
                    onPressed: _busy ? null : () => _share(image: false),
                    child: const Text('So o texto'),
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

/// Xadrez de transparencia em quadrados de 12.
class _CheckerPainter extends CustomPainter {
  final Color a;
  final Color b;
  const _CheckerPainter(this.a, this.b);

  @override
  void paint(Canvas canvas, Size size) {
    const cell = 12.0;
    canvas.drawRect(Offset.zero & size, Paint()..color = a);
    final paint = Paint()..color = b;
    for (var y = 0; y * cell < size.height; y++) {
      for (var x = y.isEven ? 0 : 1; x * cell < size.width; x += 2) {
        canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_CheckerPainter old) => old.a != a || old.b != b;
}
