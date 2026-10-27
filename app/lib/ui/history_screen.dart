// Historico de atividades finalizadas.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../core/format/activity_labels.dart';
import '../core/format/measures.dart';
import '../persistence/database.dart';
import '../recording/domain/recording_models.dart';
import 'activity_detail_screen.dart';
import '../sync/sync_controller.dart' show kSignInToSyncMessage;
import '../sync/background/background_sync_provider.dart';
import 'auth_screen.dart';

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
      if (msg != null && msg != prev?.message) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(msg),
            action: msg == kSignInToSyncMessage
                ? SnackBarAction(
                    label: 'Entrar',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AuthScreen()),
                    ),
                  )
                : null,
          ));
        ref.invalidate(recentActivitiesProvider);
        ref.invalidate(pendingCountProvider);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historico'),
        actions: [
          IconButton(
            key: const Key('sync'),
            tooltip: pending > 0 ? 'Sincronizar ($pending)' : 'Sincronizar',
            icon: sync.running
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Badge(
                    isLabelVisible: pending > 0,
                    label: Text('$pending'),
                    child: const Icon(Icons.cloud_upload),
                  ),
            onPressed: sync.running
                ? null
                : () => ref.read(syncControllerProvider.notifier).syncNow(),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Nenhuma atividade ainda'));
          }
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) => _ActivityTile(list[i]),
          );
        },
      ),
    );
  }
}

class _ActivityTile extends ConsumerWidget {
  final Activity activity;
  const _ActivityTile(this.activity);

  IconData get _icon {
    switch (activity.activityType) {
      case ActivityType.run:
        return Icons.directions_run;
      case ActivityType.ride:
        return Icons.directions_bike;
      case ActivityType.walk:
        return Icons.directions_walk;
    }
  }

  /// Pede confirmacao e, se confirmado, apaga a atividade e atualiza as listas.
  /// Menu de contexto em vez de swipe: e o caminho mais simples de dirigir em
  /// widget test (tap no menu, tap no item) e nao depende de gesto/velocidade.
  Future<void> _confirmAndDelete(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir atividade?'),
        content: Text(activity.remoteId != null
            ? 'Ela tambem sera apagada do servidor. '
                'Esta acao nao pode ser desfeita.'
            : 'Esta acao nao pode ser desfeita.'),
        actions: [
          TextButton(
            key: const Key('cancel-delete'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            key: const Key('confirm-delete'),
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
    return ListTile(
      leading: Icon(_icon),
      title: Text(
        '${activityTypeLabel(activity.activityType)} - ${formatDateTimeMs(activity.startTimestampMs)}',
      ),
      subtitle: Text(
        '${formatDistance(activity.distanceMeters)} - ${formatDuration(activity.timerTimeMs)}',
      ),
      trailing: PopupMenuButton<String>(
        key: Key('menu-${activity.guid}'),
        tooltip: 'Acoes da atividade',
        onSelected: (value) {
          if (value == 'delete') _confirmAndDelete(context, ref);
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            key: Key('delete-${activity.guid}'),
            value: 'delete',
            child: const Text('Excluir'),
          ),
        ],
      ),
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ActivityDetailScreen(activity: activity),
        ));
      },
    );
  }
}
