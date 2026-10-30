// Fechamento gentil (F04): o que aparece depois de Salvar. Duas ou tres
// frases que comparam a pessoa so com ela mesma, o esforco e o humor
// escolhidos e o botao Concluir. Mostrada pela RecordingScreen, que fecha ao
// concluir.
library;

import 'package:flutter/material.dart';

import '../../closing/domain/effort.dart';
import '../../recording/domain/recording_models.dart';
import '../components/big_action_button.dart';
import '../components/sport_chip.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'effort_picker.dart';

class ClosingView extends StatelessWidget {
  final ActivityType type;

  /// Frases do fechamento; vazia = so a confirmacao.
  final List<String> phrases;

  final int? rpe;
  final Mood? mood;

  /// Tempo de cronometro (para a carga do treino).
  final int timerMs;

  final VoidCallback onDone;

  const ClosingView({
    super.key,
    required this.type,
    required this.phrases,
    required this.timerMs,
    required this.onDone,
    this.rpe,
    this.mood,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final load = trainingLoad(rpe: rpe, timerMs: timerMs);
    final m = mood;
    final r = rpe;
    return SafeArea(
      key: const Key('closing_view'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppShape.gutter, 24, AppShape.gutter, 16),
              children: [
                Align(alignment: Alignment.centerLeft, child: SportChip(type: type)),
                const SizedBox(height: 12),
                Text('Bom treino', style: AppText.screenTitle.copyWith(color: c.text)),
                const SizedBox(height: 16),
                if (phrases.isEmpty)
                  _Phrase(text: 'Treino salvo.', index: 0)
                else
                  for (var i = 0; i < phrases.length; i++)
                    _Phrase(text: phrases[i], index: i),
                if (r != null || m != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    key: const Key('closing_effort'),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(AppShape.card),
                      border: Border.all(color: c.line),
                    ),
                    child: Row(
                      children: [
                        if (r != null)
                          Expanded(
                            child: _Fact(
                              label: 'Esforco',
                              value: rpeText(r),
                              detail: load == null ? null : 'Carga $load',
                              role: c.extra,
                            ),
                          ),
                        if (m != null)
                          Expanded(
                            child: Row(
                              children: [
                                Icon(moodIcon(m), color: c.ciano.fg, size: 28),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: _Fact(label: 'Humor', value: m.label, role: c.ciano),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppShape.gutter, 8, AppShape.gutter, 16),
            child: BigActionButton(
              key: const Key('closing_done'),
              label: 'Concluir',
              icon: Icons.check_rounded,
              onPressed: onDone,
            ),
          ),
        ],
      ),
    );
  }
}

class _Phrase extends StatelessWidget {
  final String text;
  final int index;
  const _Phrase({required this.text, required this.index});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      key: Key('closing_phrase_$index'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.dist.tint,
        borderRadius: BorderRadius.circular(AppShape.tile),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome_rounded, color: c.dist.fg, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: AppText.bodyStrong.copyWith(color: c.text)),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final String label;
  final String value;
  final String? detail;
  final RoleColors role;
  const _Fact({required this.label, required this.value, required this.role, this.detail});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.label.copyWith(color: c.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: AppText.bodyStrong.copyWith(color: role.fg)),
        if (detail != null)
          Text(detail!, style: AppText.label.copyWith(color: c.textMuted)),
      ],
    );
  }
}
