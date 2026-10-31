// Cartao do bloco atual da sessao guiada do plano 5 km (F06), na tela de
// gravacao: Correr/Caminhar, contagem regressiva do bloco, proximo bloco e
// progresso da sessao. Cores do tema (corrida = cor da Corrida, caminhada =
// cor da Caminhada).
//
// Acessibilidade: o cabecalho (bloco e numero) e uma regiao viva, entao o
// leitor de tela anuncia a TROCA de bloco; a contagem regressiva fica fora da
// regiao viva para nao ser anunciada a cada segundo.
library;

import 'package:flutter/material.dart';

import '../../core/format/measures.dart';
import '../../plan5k/domain/plan_phrases.dart';
import '../../plan5k/guided_session.dart';
import '../../recording/domain/recording_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

class GuidedBlockCard extends StatelessWidget {
  final GuidedUiState guided;

  /// Gravacao pausada: o plano tambem esta parado.
  final bool paused;

  const GuidedBlockCard({super.key, required this.guided, this.paused = false});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final v = guided.view;
    final block = v.block;
    final role = block == null
        ? c.ciano
        : c.sport(block.kind.isRun ? ActivityType.run : ActivityType.walk);
    final title = block == null ? 'Plano de hoje concluido' : blockLabel(block.kind);
    final position = block == null
        ? guided.session.label
        : 'Bloco ${v.index + 1} de ${v.blockCount}';
    final next = v.next;
    final remaining = v.remainingMs;
    final percent = (v.progress * 100).round();

    return Container(
      key: const Key('plan_block_card'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: role.tint,
        borderRadius: BorderRadius.circular(AppShape.tile),
        border: Border.all(color: role.fill),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            key: const Key('plan_block_header'),
            liveRegion: true,
            container: true,
            label: block == null
                ? 'Plano de hoje concluido'
                : '$title. $position${paused ? '. Pausado' : ''}',
            child: ExcludeSemantics(
              child: Row(
                children: [
                  Icon(
                    block == null
                        ? Icons.check_circle_rounded
                        : block.kind.isRun
                            ? Icons.directions_run_rounded
                            : Icons.directions_walk_rounded,
                    color: role.fg,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      key: const Key('plan_block_label'),
                      style: AppText.sectionTitle.copyWith(color: role.fg),
                    ),
                  ),
                  Text(
                    paused ? 'Pausado' : position,
                    style: AppText.label.copyWith(color: c.textMuted),
                  ),
                ],
              ),
            ),
          ),
          if (block != null) ...[
            const SizedBox(height: 4),
            Semantics(
              label: 'Faltam ${spokenPlanDuration(remaining)} neste bloco',
              child: ExcludeSemantics(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    formatDuration(remaining),
                    key: const Key('plan_block_countdown'),
                    maxLines: 1,
                    style: AppText.metricL.copyWith(color: c.text),
                  ),
                ),
              ),
            ),
            Text(
              next == null ? 'Ultimo bloco' : 'A seguir: ${nextBlockLabel(next)}',
              key: const Key('plan_block_next'),
              style: AppText.body.copyWith(color: c.textMuted),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Siga gravando ou encerre quando quiser.',
                style: AppText.body.copyWith(color: c.textMuted),
              ),
            ),
          const SizedBox(height: 10),
          Semantics(
            label: 'Sessao $percent por cento concluida',
            child: ExcludeSemantics(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  key: const Key('plan_session_progress'),
                  value: v.progress,
                  minHeight: 8,
                  color: role.fill,
                  backgroundColor: c.line,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
