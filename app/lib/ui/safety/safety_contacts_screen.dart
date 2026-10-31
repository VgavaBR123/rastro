// Rastro Seguro (F08), pelas Configuracoes: contatos de confianca. Convidar
// por email, convites enviados e recebidos (pendente ou aceito), aceitar e
// remover (com confirmacao). Exige login; deslogado convida a entrar.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../safety/contacts_controller.dart';
import '../../safety/safety_alerts.dart' show kNoPushNotice;
import '../../safety/safety_models.dart';
import '../../safety/safety_providers.dart';
import '../section_card.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

class SafetyContactsScreen extends ConsumerStatefulWidget {
  const SafetyContactsScreen({super.key});

  @override
  ConsumerState<SafetyContactsScreen> createState() => _SafetyContactsScreenState();
}

class _SafetyContactsScreenState extends ConsumerState<SafetyContactsScreen> {
  final _email = TextEditingController();
  String? _inviteError;
  String? _inviteDone;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(authControllerProvider).isSignedIn) {
        ref.read(contactsProvider.notifier).load();
      }
    });
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _invite() async {
    final email = _email.text;
    setState(() {
      _inviteError = null;
      _inviteDone = null;
    });
    final err = await ref.read(contactsProvider.notifier).invite(email);
    if (!mounted) return;
    setState(() {
      _inviteError = err;
      if (err == null) {
        _inviteDone = 'Convite enviado. Assim que a pessoa aceitar, ela aparece como contato.';
        _email.clear();
      }
    });
  }

  Future<void> _remove(TrustedContact contact) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover contato?'),
        content: Text(
          '${contact.label} deixa de ser avisado(a) no Rastro Seguro, '
          'inclusive na atividade em andamento.',
        ),
        actions: [
          TextButton(
            key: const Key('contact_remove_cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('contact_remove_confirm'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.of(ctx).danger,
              foregroundColor: AppColors.of(ctx).bg,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final err = await ref.read(contactsProvider.notifier).remove(contact.id);
    if (err != null && mounted) _snack(err);
  }

  Future<void> _accept(TrustedContact contact) async {
    final err = await ref.read(contactsProvider.notifier).accept(contact.id);
    if (!mounted) return;
    _snack(err ?? 'Agora voce e contato de confianca de ${contact.label}. $kNoPushNotice');
  }

  void _snack(String text) => ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final signedIn = ref.watch(authControllerProvider.select((s) => s.isSignedIn));
    // A conta pode terminar de carregar depois da tela abrir.
    ref.listen<bool>(authControllerProvider.select((s) => s.isSignedIn), (_, v) {
      if (v) ref.read(contactsProvider.notifier).load();
    });
    final s = ref.watch(contactsProvider);
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppShape.gutter, 0, AppShape.gutter, 24),
        children: [
          const ScreenTitle(
            'Rastro Seguro',
            subtitle: 'Ate 3 pessoas de confianca sao avisadas se voce nao chegar no horario combinado.',
          ),
          if (!signedIn)
            const SafetySignedOutCard(
              key: Key('safety_signed_out'),
              message: 'Os contatos de confianca sao outras contas do Rastro. Entre na sua conta para convidar.',
            )
          else ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                kNoPushNotice,
                key: const Key('safety_push_notice'),
                style: AppText.label.copyWith(color: AppColors.of(context).extra.fg),
              ),
            ),
            _InviteCard(
              controller: _email,
              busy: s.busy,
              error: _inviteError,
              done: _inviteDone,
              full: (s.lists?.outgoing.where((x) => x.accepted).length ?? 0) >= kMaxTrustedContacts,
              onSend: _invite,
            ),
            if (s.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.error!,
                        key: const Key('safety_contacts_error'),
                        style: AppText.body.copyWith(color: c.danger),
                      ),
                    ),
                    TextButton(
                      key: const Key('safety_contacts_retry'),
                      style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
                      onPressed: () => ref.read(contactsProvider.notifier).load(),
                      child: const Text('Tentar de novo'),
                    ),
                  ],
                ),
              ),
            if (s.loading && s.lists == null)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (s.lists case final lists?) ...[
              _ContactSection(
                key: const Key('safety_incoming'),
                title: 'Quem convidou voce',
                empty: 'Nenhum convite recebido.',
                contacts: lists.incoming,
                busy: s.busy,
                onAccept: _accept,
                onRemove: _remove,
              ),
              _ContactSection(
                key: const Key('safety_outgoing'),
                title: 'Quem voce convidou',
                empty: 'Voce ainda nao convidou ninguem.',
                contacts: lists.outgoing,
                busy: s.busy,
                onRemove: _remove,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// Cartao "entre na sua conta" com o botao que leva ao login.
class SafetySignedOutCard extends StatelessWidget {
  final String message;
  const SafetySignedOutCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SectionCard(
      title: 'Entre na sua conta',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(message, style: AppText.body.copyWith(color: c.textMuted)),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('safety_sign_in'),
              style: FilledButton.styleFrom(minimumSize: const Size(44, 48)),
              onPressed: () => context.push(AppRoutes.auth),
              child: const Text('Entrar ou criar conta'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  final TextEditingController controller;
  final bool busy;
  final bool full;
  final String? error;
  final String? done;
  final VoidCallback onSend;

  const _InviteCard({
    required this.controller,
    required this.busy,
    required this.full,
    required this.error,
    required this.done,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SectionCard(
      title: 'Convidar por email',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              full
                  ? 'Voce ja tem 3 contatos aceitos, o maximo. Remova um para convidar outro.'
                  : 'A pessoa precisa ter conta no Rastro e aceitar o convite.',
              style: AppText.label.copyWith(color: c.textMuted),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const Key('safety_invite_email'),
              controller: controller,
              enabled: !full,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.send,
              decoration: const InputDecoration(labelText: 'Email'),
              onSubmitted: (_) => onSend(),
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Semantics(
                liveRegion: true,
                child: Text(
                  error!,
                  key: const Key('safety_invite_error'),
                  style: AppText.body.copyWith(color: c.danger),
                ),
              ),
            ],
            if (done != null) ...[
              const SizedBox(height: 8),
              Semantics(
                liveRegion: true,
                child: Text(
                  done!,
                  key: const Key('safety_invite_done'),
                  style: AppText.body.copyWith(color: c.dist.fg),
                ),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('safety_invite_send'),
              style: FilledButton.styleFrom(minimumSize: const Size(44, 48)),
              onPressed: busy || full ? null : onSend,
              icon: const Icon(Icons.send_rounded),
              label: const Text('Enviar convite'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactSection extends StatelessWidget {
  final String title;
  final String empty;
  final List<TrustedContact> contacts;
  final bool busy;
  final ValueChanged<TrustedContact>? onAccept;
  final ValueChanged<TrustedContact> onRemove;

  const _ContactSection({
    super.key,
    required this.title,
    required this.empty,
    required this.contacts,
    required this.busy,
    this.onAccept,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SectionCard(
      title: title,
      child: contacts.isEmpty
          ? Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Text(empty, style: AppText.body.copyWith(color: c.textMuted)),
            )
          : Column(
              children: [
                for (var i = 0; i < contacts.length; i++) ...[
                  if (i > 0) const SectionDivider(),
                  _ContactTile(contact: contacts[i], busy: busy, onAccept: onAccept, onRemove: onRemove),
                ],
              ],
            ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final TrustedContact contact;
  final bool busy;
  final ValueChanged<TrustedContact>? onAccept;
  final ValueChanged<TrustedContact> onRemove;

  const _ContactTile({required this.contact, required this.busy, this.onAccept, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final pending = !contact.accepted;
    final role = pending ? c.extra : c.dist;
    return ListTile(
      key: Key('contact_${contact.id}'),
      minTileHeight: 64,
      leading: Icon(pending ? Icons.hourglass_top_rounded : Icons.verified_user_rounded, color: role.fg),
      title: Text(contact.label, style: AppText.bodyStrong.copyWith(color: c.text)),
      subtitle: Text(
        '${contact.email}\n${pending ? 'Pendente' : 'Aceito'}',
        key: Key('contact_status_${contact.id}'),
        style: AppText.label.copyWith(color: c.textMuted),
      ),
      isThreeLine: true,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pending && onAccept != null)
            FilledButton(
              key: Key('contact_accept_${contact.id}'),
              style: FilledButton.styleFrom(minimumSize: const Size(44, 44)),
              onPressed: busy ? null : () => onAccept!(contact),
              child: const Text('Aceitar'),
            ),
          IconButton(
            key: Key('contact_remove_${contact.id}'),
            tooltip: pending && onAccept != null ? 'Recusar convite' : 'Remover contato',
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            onPressed: busy ? null : () => onRemove(contact),
            icon: Icon(Icons.person_remove_rounded, color: c.danger),
          ),
        ],
      ),
    );
  }
}
