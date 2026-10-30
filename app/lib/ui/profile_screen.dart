// Voce (aba fixa): deslogado, convida a entrar ou criar conta. Logado: avatar
// com o anel, nome editavel, e-mail, totais da semana, recordes pessoais,
// totais do que ja foi sincronizado, seguranca da conta (trocar senha, sair de
// todos os aparelhos), sair e excluir conta. Sair ou excluir deixa a aba no
// estado deslogado (nao ha tela para fechar).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../activity/stats_summary.dart';
import '../app/providers.dart';
import '../app/router.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_models.dart';
import '../core/format/activity_labels.dart';
import '../core/format/measures.dart';
import '../recording/domain/recording_models.dart';
import 'account_dialogs.dart';
import 'components/app_nav_bar.dart';
import 'components/gradient_ring.dart';
import 'section_card.dart';
import 'stats_screen.dart' show StatsTotalsGrid;
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'theme/app_typography.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    final metric = ref.watch(settingsProvider).useMetric;

    final List<Widget> children;
    if (auth.status == AuthStatus.unknown) {
      // Lendo a sessao guardada: e rapido, so evita piscar o convite.
      children = const [
        Padding(
          padding: EdgeInsets.all(48),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    } else if (user == null) {
      children = [
        const _SignedOutCard(),
        ..._localSections(ref, metric),
        const _SettingsLink(),
      ];
    } else {
      children = [
        _UserCard(user: user),
        ..._localSections(ref, metric),
        _CloudTotals(metric: metric),
        _AccountSecurity(),
        const _SettingsLink(),
        const _LogoutCard(),
        const _DangerZone(),
      ];
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        // Pagina curta e heterogenea: coluna inteira montada (sem lista
        // preguicosa), para o topo continuar na arvore ao rolar ate o fim.
        child: SingleChildScrollView(
          key: const Key('profile_list'),
          padding: EdgeInsets.fromLTRB(
            AppShape.gutter,
            0,
            AppShape.gutter,
            AppNavBar.reservedHeight(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [const ScreenTitle('Voce'), ...children],
          ),
        ),
      ),
    );
  }

  /// Totais da semana e recordes, calculados com as atividades do aparelho.
  List<Widget> _localSections(WidgetRef ref, bool metric) {
    final stats = ref.watch(statsProvider).value;
    if (stats == null) return const [];
    // Modo Gentil (F04): sem o recorde de pace.
    final gentle = ref.watch(settingsProvider).gentleMode;
    final records = [
      for (final r in stats.records)
        if (!(gentle && r.kind == RecordKind.bestPace)) r,
    ];
    return [
      SectionCard(
        title: 'Esta semana',
        padding: const EdgeInsets.all(12),
        child: StatsTotalsGrid(
          totals: stats.summary.totals(StatsPeriod.week),
          metric: metric,
          keyPrefix: 'profile_week',
        ),
      ),
      if (records.isNotEmpty)
        SectionCard(
          title: 'Recordes pessoais',
          child: Column(
            children: [
              for (var i = 0; i < records.length; i++) ...[
                if (i > 0) const SectionDivider(),
                _RecordRow(record: records[i], metric: metric),
              ],
            ],
          ),
        ),
    ];
  }
}

/// SnackBar acima da navegacao flutuante.
void _snack(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.fromLTRB(
        AppShape.gutter,
        0,
        AppShape.gutter,
        AppNavBar.reservedHeight(context),
      ),
    ),
  );
}

/// Iniciais do nome ("Ana Lima" -> "AL"); sem nome, "?".
String profileInitials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  final first = parts.first.characters.first;
  final last = parts.length > 1 ? parts.last.characters.first : '';
  return (first + last).toUpperCase();
}

class _Avatar extends StatelessWidget {
  final Widget child;
  const _Avatar({required this.child});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GradientRing(
      width: 3,
      child: Container(
        width: 72,
        height: 72,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: c.bg, shape: BoxShape.circle),
        child: Container(
          decoration: BoxDecoration(color: c.surface2, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}

class _SignedOutCard extends StatelessWidget {
  const _SignedOutCard();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SectionCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _Avatar(
            child: Icon(Icons.person_rounded, size: 34, color: c.extra.fg),
          ),
          const SizedBox(height: 14),
          Text(
            'Entre para guardar seus treinos',
            textAlign: TextAlign.center,
            style: AppText.sectionTitle.copyWith(color: c.text),
          ),
          const SizedBox(height: 6),
          Text(
            'Com a conta, suas atividades sobem para o servidor e voce nao '
            'perde nada ao trocar de aparelho. Gravar funciona sem ela.',
            textAlign: TextAlign.center,
            style: AppText.body.copyWith(color: c.textMuted),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('profile_signin'),
              icon: const Icon(Icons.login_rounded),
              label: const Text('Entrar ou criar conta'),
              onPressed: () => context.push(AppRoutes.auth),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends ConsumerWidget {
  final AppUser user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    return SectionCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _Avatar(
            child: Text(
              profileInitials(user.displayName),
              style: AppText.sectionTitle.copyWith(color: c.text),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  key: const Key('profile_name'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sectionTitle.copyWith(color: c.text),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body.copyWith(color: c.textMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  'Membro desde ${formatDateTimeMs(user.createdAtMs).split(' ').first}',
                  style: AppText.label.copyWith(color: c.textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            key: const Key('profile_edit_name'),
            icon: Icon(Icons.edit_rounded, color: c.extra.fg),
            tooltip: 'Editar nome',
            onPressed: () => _editName(context, ref, user.displayName),
          ),
        ],
      ),
    );
  }

  Future<void> _editName(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(initial: current),
    );
    if (name == null || name.trim().isEmpty || name.trim() == current) return;
    final ok = await ref
        .read(authControllerProvider.notifier)
        .updateDisplayName(name);
    if (!ok && context.mounted) {
      _snack(context, 'Nao foi possivel salvar o nome');
    }
  }
}

/// Dialogo do nome. O controller vive no State para ser descartado so quando o
/// dialogo sai da arvore (descartar ao fechar quebra a animacao de saida).
class _NameDialog extends StatefulWidget {
  final String initial;
  const _NameDialog({required this.initial});

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Seu nome'),
      content: TextField(
        key: const Key('profile_name_field'),
        controller: _controller,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('profile_name_save'),
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

/// Nome do recorde ("Corrida mais longa", "Pedal mais longo"...).
String recordLabel(PersonalRecord r) => switch (r.kind) {
  RecordKind.longestDistance => switch (r.type) {
    ActivityType.ride => 'Pedal mais longo',
    _ => '${activityTypeLabel(r.type)} mais longa',
  },
  RecordKind.bestPace => 'Melhor pace na corrida',
  RecordKind.longestTime => 'Mais tempo num pedal',
};

class _RecordRow extends StatelessWidget {
  final PersonalRecord record;
  final bool metric;
  const _RecordRow({required this.record, required this.metric});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final role = c.sport(record.type);
    final label = recordLabel(record);
    final value = switch (record.kind) {
      RecordKind.longestDistance => formatDistance(
        record.value,
        metric: metric,
      ),
      RecordKind.bestPace => formatPace(record.value, metric: metric),
      RecordKind.longestTime => formatDuration(record.value.round()),
    };
    return Padding(
      key: Key('profile_record_${record.type.name}_${record.kind.name}'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppShape.gutter,
        vertical: 12,
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: role.fill, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppText.bodyStrong.copyWith(color: c.text)),
                Text(
                  formatDateTimeMs(record.entry.startTimestampMs)
                      .split(' ')
                      .first,
                  style: AppText.label.copyWith(color: c.textMuted),
                ),
              ],
            ),
          ),
          Text(value, style: AppText.metricS.copyWith(color: role.fg)),
        ],
      ),
    );
  }
}

/// Totais do servidor (exigem rede): atividades sincronizadas e distancia.
class _CloudTotals extends ConsumerWidget {
  final bool metric;
  const _CloudTotals({required this.metric});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    // A aba fica viva no shell: rele os totais quando um sync termina ou a
    // lista local muda (salvar, apagar, recuperar), senao ficam velhos.
    ref.listen(syncControllerProvider, (prev, next) {
      if (prev?.running == true && !next.running) {
        ref.invalidate(profileProvider);
      }
    });
    ref.listen(recentActivitiesProvider, (prev, next) {
      if (prev != null && next.hasValue && !next.isLoading) {
        ref.invalidate(profileProvider);
      }
    });
    final profile = ref.watch(profileProvider);
    final muted = AppText.label.copyWith(color: c.textMuted);
    Widget total(String label, String value, Key key, RoleColors role) =>
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: muted),
              const SizedBox(height: 4),
              Text(
                value,
                key: key,
                style: AppText.metricM.copyWith(color: role.fg),
              ),
            ],
          ),
        );
    return SectionCard(
      title: 'Na sua conta',
      padding: const EdgeInsets.all(16),
      child: profile.when(
        data: (p) => Row(
          children: [
            total(
              'Atividades sincronizadas',
              '${p.stats.activityCount}',
              const Key('profile_count'),
              c.ciano,
            ),
            const SizedBox(width: 12),
            total(
              'Distancia total',
              formatDistance(p.stats.totalDistanceMeters, metric: metric),
              const Key('profile_distance'),
              c.dist,
            ),
          ],
        ),
        loading: () => const Padding(
          padding: EdgeInsets.all(8),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => Row(
          children: [
            Icon(Icons.cloud_off_rounded, color: c.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Totais indisponiveis sem conexao',
                style: AppText.body.copyWith(color: c.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountSecurity extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    return SectionCard(
      title: 'Seguranca da conta',
      child: Column(
        children: [
          ListTile(
            key: const Key('profile_change_password'),
            leading: Icon(Icons.lock_reset_rounded, color: c.ciano.fg),
            title: const Text('Trocar senha'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () async {
              final ok = await showChangePasswordDialog(context);
              // 401 (sessao caiu): a aba ja mostra o estado deslogado.
              if (ok && context.mounted) _snack(context, 'Senha alterada');
            },
          ),
          const SectionDivider(),
          ListTile(
            key: const Key('profile_logout_all'),
            leading: Icon(Icons.devices_rounded, color: c.ciano.fg),
            title: const Text('Sair de todos os aparelhos'),
            subtitle: const Text('Encerra a conta em todos, inclusive neste'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => showLogoutAllDialog(context),
          ),
        ],
      ),
    );
  }
}

class _SettingsLink extends StatelessWidget {
  const _SettingsLink();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SectionCard(
      child: ListTile(
        key: const Key('profile_settings'),
        leading: Icon(Icons.tune_rounded, color: c.extra.fg),
        title: const Text('Configuracoes'),
        subtitle: const Text('Unidades, pausa automatica e peso'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => context.push(AppRoutes.settings),
      ),
    );
  }
}

class _LogoutCard extends ConsumerWidget {
  const _LogoutCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SectionCard(
      child: ListTile(
        key: const Key('profile_logout'),
        leading: const Icon(Icons.logout_rounded),
        title: const Text('Sair'),
        subtitle: const Text('Suas atividades continuam neste aparelho'),
        onTap: () => ref.read(authControllerProvider.notifier).logout(),
      ),
    );
  }
}

class _DangerZone extends StatelessWidget {
  const _DangerZone();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SectionCard(
      title: 'Zona de perigo',
      titleColor: c.danger,
      child: ListTile(
        key: const Key('profile_delete_account'),
        leading: Icon(Icons.delete_forever_rounded, color: c.danger),
        title: Text(
          'Excluir conta',
          style: AppText.bodyStrong.copyWith(color: c.danger),
        ),
        subtitle: const Text(
          'Apaga a conta e as atividades no servidor. '
          'As do aparelho continuam.',
        ),
        onTap: () => showDeleteAccountDialog(context),
      ),
    );
  }
}
