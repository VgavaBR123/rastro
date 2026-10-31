// Caixa de entrada (F08): sino com o contador de nao lidas (no cabecalho do
// Inicio) e a tela das notificacoes. Alertas do Rastro Seguro (safety_alert e
// safety_sos) aparecem em destaque, com quem precisa de ajuda, o motivo e
// "Ver localizacao" (abre o link publico no navegador). Convite leva a tela
// de contatos para aceitar. Abrir uma notificacao a marca como lida.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../safety/safety_models.dart';
import '../../safety/safety_providers.dart';
import '../section_card.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'safety_contacts_screen.dart';

/// Sino com o contador de nao lidas.
class InboxBell extends ConsumerWidget {
  const InboxBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final unread = ref.watch(inboxProvider.select((s) => s.unread));
    final alert = ref.watch(inboxProvider.select((s) => s.items.any((n) => n.unread && n.isAlert)));
    final label = unread == 0
        ? 'Notificacoes'
        : unread == 1
        ? 'Notificacoes, 1 nao lida'
        : 'Notificacoes, $unread nao lidas';
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: () => context.push(AppRoutes.inbox),
      child: Tooltip(
        message: 'Notificacoes',
        child: InkResponse(
          key: const Key('inbox_bell'),
          radius: 24,
          onTap: () => context.push(AppRoutes.inbox),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  unread > 0 ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                  color: alert ? c.danger : c.textMuted,
                ),
                if (unread > 0)
                  Positioned(
                    top: 6,
                    right: 4,
                    child: Container(
                      key: const Key('inbox_badge'),
                      constraints: const BoxConstraints(minWidth: 18),
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: alert ? c.danger : c.primary,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        unread > 9 ? '9+' : '$unread',
                        textAlign: TextAlign.center,
                        style: AppText.label.copyWith(color: alert ? c.bg : c.onPrimary),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(authControllerProvider).isSignedIn) ref.read(inboxProvider.notifier).refresh();
    });
  }

  Future<void> _openLocation(AppNotification n) async {
    ref.read(inboxProvider.notifier).markRead(n.id);
    final url = n.shareUrl;
    final ok = url != null && await ref.read(urlOpenerProvider).open(url);
    if (!ok && mounted) {
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(const SnackBar(content: Text('Nao deu para abrir o link da localizacao.')));
    }
  }

  void _open(AppNotification n) {
    ref.read(inboxProvider.notifier).markRead(n.id);
    if (n.kind == NotificationKind.contactInvite || n.kind == NotificationKind.contactAccepted) {
      context.push(AppRoutes.safety);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final signedIn = ref.watch(authControllerProvider.select((s) => s.isSignedIn));
    ref.listen<bool>(authControllerProvider.select((s) => s.isSignedIn), (_, v) {
      if (v) ref.read(inboxProvider.notifier).refresh();
    });
    final s = ref.watch(inboxProvider);
    return Scaffold(
      appBar: AppBar(),
      body: RefreshIndicator(
        onRefresh: () => ref.read(inboxProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppShape.gutter, 0, AppShape.gutter, 24),
          children: [
            const ScreenTitle('Notificacoes'),
            if (!signedIn)
              const SafetySignedOutCard(
                key: Key('inbox_signed_out'),
                message: 'Convites e alertas do Rastro Seguro chegam aqui. Entre na sua conta para ver.',
              )
            else ...[
              if (s.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    s.error!,
                    key: const Key('inbox_error'),
                    style: AppText.body.copyWith(color: c.danger),
                  ),
                ),
              if (s.loading && s.items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (!s.loading && s.items.isEmpty)
                Padding(
                  key: const Key('inbox_empty'),
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Nenhuma notificacao por enquanto.',
                    textAlign: TextAlign.center,
                    style: AppText.body.copyWith(color: c.textMuted),
                  ),
                ),
              for (final n in s.items) ...[
                NotificationCard(notification: n, onOpen: () => _open(n), onLocation: () => _openLocation(n)),
                const SizedBox(height: 12),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onOpen;
  final VoidCallback onLocation;

  const NotificationCard({super.key, required this.notification, required this.onOpen, required this.onLocation});

  static String _when(int ms) => DateFormat('dd/MM HH:mm').format(DateTime.fromMillisecondsSinceEpoch(ms));

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final n = notification;
    final alert = n.isAlert;
    final (IconData icon, Color accent) = switch (n.kind) {
      NotificationKind.safetyAlert || NotificationKind.safetySos => (Icons.warning_rounded, c.danger),
      NotificationKind.safetyCheck => (Icons.help_rounded, c.extra.fg),
      NotificationKind.safetyAllClear => (Icons.check_circle_rounded, c.dist.fg),
      NotificationKind.contactInvite || NotificationKind.contactAccepted => (Icons.group_add_rounded, c.ciano.fg),
      NotificationKind.unknown => (Icons.notifications_rounded, c.textMuted),
    };
    final who = n.ownerName;
    final title = switch (n.kind) {
      NotificationKind.safetyAlert => '${who ?? 'Um contato'} pode precisar de ajuda',
      NotificationKind.safetySos => '${who ?? 'Um contato'} pediu ajuda',
      NotificationKind.safetyAllClear => '${who ?? 'Seu contato'} respondeu que esta bem',
      _ => n.title.isEmpty ? 'Notificacao' : n.title,
    };
    final detail = switch (n.kind) {
      NotificationKind.safetyAlert =>
        'Motivo: ${checkReasonLabel(n.reason)}. Nao respondeu a checagem do Rastro Seguro.',
      NotificationKind.safetySos => 'Mandou a posicao pelo Rastro Seguro.',
      _ => n.body,
    };
    return Semantics(
      container: true,
      label: n.unread ? 'Nao lida' : null,
      child: Material(
        key: Key('notification_${n.id}'),
        color: alert ? c.danger.withValues(alpha: 0.12) : c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppShape.tile),
          side: BorderSide(color: alert ? c.danger : (n.unread ? c.primary : c.line), width: alert ? 1.5 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: accent, size: alert ? 30 : 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: (alert ? AppText.sectionTitle : AppText.bodyStrong).copyWith(color: c.text),
                          ),
                          if (detail.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(detail, style: AppText.body.copyWith(color: c.textMuted)),
                          ],
                          const SizedBox(height: 4),
                          Text(_when(n.createdAt), style: AppText.label.copyWith(color: c.textMuted)),
                        ],
                      ),
                    ),
                    if (n.unread)
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(top: 6),
                        decoration: BoxDecoration(color: alert ? c.danger : c.primary, shape: BoxShape.circle),
                      ),
                  ],
                ),
                if (alert && n.shareUrl != null) ...[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    key: Key('notification_location_${n.id}'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(44, 52),
                      backgroundColor: c.danger,
                      foregroundColor: c.bg,
                    ),
                    onPressed: onLocation,
                    icon: const Icon(Icons.location_on_rounded),
                    label: const Text('Ver localizacao'),
                  ),
                ],
                if (n.kind == NotificationKind.contactInvite) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    key: Key('notification_accept_${n.id}'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(44, 48)),
                    onPressed: onOpen,
                    child: const Text('Ver convite e aceitar'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
