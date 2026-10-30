// Checklist "Gravacao confiavel" (F01): mostra, com o estado real do aparelho,
// o que pode interromper a gravacao (otimizacao de bateria, localizacao,
// notificacoes) e as instrucoes do fabricante, com atalho para cada ajuste.
// Aparece uma vez antes da primeira gravacao e sempre pelas Configuracoes. Ao
// voltar dos ajustes do sistema, relê o estado.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../recording/domain/reliability_checklist.dart';
import 'components/big_action_button.dart';
import 'section_card.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'theme/app_typography.dart';

class ReliabilityChecklistScreen extends ConsumerStatefulWidget {
  /// Aberta pelo Iniciar antes da primeira gravacao: mostra "Continuar para
  /// gravar", que marca o checklist como visto e devolve true.
  final bool beforeFirstRecording;

  const ReliabilityChecklistScreen({
    super.key,
    this.beforeFirstRecording = false,
  });

  @override
  ConsumerState<ReliabilityChecklistScreen> createState() =>
      _ReliabilityChecklistScreenState();
}

class _ReliabilityChecklistScreenState
    extends ConsumerState<ReliabilityChecklistScreen>
    with WidgetsBindingObserver {
  List<ChecklistItem>? _items;
  bool _continuing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Voltou dos ajustes do sistema: o estado pode ter mudado.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final snap = await ref.read(reliabilityProbeProvider).read();
    if (!mounted) return;
    setState(() => _items = buildReliabilityChecklist(snap));
  }

  Future<void> _run(ChecklistAction action) async {
    // O ref so e usado com a tela montada: a pessoa pode sair durante o ajuste.
    final probe = ref.read(reliabilityProbeProvider);
    try {
      await probe.run(action);
    } catch (_) {
      // Ajuste indisponivel neste aparelho: a releitura mostra o estado real.
    }
    if (!mounted) return;
    await _load();
  }

  Future<void> _continue() async {
    setState(() => _continuing = true);
    final settings = ref.read(settingsProvider.notifier);
    try {
      await settings.markReliabilityChecklistSeen();
    } catch (_) {
      // Nao salvar o "visto" nao pode impedir a gravacao; o checklist so
      // volta a aparecer na proxima vez.
    } finally {
      if (mounted) {
        setState(() => _continuing = false);
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final items = _items;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Coluna (e nao ListView): poucos itens, e todos ficam na arvore.
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppShape.gutter,
                  0,
                  AppShape.gutter,
                  24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const ScreenTitle(
                      'Gravacao confiavel',
                      subtitle:
                          'Confira o que pode interromper a gravacao neste '
                          'aparelho. O Rastro avisa se ficar algum trecho sem '
                          'dados.',
                    ),
                    if (items == null)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else ...[
                      _Summary(items: items),
                      const SizedBox(height: 16),
                      for (final i in items)
                        _ItemCard(item: i, onAction: () => _run(i.action)),
                    ],
                  ],
                ),
              ),
            ),
            if (widget.beforeFirstRecording)
              Container(
                decoration: BoxDecoration(
                  color: c.surface,
                  border: Border(top: BorderSide(color: c.line)),
                ),
                padding: const EdgeInsets.fromLTRB(
                  AppShape.gutter,
                  12,
                  AppShape.gutter,
                  12,
                ),
                child: BigActionButton(
                  key: const Key('reliability_continue'),
                  label: 'Continuar para gravar',
                  icon: Icons.play_arrow_rounded,
                  onPressed: _continuing ? null : _continue,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Resumo no topo: pronto ou quantos ajustes faltam.
class _Summary extends StatelessWidget {
  final List<ChecklistItem> items;
  const _Summary({required this.items});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final pending = items
        .where((i) => i.status == ChecklistStatus.action)
        .length;
    final ready = pending == 0;
    final role = ready ? c.dist : c.extra;
    return Container(
      key: const Key('reliability_summary'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: role.tint,
        borderRadius: BorderRadius.circular(AppShape.tile),
      ),
      child: Row(
        children: [
          Icon(
            ready ? Icons.verified_rounded : Icons.warning_amber_rounded,
            color: role.fg,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              ready
                  ? 'Tudo pronto para gravar'
                  : pending == 1
                  ? '1 ajuste recomendado'
                  : '$pending ajustes recomendados',
              style: AppText.sectionTitle.copyWith(color: c.text),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final ChecklistItem item;
  final VoidCallback onAction;
  const _ItemCard({required this.item, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final (IconData icon, Color color, String label) = switch (item.status) {
      ChecklistStatus.ok => (Icons.check_circle_rounded, c.dist.fg, 'Ok'),
      ChecklistStatus.warning => (
        Icons.error_outline_rounded,
        c.extra.fg,
        'Recomendado',
      ),
      ChecklistStatus.action => (
        Icons.cancel_rounded,
        c.danger,
        'Precisa de ajuste',
      ),
      ChecklistStatus.unknown => (
        Icons.help_outline_rounded,
        c.textMuted,
        'Nao conferido',
      ),
      ChecklistStatus.info => (
        Icons.info_outline_rounded,
        c.ciano.fg,
        'Confira',
      ),
    };
    return SectionCard(
      key: Key('reliability_item_${item.id.name}'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                label: label,
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AppText.bodyStrong.copyWith(color: c.text),
                    ),
                    const SizedBox(height: 2),
                    Text(label, style: AppText.label.copyWith(color: color)),
                    const SizedBox(height: 6),
                    Text(
                      item.description,
                      style: AppText.body.copyWith(color: c.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (item.steps.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final (n, step) in item.steps.indexed)
              Padding(
                padding: const EdgeInsets.only(left: 38, top: 4),
                child: Text(
                  '${n + 1}. $step',
                  style: AppText.body.copyWith(color: c.text),
                ),
              ),
          ],
          if (item.action != ChecklistAction.none &&
              item.actionLabel != null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 38),
              child: OutlinedButton.icon(
                key: Key('reliability_action_${item.id.name}'),
                onPressed: onAction,
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: Text(item.actionLabel!),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  foregroundColor: c.text,
                  side: BorderSide(color: c.line),
                  textStyle: AppText.bodyStrong,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
