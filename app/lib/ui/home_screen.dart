// Tela inicial: escolha do esporte e inicio da gravacao. Na abertura, oferece
// recuperar uma atividade que ficou sem finalizar (app morto, reboot).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../recording/domain/recording_models.dart';
import '../sync/background/background_sync_provider.dart';
import 'history_screen.dart';
import 'recording_screen.dart';
import 'recovery_dialog.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkInterrupted());
  }

  Future<void> _checkInterrupted() async {
    final ctrl = ref.read(recordingControllerProvider.notifier);
    if (ref.read(recordingControllerProvider).isActive) return;
    final repo = ref.read(recordingRepositoryProvider);
    final list = await repo.interrupted(exceptGuid: ctrl.activityGuid);
    var changed = false;
    // Mais recente primeiro; so a primeira ainda pode ser retomada.
    for (var i = 0; i < list.length; i++) {
      final it = list[i];
      if (!mounted) return;
      final choice = await showRecoveryDialog(
        context,
        it,
        metric: ref.read(settingsProvider).useMetric,
        allowResume:
            i == 0 && canResume(it, DateTime.now().millisecondsSinceEpoch),
      );
      if (!mounted) return;
      switch (choice) {
        case RecoveryChoice.resume:
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => RecordingScreen(
              activityType: it.activity.activityType,
              resumeFrom: it,
            ),
          ));
          return;
        case RecoveryChoice.save:
          await repo.finishInterrupted(it);
          ref.read(backgroundSyncSchedulerProvider).scheduleSoon();
          changed = true;
        case RecoveryChoice.discard:
          await repo.deleteActivity(it.activity.guid);
          changed = true;
        case null:
          return;
      }
    }
    if (changed) {
      ref.invalidate(recentActivitiesProvider);
      ref.invalidate(pendingCountProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atividades'),
        actions: [
          IconButton(
            key: const Key('history'),
            icon: const Icon(Icons.history),
            tooltip: 'Historico',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const HistoryScreen(),
              ));
            },
          ),
          IconButton(
            key: const Key('settings'),
            icon: const Icon(Icons.settings),
            tooltip: 'Configuracoes',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const SettingsScreen(),
              ));
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Escolha a atividade', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 24),
            _ActivityButton(type: ActivityType.run, label: 'Correr', icon: Icons.directions_run),
            _ActivityButton(type: ActivityType.ride, label: 'Pedalar', icon: Icons.directions_bike),
            _ActivityButton(type: ActivityType.walk, label: 'Caminhar', icon: Icons.directions_walk),
          ],
        ),
      ),
    );
  }
}

class _ActivityButton extends StatelessWidget {
  final ActivityType type;
  final String label;
  final IconData icon;
  const _ActivityButton({required this.type, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 32),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          icon: Icon(icon),
          label: Text(label),
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => RecordingScreen(activityType: type),
            ));
          },
        ),
      ),
    );
  }
}
