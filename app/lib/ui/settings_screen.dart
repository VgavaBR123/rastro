// Tela de configuracoes: unidades e pausa automatica.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Configuracoes')),
      body: ListView(
        children: [
          SwitchListTile(
            key: const Key('metric'),
            title: const Text('Unidades metricas'),
            subtitle: Text(s.useMetric ? 'km, m, min/km' : 'mi, ft, min/mi'),
            value: s.useMetric,
            onChanged: ctrl.setUseMetric,
          ),
          SwitchListTile(
            key: const Key('autopause'),
            title: const Text('Pausa automatica'),
            subtitle: const Text('Pausa sozinho quando voce para'),
            value: s.autoPauseEnabled,
            onChanged: ctrl.setAutoPauseEnabled,
          ),
        ],
      ),
    );
  }
}
