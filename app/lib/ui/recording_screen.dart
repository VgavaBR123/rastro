// Tela de gravacao: inicia a captura, mostra metricas ao vivo e controla
// pausar/retomar/encerrar. Consome o RecordingController via Riverpod.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../core/format/measures.dart';
import '../persistence/recording_repository.dart';
import '../recording/domain/recording_models.dart';
import '../sync/background/background_sync_provider.dart';
import 'route_preview.dart';

class RecordingScreen extends ConsumerStatefulWidget {
  final ActivityType activityType;

  /// Quando presente, continua esta atividade interrompida em vez de comecar
  /// uma nova.
  final InterruptedActivity? resumeFrom;

  const RecordingScreen({
    super.key,
    required this.activityType,
    this.resumeFrom,
  });

  @override
  ConsumerState<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends ConsumerState<RecordingScreen> {
  @override
  void initState() {
    super.initState();
    // Inicia (ou retoma) a gravacao assim que a tela abre.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = ref.read(recordingControllerProvider.notifier);
      final resumeFrom = widget.resumeFrom;
      if (resumeFrom != null) {
        ctrl.resumeInterrupted(resumeFrom);
        return;
      }
      final autoPause = ref.read(settingsProvider).autoPauseEnabled;
      ctrl.start(widget.activityType, autoPauseEnabled: autoPause);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(recordingControllerProvider);
    final ctrl = ref.read(recordingControllerProvider.notifier);
    final metric = ref.watch(settingsProvider).useMetric;

    return Scaffold(
      appBar: AppBar(title: Text(_title(widget.activityType))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            RoutePreview(route: ctrl.route),
            const SizedBox(height: 16),
            if (s.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(s.error!, style: const TextStyle(color: Colors.red)),
              ),
            _Metric(label: 'Distancia', value: formatDistance(s.distanceMeters, metric: metric), key: const Key('distance')),
            _Metric(label: 'Tempo', value: formatDuration(s.timerMs), key: const Key('duration')),
            _Metric(label: 'Pace', value: formatPace(s.avgPaceSecondsPerMeter, metric: metric), key: const Key('pace')),
            _Metric(label: 'Elevacao', value: formatElevation(s.ascentMeters, metric: metric), key: const Key('elevation')),
            const SizedBox(height: 32),
            _Controls(
              state: s.state,
              ctrl: ctrl,
              // Atividade nova na fila: pede um sync assim que houver rede.
              onStopped: () =>
                  ref.read(backgroundSyncSchedulerProvider).scheduleSoon(),
            ),
          ],
        ),
      ),
    );
  }

  String _title(ActivityType t) {
    switch (t) {
      case ActivityType.run:
        return 'Corrida';
      case ActivityType.ride:
        return 'Pedal';
      case ActivityType.walk:
        return 'Caminhada';
    }
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  const _Metric({required this.label, required this.value, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  final RecordingState state;
  final dynamic ctrl;
  final VoidCallback onStopped;
  const _Controls({
    required this.state,
    required this.ctrl,
    required this.onStopped,
  });

  @override
  Widget build(BuildContext context) {
    final paused = state == RecordingState.manuallyPaused ||
        state == RecordingState.autoPaused;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (!paused)
          FilledButton.icon(
            key: const Key('pause'),
            icon: const Icon(Icons.pause),
            label: const Text('Pausar'),
            onPressed: ctrl.pause,
          )
        else
          FilledButton.icon(
            key: const Key('resume'),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Retomar'),
            onPressed: ctrl.resume,
          ),
        FilledButton.icon(
          key: const Key('stop'),
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          icon: const Icon(Icons.stop),
          label: const Text('Encerrar'),
          onPressed: () async {
            await ctrl.stop();
            onStopped();
            if (context.mounted) Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
