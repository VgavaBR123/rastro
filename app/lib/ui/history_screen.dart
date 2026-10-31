// Historico de atividades finalizadas, em cartoes compactos (relatorio 11),
// com sincronizar (badge de pendentes) e excluir com confirmacao.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../app/providers.dart';
import '../app/router.dart';
import '../persistence/database.dart';
import '../sync/background/background_sync_provider.dart';
import '../sync/sync_controller.dart'
    show kSessionExpiredMessage, kSignInToSyncMessage;
import 'components/activity_card.dart';
import 'components/app_nav_bar.dart';
import 'share_activity.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'theme/app_typography.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recentActivitiesProvider);
    final sync = ref.watch(syncControllerProvider);
    final pending = ref.watch(pendingCountProvider).value ?? 0;

    // Mostra o resultado da sincronizacao e atualiza as listas.
    ref.listen(syncControllerProvider, (prev, next) {
      final msg = next.message;
      if (msg != null && next.messageSeq != prev?.messageSeq) {
        final signIn =
            msg == kSignInToSyncMessage || msg == kSessionExpiredMessage;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(msg),
              // Com acao o SnackBar fica fixo por padrao; aqui ele some
              // sozinho como os outros avisos (HIS-02).
              persist: false,
              duration: const Duration(seconds: 4),
              action: signIn
                  ? SnackBarAction(
                      label: 'Entrar',
                      onPressed: () => context.push(AppRoutes.auth),
                    )
                  : null,
            ),
          );
        ref.invalidate(recentActivitiesProvider);
        ref.invalidate(pendingCountProvider);
      }
    });

    final c = AppColors.of(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppShape.gutter, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Historico',
                      style: AppText.screenTitle.copyWith(color: c.text),
                    ),
                  ),
                  IconButton(
                    key: const Key('sync'),
                    // Rotulo unico: o numero do selo nao e lido de novo
                    // (HIS-11).
                    tooltip: switch (pending) {
                      0 => 'Sincronizar',
                      1 => 'Sincronizar, 1 pendente',
                      _ => 'Sincronizar, $pending pendentes',
                    },
                    icon: sync.running
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Badge(
                            isLabelVisible: pending > 0,
                            backgroundColor: c.pace.fill,
                            textColor: c.onFill,
                            label: ExcludeSemantics(child: Text('$pending')),
                            child: Icon(
                              Icons.cloud_upload_rounded,
                              color: c.pace.fg,
                            ),
                          ),
                    onPressed: sync.running
                        ? null
                        : () => ref
                              .read(syncControllerProvider.notifier)
                              .syncNow(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text(
                    'Erro: $e',
                    style: AppText.body.copyWith(color: c.danger),
                  ),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return Center(
                      child: Text(
                        'Nenhuma atividade ainda',
                        style: AppText.body.copyWith(color: c.textMuted),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      AppShape.gutter,
                      8,
                      AppShape.gutter,
                      AppNavBar.reservedHeight(context),
                    ),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _ActivityTile(list[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends ConsumerWidget {
  final Activity activity;
  const _ActivityTile(this.activity);

  /// Pede confirmacao e, se confirmado, apaga a atividade e atualiza as listas.
  /// Menu de contexto em vez de swipe: e o caminho mais simples de dirigir em
  /// widget test (tap no menu, tap no item) e nao depende de gesto/velocidade.
  Future<void> _confirmAndDelete(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir atividade?'),
        content: Text(
          activity.remoteId != null
              ? 'Ela tambem sera apagada do servidor. '
                    'Esta acao nao pode ser desfeita.'
              : 'Esta acao nao pode ser desfeita.',
        ),
        actions: [
          TextButton(
            key: const Key('cancel-delete'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            key: const Key('confirm-delete'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.of(dialogContext).danger,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(recordingRepositoryProvider).deleteActivity(activity.guid);
    // Leva a exclusao ao servidor assim que houver rede.
    if (activity.remoteId != null) {
      ref.read(backgroundSyncSchedulerProvider).scheduleSoon();
    }
    ref.invalidate(recentActivitiesProvider);
    ref.invalidate(pendingCountProvider);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Atividade excluida')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ActivityCard(
      key: Key('tile-${activity.guid}'),
      activity: activity,
      useMetric: ref.watch(settingsProvider.select((s) => s.useMetric)),
      compact: true,
      onOpen: () {
        context.push(AppRoutes.activity(activity.guid), extra: activity);
      },
      trailing: PopupMenuButton<String>(
        key: Key('menu-${activity.guid}'),
        tooltip: 'Acoes da atividade',
        icon: Icon(
          Icons.more_horiz_rounded,
          color: AppColors.of(context).textMuted,
        ),
        onSelected: (value) {
          if (value == 'share') shareActivity(context, activity);
          if (value == 'delete') _confirmAndDelete(context, ref);
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            key: Key('share-${activity.guid}'),
            value: 'share',
            child: const Text('Compartilhar'),
          ),
          PopupMenuItem(
            key: Key('delete-${activity.guid}'),
            value: 'delete',
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}
