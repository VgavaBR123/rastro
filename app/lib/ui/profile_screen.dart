// Perfil: nome editavel, e-mail, totais do que ja foi sincronizado e sair.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../core/format/activity_labels.dart';
import '../core/format/measures.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    final profile = ref.watch(profileProvider);
    final metric = ref.watch(settingsProvider).useMetric;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(user.displayName, key: const Key('profile_name')),
            subtitle: Text(user.email),
            trailing: IconButton(
              key: const Key('profile_edit_name'),
              icon: const Icon(Icons.edit),
              tooltip: 'Editar nome',
              onPressed: () => _editName(context, ref, user.displayName),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Membro desde'),
            subtitle: Text(formatDateTimeMs(user.createdAtMs).split(' ').first),
          ),
          const Divider(),
          profile.when(
            data: (p) => Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_done),
                  title: const Text('Atividades sincronizadas'),
                  trailing: Text(
                    '${p.stats.activityCount}',
                    key: const Key('profile_count'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.straighten),
                  title: const Text('Distancia total'),
                  trailing: Text(
                    formatDistance(p.stats.totalDistanceMeters, metric: metric),
                    key: const Key('profile_distance'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => const ListTile(
              leading: Icon(Icons.cloud_off),
              title: Text('Totais indisponiveis sem conexao'),
            ),
          ),
          const Divider(),
          ListTile(
            key: const Key('profile_logout'),
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sair', style: TextStyle(color: Colors.red)),
            subtitle: const Text('Suas atividades continuam neste aparelho'),
            onTap: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _editName(BuildContext context, WidgetRef ref, String current) async {
    final controller = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seu nome'),
        content: TextField(
          key: const Key('profile_name_field'),
          controller: controller,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('profile_name_save'),
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.trim().isEmpty || name.trim() == current) return;
    final ok =
        await ref.read(authControllerProvider.notifier).updateDisplayName(name);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao foi possivel salvar o nome')),
      );
    }
  }
}
