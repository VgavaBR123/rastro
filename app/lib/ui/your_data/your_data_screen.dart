// Configuracoes > Seus dados (F07): importar atividades (ZIP da exportacao
// de conta e arquivos FIT, GPX e TCX), com progresso, cancelar e resumo, e
// exportar tudo num ZIP de GPX com a opcao de privacidade.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../your_data/import_service.dart';
import '../../your_data/your_data_controller.dart';
import '../../your_data/your_data_providers.dart';
import '../components/big_action_button.dart';
import '../section_card.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// Erros listados no resumo; o resto vira "e mais N".
const int kSummaryMaxErrors = 30;

class YourDataScreen extends ConsumerWidget {
  const YourDataScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(yourDataControllerProvider);
    final ctrl = ref.read(yourDataControllerProvider.notifier);
    ref.listen(yourDataControllerProvider.select((s) => s.message), (_, msg) {
      if (msg == null) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(key: const Key('your_data_message'), content: Text(msg)));
      ctrl.clearMessage();
    });

    return Scaffold(
      key: const Key('your_data_screen'),
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppShape.gutter, 0, AppShape.gutter, 24),
        children: [
          const ScreenTitle(
            'Seus dados',
            subtitle: 'Traga seu historico de outros apps e leve suas atividades com voce',
          ),
          SectionCard(
            title: 'Importar',
            padding: const EdgeInsets.all(16),
            child: switch (s.phase) {
              YourDataPhase.importing => _Progress(
                state: s,
                label: 'Importando',
                progressKey: const Key('import_progress'),
                countKey: const Key('import_count'),
                cancelKey: const Key('import_cancel'),
                onCancel: ctrl.cancel,
              ),
              YourDataPhase.imported when s.summary != null => _Summary(
                summary: s.summary!,
                onDone: ctrl.dismissSummary,
              ),
              _ => _ImportIntro(
                enabled: !s.busy,
                onPick: ctrl.pickAndImport,
              ),
            },
          ),
          SectionCard(
            title: 'Exportar',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SwitchListTile(
                  key: const Key('export_privacy'),
                  title: const Text('Aplicar zonas de privacidade'),
                  subtitle: const Text(
                    'Corta o inicio e o fim dentro das zonas e os metros ocultos '
                    'de cada atividade, como no envio ao servidor',
                  ),
                  value: s.exportPrivacy,
                  onChanged: s.busy ? null : ctrl.setExportPrivacy,
                ),
                const SectionDivider(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: s.phase == YourDataPhase.exporting
                      ? _Progress(
                          state: s,
                          label: 'Exportando',
                          progressKey: const Key('export_progress'),
                          countKey: const Key('export_count'),
                          cancelKey: const Key('export_cancel'),
                          onCancel: ctrl.cancel,
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Um ZIP com um arquivo GPX por atividade, uma planilha '
                              '(atividades.csv) com o resumo e um LEIA-ME.',
                              style: AppText.body.copyWith(color: AppColors.of(context).textMuted),
                            ),
                            const SizedBox(height: 12),
                            BigActionButton(
                              key: const Key('export_all'),
                              label: 'Exportar tudo',
                              icon: Icons.ios_share_rounded,
                              height: 56,
                              onPressed: s.busy ? null : ctrl.exportAll,
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportIntro extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPick;
  const _ImportIntro({required this.enabled, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final muted = AppText.body.copyWith(color: AppColors.of(context).textMuted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Escolha o ZIP da exportacao de conta de outro app (com activities.csv '
          'e a pasta activities) ou arquivos FIT, GPX e TCX, tambem em .gz. '
          'Tudo e lido no aparelho.',
          style: muted,
        ),
        const SizedBox(height: 8),
        Text(
          'Entram corrida, pedal e caminhada (com trilha), como "so eu". '
          'Repetidas sao puladas.',
          style: muted,
        ),
        const SizedBox(height: 12),
        BigActionButton(
          key: const Key('import_pick'),
          label: 'Escolher arquivos',
          icon: Icons.file_open_outlined,
          height: 56,
          onPressed: enabled ? onPick : null,
        ),
      ],
    );
  }
}

class _Progress extends StatelessWidget {
  final YourDataState state;
  final String label;
  final Key progressKey;
  final Key countKey;
  final Key cancelKey;
  final VoidCallback onCancel;

  const _Progress({
    required this.state,
    required this.label,
    required this.progressKey,
    required this.countKey,
    required this.cancelKey,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final count = state.total <= 0 ? 'Preparando os arquivos...' : '${state.done} de ${state.total}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          label: label,
          value: count,
          liveRegion: true,
          child: ExcludeSemantics(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppShape.tile),
              child: LinearProgressIndicator(
                key: progressKey,
                value: state.fraction,
                minHeight: 8,
                color: c.primary,
                backgroundColor: c.surface2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        ExcludeSemantics(
          child: Text(
            '$label: $count',
            key: countKey,
            style: AppText.bodyStrong.copyWith(color: c.text),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          key: cancelKey,
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: state.cancelling ? null : onCancel,
          child: Text(state.cancelling ? 'Cancelando...' : 'Cancelar'),
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  final ImportSummary summary;
  final VoidCallback onDone;
  const _Summary({required this.summary, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final body = AppText.body.copyWith(color: c.text);
    final muted = AppText.body.copyWith(color: c.textMuted);
    final errors = summary.errors;
    final shown = errors.take(kSummaryMaxErrors).toList();
    return Column(
      key: const Key('import_summary'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          summary.cancelled ? 'Importacao cancelada' : 'Importacao concluida',
          style: AppText.sectionTitle.copyWith(color: c.text),
        ),
        if (summary.cancelled) ...[
          const SizedBox(height: 4),
          Text(
            'O que ja tinha entrado foi mantido.',
            key: const Key('import_summary_cancelled'),
            style: muted,
          ),
        ],
        const SizedBox(height: 12),
        Text(
          '${summary.imported} ${summary.imported == 1 ? 'importada' : 'importadas'}',
          key: const Key('import_summary_imported'),
          style: AppText.bodyStrong.copyWith(color: c.dist.fg),
        ),
        const SizedBox(height: 4),
        Text(
          '${summary.duplicates} ${summary.duplicates == 1 ? 'duplicada' : 'duplicadas'} (ja estavam no app)',
          key: const Key('import_summary_duplicates'),
          style: body,
        ),
        if (summary.ignoredLines.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              key: const Key('import_summary_ignored'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [for (final l in summary.ignoredLines) Text(l, style: body)],
            ),
          ),
        if (errors.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            '${errors.length} com erro',
            style: AppText.bodyStrong.copyWith(color: c.danger),
          ),
          const SizedBox(height: 4),
          Column(
            key: const Key('import_summary_errors'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final e in shown)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text('${e.source}: ${e.reason}', style: muted),
                ),
              if (errors.length > shown.length)
                Text('e mais ${errors.length - shown.length}', style: muted),
            ],
          ),
        ],
        const SizedBox(height: 16),
        BigActionButton(
          key: const Key('import_done'),
          label: 'Concluir',
          height: 56,
          onPressed: onDone,
        ),
      ],
    );
  }
}
