// Tela inicial: escolha do esporte e inicio da gravacao.
library;

import 'package:flutter/material.dart';

import '../recording/domain/recording_models.dart';
import 'history_screen.dart';
import 'recording_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
