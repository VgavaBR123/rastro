// Tela de gravacao: inicia a captura, mostra metricas ao vivo (com split e
// volta correntes) e controla pausar/retomar/volta/encerrar. Consome o
// RecordingController via Riverpod. As mesmas acoes chegam pela notificacao;
// encerrar por qualquer caminho fecha esta tela.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../core/format/measures.dart';
import '../persistence/recording_repository.dart';
import '../recording/domain/recording_models.dart';
import '../recording/presentation/recording_controller.dart';
import '../recording/presentation/recording_ui_state.dart';
import '../sync/background/background_sync_provider.dart';
import 'route_map.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Com o app recem-aberto as configuracoes podem nao ter vindo do banco
      // ainda; sem esperar, a gravacao usaria os padroes (auto-pausa ligada,
      // sem peso para as calorias).
      await ref.read(settingsProvider.notifier).ensureLoaded();
      if (!mounted) return;
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

  bool _closed = false;

  /// Gravacao encerrada (pela tela ou pela notificacao): pede sync da
  /// atividade nova e fecha a tela, uma vez so.
  void _onFinished() {
    if (_closed) return;
    _closed = true;
    ref.read(backgroundSyncSchedulerProvider).scheduleSoon();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<RecordingUiState>(recordingControllerProvider, (prev, next) {
      if (next.state == RecordingState.finished &&
          prev?.state != RecordingState.finished) {
        _onFinished();
      }
    });
    final s = ref.watch(recordingControllerProvider);
    final ctrl = ref.read(recordingControllerProvider.notifier);
    final metric = ref.watch(settingsProvider).useMetric;
    final split = s.split(metric: metric);

    return Scaffold(
      appBar: AppBar(title: Text(_title(widget.activityType))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            RouteMap(route: ctrl.route, mode: RouteMapMode.follow),
            const SizedBox(height: 16),
            if (s.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  s.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            _Metric(
              label: 'Distancia',
              value: formatDistance(s.distanceMeters, metric: metric),
              key: const Key('distance'),
            ),
            _Metric(
              label: 'Tempo',
              value: formatDuration(s.timerMs),
              key: const Key('duration'),
            ),
            _Metric(
              label: 'Pace',
              value: formatPace(s.avgPaceSecondsPerMeter, metric: metric),
              key: const Key('pace'),
            ),
            _Metric(
              label: 'Elevacao',
              value: formatElevation(s.ascentMeters, metric: metric),
              key: const Key('elevation'),
            ),
            const SizedBox(height: 8),
            _LiveRow(
              key: const Key('current_split'),
              label: '${metric ? 'Km' : 'Milha'} ${split.number}',
              distance: formatDistance(split.distanceMeters, metric: metric),
              detail: formatPace(split.paceSecondsPerMeter, metric: metric),
            ),
            _LiveRow(
              key: const Key('current_lap'),
              label: 'Volta ${s.currentLap.number}',
              distance: formatDistance(
                s.currentLap.distanceMeters,
                metric: metric,
              ),
              detail: formatDuration(s.currentLap.timerMs),
            ),
            const SizedBox(height: 32),
            _Controls(
              state: s.state,
              ctrl: ctrl,
              onStopped: () {
                // Sem sessao ativa o stop nao muda o estado; fecha mesmo assim.
                if (ref.read(recordingControllerProvider).state !=
                    RecordingState.finished) {
                  _onFinished();
                }
              },
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
          Text(
            value,
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

/// Linha compacta do split ou da volta corrente.
class _LiveRow extends StatelessWidget {
  final String label;
  final String distance;
  final String detail;
  const _LiveRow({
    required this.label,
    required this.distance,
    required this.detail,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 18);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(distance, style: style, textAlign: TextAlign.center),
          ),
          Expanded(
            child: Text(detail, style: style, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  final RecordingState state;
  final RecordingController ctrl;
  final VoidCallback onStopped;
  const _Controls({
    required this.state,
    required this.ctrl,
    required this.onStopped,
  });

  @override
  Widget build(BuildContext context) {
    final paused =
        state == RecordingState.manuallyPaused ||
        state == RecordingState.autoPaused;
    return Wrap(
      alignment: WrapAlignment.spaceEvenly,
      spacing: 12,
      runSpacing: 12,
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
        OutlinedButton.icon(
          key: const Key('lap'),
          icon: const Icon(Icons.flag),
          label: const Text('Volta'),
          onPressed: ctrl.lap,
        ),
        FilledButton.icon(
          key: const Key('stop'),
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          icon: const Icon(Icons.stop),
          label: const Text('Encerrar'),
          onPressed: () async {
            await ctrl.stop();
            onStopped();
          },
        ),
      ],
    );
  }
}
