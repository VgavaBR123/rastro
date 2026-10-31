// Rastro Seguro (F08) na tela Gravar: opcao que abre a escolha dos contatos
// aceitos (1 a 3) e do horario previsto de chegada (atalhos 30, 45, 60 e
// 90 min ou um horario; de 5 min a 12 h). Sem login, sem contato aceito ou
// sem rede: explica e a gravacao segue sem Rastro Seguro (nunca bloqueia).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../safety/contacts_controller.dart';
import '../../safety/safety_models.dart';
import '../../safety/safety_providers.dart';
import '../../safety/safety_session_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// Atalhos de duracao (min) contados a partir do Iniciar.
const List<int> kSafetyEtaShortcuts = [30, 45, 60, 90];

String formatClock(int epochMs) => DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(epochMs));

/// Texto do horario escolhido, para a opcao e a faixa.
String safetyPlanSummary(SafetyPlan p) {
  final names = p.contacts.map((c) => c.label).join(', ');
  final when = p.minutes != null ? 'chegada em ${p.minutes} min' : 'chegada as ${formatClock(p.etaAtMs!)}';
  return '$names - $when';
}

class SafetyEntry extends ConsumerWidget {
  const SafetyEntry({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final plan = ref.watch(safetyPlanProvider);
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        key: const Key('safety_entry'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        minTileHeight: 48,
        leading: Icon(
          plan == null ? Icons.shield_outlined : Icons.shield_rounded,
          color: plan == null ? c.textMuted : c.ciano.fg,
        ),
        title: Text('Rastro Seguro', style: AppText.bodyStrong.copyWith(color: c.text)),
        subtitle: Text(
          plan == null ? 'Avisa seus contatos se voce nao chegar no horario' : safetyPlanSummary(plan),
          key: const Key('safety_entry_subtitle'),
          style: AppText.label.copyWith(color: plan == null ? c.textMuted : c.ciano.fg),
        ),
        trailing: plan == null
            ? Icon(Icons.chevron_right_rounded, color: c.textMuted)
            : IconButton(
                key: const Key('safety_entry_clear'),
                tooltip: 'Gravar sem Rastro Seguro',
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: () => ref.read(safetyPlanProvider.notifier).state = null,
                icon: Icon(Icons.close_rounded, color: c.textMuted),
              ),
        onTap: () => showSafetyPlanSheet(context),
      ),
    );
  }
}

Future<void> showSafetyPlanSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  useRootNavigator: true,
  isScrollControlled: true,
  builder: (_) => const SafetyPlanSheet(),
);

class SafetyPlanSheet extends ConsumerStatefulWidget {
  const SafetyPlanSheet({super.key});

  @override
  ConsumerState<SafetyPlanSheet> createState() => _SafetyPlanSheetState();
}

class _SafetyPlanSheetState extends ConsumerState<SafetyPlanSheet> {
  final Set<String> _picked = {};
  int? _minutes = 60;
  int? _etaAt;
  String? _error;

  @override
  void initState() {
    super.initState();
    final plan = ref.read(safetyPlanProvider);
    if (plan != null) {
      _picked.addAll(plan.contactIds);
      _minutes = plan.minutes;
      _etaAt = plan.etaAtMs;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(authControllerProvider).isSignedIn) ref.read(contactsProvider.notifier).load();
    });
  }

  Future<void> _pickTime() async {
    final now = DateTime.fromMillisecondsSinceEpoch(ref.read(safetyClockProvider)());
    final initial = DateTime.fromMillisecondsSinceEpoch(
      _etaAt ?? now.add(const Duration(hours: 1)).millisecondsSinceEpoch,
    );
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      helpText: 'Horario previsto de chegada',
      builder: (ctx, child) =>
          MediaQuery(data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true), child: child!),
    );
    if (t == null || !mounted) return;
    var at = DateTime(now.year, now.month, now.day, t.hour, t.minute);
    // Horario ja passou hoje: e amanha (treino que vira a meia-noite).
    if (!at.isAfter(now)) at = at.add(const Duration(days: 1));
    setState(() {
      _etaAt = at.millisecondsSinceEpoch;
      _minutes = null;
      _error = null;
    });
  }

  void _confirm(List<TrustedContact> accepted) {
    final contacts = [
      for (final c in accepted)
        if (_picked.contains(c.id)) c,
    ];
    if (contacts.isEmpty) {
      setState(() => _error = 'Escolha pelo menos um contato.');
      return;
    }
    if (contacts.length > kMaxTrustedContacts) {
      setState(() => _error = 'Escolha no maximo 3 contatos.');
      return;
    }
    final now = ref.read(safetyClockProvider)();
    if (_etaAt != null && !safetyEtaValid(_etaAt!, now)) {
      setState(() => _error = 'Escolha um horario entre 5 minutos e 12 horas a partir de agora.');
      return;
    }
    ref.read(safetyPlanProvider.notifier).state = SafetyPlan(
      contacts: contacts,
      minutes: _minutes,
      etaAtMs: _minutes == null ? _etaAt : null,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final signedIn = ref.watch(authControllerProvider.select((s) => s.isSignedIn));
    ref.listen<bool>(authControllerProvider.select((s) => s.isSignedIn), (_, v) {
      if (v) ref.read(contactsProvider.notifier).load();
    });
    final s = ref.watch(contactsProvider);
    final accepted = s.accepted;

    Widget body;
    if (!signedIn) {
      body = _Explain(
        key: const Key('safety_setup_signed_out'),
        text:
            'O Rastro Seguro avisa outras contas do Rastro. Entre na sua conta para usar. '
            'Voce pode gravar normalmente sem ele.',
        action: 'Entrar',
        actionKey: const Key('safety_setup_sign_in'),
        onAction: () {
          Navigator.of(context).pop();
          context.push(AppRoutes.auth);
        },
      );
    } else if (s.lists == null && s.error == null) {
      body = const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (s.lists == null && s.error != null) {
      body = _Explain(
        key: const Key('safety_setup_offline'),
        text:
            'Sem conexao com o servidor, o Rastro Seguro nao funciona agora. '
            'Voce pode gravar normalmente sem ele.',
        action: 'Tentar de novo',
        actionKey: const Key('safety_setup_retry'),
        onAction: () => ref.read(contactsProvider.notifier).load(),
      );
    } else if (accepted.isEmpty) {
      body = _Explain(
        key: const Key('safety_setup_no_contacts'),
        text:
            'Voce ainda nao tem contato de confianca aceito. Convide alguem em Configuracoes > Rastro Seguro. '
            'Voce pode gravar normalmente sem ele.',
        action: 'Convidar contatos',
        actionKey: const Key('safety_setup_contacts'),
        onAction: () {
          Navigator.of(context).pop();
          context.push(AppRoutes.safety);
        },
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Quem avisar', style: AppText.bodyStrong.copyWith(color: c.text)),
          Text('De 1 a 3 contatos', style: AppText.label.copyWith(color: c.textMuted)),
          for (final contact in accepted)
            CheckboxListTile(
              key: Key('safety_pick_${contact.id}'),
              contentPadding: EdgeInsets.zero,
              minTileHeight: 48,
              value: _picked.contains(contact.id),
              title: Text(contact.label),
              subtitle: Text(contact.email),
              onChanged: (v) => setState(() {
                _error = null;
                if (v == true) {
                  _picked.add(contact.id);
                } else {
                  _picked.remove(contact.id);
                }
              }),
            ),
          const SizedBox(height: 12),
          Text('Chegada prevista', style: AppText.bodyStrong.copyWith(color: c.text)),
          Text(
            'Se voce nao chegar ate la, o app pergunta se esta tudo bem antes de avisar.',
            style: AppText.label.copyWith(color: c.textMuted),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in kSafetyEtaShortcuts)
                ChoiceChip(
                  key: Key('safety_eta_$m'),
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  label: Text('$m min'),
                  selected: _minutes == m,
                  onSelected: (_) => setState(() {
                    _minutes = m;
                    _etaAt = null;
                    _error = null;
                  }),
                ),
              ChoiceChip(
                key: const Key('safety_eta_custom'),
                materialTapTargetSize: MaterialTapTargetSize.padded,
                avatar: const Icon(Icons.schedule_rounded, size: 18),
                label: Text(_etaAt == null ? 'Horario' : 'As ${formatClock(_etaAt!)}'),
                selected: _etaAt != null,
                onSelected: (_) => _pickTime(),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                key: const Key('safety_plan_error'),
                style: AppText.body.copyWith(color: c.danger),
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('safety_plan_confirm'),
            style: FilledButton.styleFrom(minimumSize: const Size(44, 52)),
            onPressed: () => _confirm(accepted),
            child: const Text('Usar Rastro Seguro nesta atividade'),
          ),
          if (ref.watch(safetyPlanProvider) != null)
            TextButton(
              key: const Key('safety_plan_clear'),
              style: TextButton.styleFrom(minimumSize: const Size(44, 48)),
              onPressed: () {
                ref.read(safetyPlanProvider.notifier).state = null;
                Navigator.of(context).pop();
              },
              child: const Text('Gravar sem Rastro Seguro'),
            ),
        ],
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(AppShape.gutter, 0, AppShape.gutter, 16 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          key: const Key('safety_plan_sheet'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Rastro Seguro', style: AppText.sectionTitle.copyWith(color: c.text)),
            const SizedBox(height: 12),
            body,
          ],
        ),
      ),
    );
  }
}

class _Explain extends StatelessWidget {
  final String text;
  final String action;
  final Key actionKey;
  final VoidCallback onAction;
  const _Explain({
    super.key,
    required this.text,
    required this.action,
    required this.actionKey,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(text, style: AppText.body.copyWith(color: c.textMuted)),
        const SizedBox(height: 12),
        OutlinedButton(
          key: actionKey,
          style: OutlinedButton.styleFrom(minimumSize: const Size(44, 48)),
          onPressed: onAction,
          child: Text(action),
        ),
      ],
    );
  }
}
