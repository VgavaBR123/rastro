// Sugestao de zona de privacidade (F02): "parece que aqui e sua casa, quer
// esconder?" com Esconder e Ignorar. Aparece em Configuracoes > Privacidade e
// tambem na Inicio, para a privacidade automatica nao passar despercebida.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../privacy/domain/zone_detection.dart';
import '../../privacy/privacy_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// Sugestao "parece que aqui e sua casa" com Esconder e Ignorar.
class ZoneSuggestionCard extends StatelessWidget {
  final ZoneSuggestion suggestion;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;

  const ZoneSuggestionCard({
    super.key,
    required this.suggestion,
    required this.busy,
    required this.onAccept,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      key: const Key('zone_suggestion'),
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
        decoration: BoxDecoration(
          color: c.subida.tint,
          borderRadius: BorderRadius.circular(AppShape.tile),
          border: Border.all(color: c.subida.fg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.home_work_outlined, color: c.subida.fg),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    suggestion.kind.question,
                    style: AppText.bodyStrong.copyWith(color: c.text),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 34),
              child: Text(
                '${suggestion.occurrences} inicios ou fins de atividade neste local',
                style: AppText.label.copyWith(color: c.textMuted),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  key: const Key('suggestion_dismiss'),
                  style: TextButton.styleFrom(
                    foregroundColor: c.textMuted,
                    minimumSize: const Size(44, 44),
                  ),
                  onPressed: busy ? null : onDismiss,
                  child: const Text('Ignorar'),
                ),
                const SizedBox(width: 4),
                TextButton(
                  key: const Key('suggestion_accept'),
                  style: TextButton.styleFrom(
                    foregroundColor: c.subida.fg,
                    minimumSize: const Size(44, 44),
                    textStyle: AppText.bodyStrong,
                  ),
                  onPressed: busy ? null : onAccept,
                  child: const Text('Esconder'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Primeira sugestao pendente, na Inicio. Some quando nao ha nenhuma.
class HomeZoneSuggestion extends ConsumerStatefulWidget {
  const HomeZoneSuggestion({super.key});

  @override
  ConsumerState<HomeZoneSuggestion> createState() => _HomeZoneSuggestionState();
}

class _HomeZoneSuggestionState extends ConsumerState<HomeZoneSuggestion> {
  bool _busy = false;

  Future<void> _run(ZoneSuggestion s, {required bool accept}) async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final repo = ref.read(privacyRepositoryProvider);
      if (accept) {
        final zone = await repo.addZone(s.toZone());
        messenger?.showSnackBar(
          SnackBar(
            content: Text(
              '"${zone.label}" agora e um local protegido: o inicio e o fim '
              'das atividades ali saem cortados.',
            ),
          ),
        );
      } else {
        await repo.dismissSuggestion(s.center);
      }
      ref.invalidate(privacyZonesProvider);
      ref.invalidate(zoneSuggestionsProvider);
    } catch (e) {
      debugPrint('Falha na sugestao de zona: $e');
      messenger?.showSnackBar(
        const SnackBar(
          content: Text('Nao foi possivel salvar. Tente de novo.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list =
        ref.watch(zoneSuggestionsProvider).value ?? const <ZoneSuggestion>[];
    if (list.isEmpty) return const SizedBox.shrink();
    final s = list.first;
    return KeyedSubtree(
      key: const Key('home_zone_suggestion'),
      child: ZoneSuggestionCard(
        suggestion: s,
        busy: _busy,
        onAccept: () => _run(s, accept: true),
        onDismiss: () => _run(s, accept: false),
      ),
    );
  }
}
