// Tela de gravacao (relatorio 11, Gravando): sem navegacao, chip de estado,
// tempo e distancia grandes, pace atual, pace medio e subida em blocos, split e
// volta correntes, e o mapa a um deslize. Pausar/Retomar/Volta pela tela ou
// pela notificacao. Encerrar exige segurar e abre a tela Salvar; encerrar pela
// notificacao salva direto e fecha esta tela.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../core/format/measures.dart';
import '../persistence/recording_repository.dart';
import '../recording/domain/geo.dart';
import '../recording/domain/recording_models.dart';
import '../recording/presentation/recording_ui_state.dart';
import '../sync/background/background_sync_provider.dart';
import 'components/big_action_button.dart';
import 'components/floating_map_button.dart';
import 'components/metric_tile.dart';
import 'components/sport_chip.dart';
import 'route_map.dart';
import 'save_activity_view.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'theme/app_typography.dart';

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
  final PageController _pages = PageController();
  int _page = 0;

  /// Tela Salvar aberta (a gravacao segue pausada por baixo).
  bool _saving = false;
  DateTime? _startedAt;

  /// Salvar ou descartar em andamento: o fim da gravacao vem desta tela, que
  /// fecha sozinha depois.
  bool _finishing = false;

  bool _closed = false;

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

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  ActivityType get _type => widget.resumeFrom?.activity.activityType ?? widget.activityType;

  /// Gravacao encerrada fora desta tela (notificacao): pede sync da atividade
  /// nova e fecha a tela, uma vez so.
  void _onFinished() {
    if (_closed || _finishing) return;
    _close(sync: true);
  }

  void _close({required bool sync}) {
    _closed = true;
    if (sync) ref.read(backgroundSyncSchedulerProvider).scheduleSoon();
    ref.invalidate(recentActivitiesProvider);
    ref.invalidate(pendingCountProvider);
    if (mounted) Navigator.of(context).pop();
  }

  /// Segurou Encerrar: pausa (se ainda gravando) e abre a tela Salvar.
  void _openSave() {
    final s = ref.read(recordingControllerProvider);
    if (s.isRecording) ref.read(recordingControllerProvider.notifier).pause();
    setState(() {
      _saving = true;
      _page = 0;
      _startedAt = DateTime.now().subtract(Duration(milliseconds: s.elapsedMs));
    });
  }

  Future<void> _save(ActivityDraft draft) async {
    setState(() => _finishing = true);
    final ctrl = ref.read(recordingControllerProvider.notifier);
    final repo = ref.read(recordingRepositoryProvider);
    // O guid fica no controller depois do fim; so grava os detalhes se havia
    // gravacao.
    final wasActive = ref.read(recordingControllerProvider).isActive;
    final guid = ctrl.activityGuid;
    await ctrl.stop();
    if (wasActive && guid != null) {
      await repo.saveDetails(
        guid,
        title: draft.title,
        description: draft.description,
        visibility: draft.visibility,
      );
    }
    if (!mounted) return;
    _close(sync: true);
  }

  Future<void> _discard() async {
    setState(() => _finishing = true);
    final ctrl = ref.read(recordingControllerProvider.notifier);
    final repo = ref.read(recordingRepositoryProvider);
    // So apaga se havia gravacao: o guid fica no controller depois do fim.
    final wasActive = ref.read(recordingControllerProvider).isActive;
    final guid = ctrl.activityGuid;
    await ctrl.stop();
    if (wasActive && guid != null) await repo.deleteActivity(guid);
    if (!mounted) return;
    _close(sync: false);
  }

  void _togglePage() {
    final next = _page == 0 ? 1 : 0;
    _pages.animateToPage(next, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
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

    final Widget body;
    if (_saving) {
      body = SaveActivityView(
        type: _type,
        route: ctrl.route,
        distanceMeters: s.distanceMeters,
        timerMs: s.timerMs,
        avgPaceSecondsPerMeter: s.avgPaceSecondsPerMeter,
        ascentMeters: s.ascentMeters,
        metric: metric,
        startedAt: _startedAt ?? DateTime.now(),
        busy: _finishing,
        onBack: () => setState(() => _saving = false),
        onSave: _save,
        onDiscard: _discard,
      );
    } else {
      body = _RecordingBody(
        type: _type,
        state: s,
        route: ctrl.route,
        metric: metric,
        pages: _pages,
        page: _page,
        onPageChanged: (i) => setState(() => _page = i),
        onTogglePage: _togglePage,
        onPause: ctrl.pause,
        onResume: ctrl.resume,
        onLap: ctrl.lap,
        onStop: _openSave,
        onClose: () => Navigator.of(context).pop(),
      );
    }

    // Sem navegacao durante a gravacao: o voltar do sistema nao sai da tela
    // (na tela Salvar, volta para a gravacao).
    return PopScope(
      canPop: !s.isActive && !_saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _saving && !_finishing) setState(() => _saving = false);
      },
      child: Scaffold(body: body),
    );
  }
}

class _RecordingBody extends StatelessWidget {
  final ActivityType type;
  final RecordingUiState state;
  final List<GeoPoint> route;
  final bool metric;
  final PageController pages;
  final int page;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onTogglePage;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final Future<Object?> Function() onLap;
  final VoidCallback onStop;
  final VoidCallback onClose;

  const _RecordingBody({
    required this.type,
    required this.state,
    required this.route,
    required this.metric,
    required this.pages,
    required this.page,
    required this.onPageChanged,
    required this.onTogglePage,
    required this.onPause,
    required this.onResume,
    required this.onLap,
    required this.onStop,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final s = state;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppShape.gutter, 12, AppShape.gutter, 8),
            child: Row(
              children: [
                // Wrap + FittedBox: em tela estreita os chips quebram de linha
                // ou encolhem, sem transbordar.
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FittedBox(fit: BoxFit.scaleDown, child: _StateChip(state: s.state)),
                      FittedBox(fit: BoxFit.scaleDown, child: SportChip(type: type)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FloatingMapButton(
                  key: const Key('toggle_map'),
                  icon: page == 0 ? Icons.map_rounded : Icons.speed_rounded,
                  tooltip: page == 0 ? 'Ver o mapa' : 'Ver as metricas',
                  label: page == 0 ? 'Mapa' : 'Metricas',
                  onPressed: onTogglePage,
                ),
              ],
            ),
          ),
          if (s.error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppShape.gutter, 0, AppShape.gutter, 8),
              child: Container(
                key: const Key('recording_error'),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppShape.tile),
                  border: Border.all(color: c.danger),
                ),
                child: Text(s.error!, style: AppText.bodyStrong.copyWith(color: c.danger)),
              ),
            ),
          Expanded(
            child: PageView(
              controller: pages,
              onPageChanged: onPageChanged,
              children: [
                _MetricsPage(state: s, metric: metric),
                _MapPage(type: type, state: s, route: route, metric: metric),
              ],
            ),
          ),
          _PageDots(page: page),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppShape.gutter, 12, AppShape.gutter, 16),
            child: _Controls(
              state: s,
              onPause: onPause,
              onResume: onResume,
              onLap: onLap,
              onStop: onStop,
              onClose: onClose,
            ),
          ),
        ],
      ),
    );
  }
}

/// Gravando em tempo, Pausado em extra.
class _StateChip extends StatelessWidget {
  final RecordingState state;
  const _StateChip({required this.state});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final (String label, RoleColors role) = switch (state) {
      RecordingState.recording => ('Gravando', c.tempo),
      RecordingState.manuallyPaused => ('Pausado', c.extra),
      RecordingState.autoPaused => ('Pausa automatica', c.extra),
      RecordingState.idle => ('Preparando', c.ciano),
      RecordingState.finished => ('Encerrada', c.ciano),
    };
    return SportChip.custom(key: const Key('recording_state'), label: label, role: role);
  }
}

class _MetricsPage extends StatelessWidget {
  final RecordingUiState state;
  final bool metric;
  const _MetricsPage({required this.state, required this.metric});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final s = state;
    final split = s.split(metric: metric);
    final (curPace, curPaceUnit) = splitMeasure(formatPace(split.paceSecondsPerMeter, metric: metric));
    final (avgPace, avgPaceUnit) = splitMeasure(formatPace(s.avgPaceSecondsPerMeter, metric: metric));
    final (ascent, ascentUnit) = splitMeasure(formatElevation(s.ascentMeters, metric: metric));
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppShape.gutter),
      child: AnimatedOpacity(
        // Pausado: metricas a 60% (relatorio 11).
        opacity: s.isPaused ? 0.6 : 1,
        duration: const Duration(milliseconds: 200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            _BigMetric(
              key: const Key('duration'),
              label: 'Tempo',
              value: formatDuration(s.timerMs),
              role: c.tempo,
            ),
            const SizedBox(height: 16),
            _BigMetric(
              key: const Key('distance'),
              label: 'Distancia',
              value: formatDistance(s.distanceMeters, metric: metric),
              role: c.dist,
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: MetricTile(
                    key: const Key('current_pace'),
                    label: 'Pace atual',
                    value: curPace,
                    unit: curPaceUnit,
                    role: c.pace,
                    block: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: MetricTile(
                    key: const Key('pace'),
                    label: 'Pace medio',
                    value: avgPace,
                    unit: avgPaceUnit,
                    role: c.pace,
                    block: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: MetricTile(
                    key: const Key('elevation'),
                    label: 'Subida',
                    value: ascent,
                    unit: ascentUnit,
                    role: c.subida,
                    block: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _LiveRow(
              key: const Key('current_split'),
              label: '${metric ? 'Km' : 'Milha'} ${split.number}',
              distance: formatDistance(split.distanceMeters, metric: metric),
              detail: formatPace(split.paceSecondsPerMeter, metric: metric),
            ),
            _LiveRow(
              key: const Key('current_lap'),
              label: 'Volta ${s.currentLap.number}',
              distance: formatDistance(s.currentLap.distanceMeters, metric: metric),
              detail: formatDuration(s.currentLap.timerMs),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Tempo ou distancia em metricXL. O valor e um Text unico (o teste de ponta a
/// ponta le o ultimo Text debaixo da Key).
class _BigMetric extends StatelessWidget {
  final String label;
  final String value;
  final RoleColors role;
  const _BigMetric({required this.label, required this.value, required this.role, super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      children: [
        Text(label, style: AppText.label.copyWith(color: c.textMuted)),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, maxLines: 1, style: AppText.metricXL.copyWith(color: role.fg)),
        ),
      ],
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
    final c = AppColors.of(context);
    final value = AppText.metricS.copyWith(color: c.text);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: AppText.label.copyWith(color: c.textMuted)),
          ),
          Expanded(
            child: Text(distance, style: value, textAlign: TextAlign.center),
          ),
          Expanded(
            child: Text(detail, style: value, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}

/// Mapa ao vivo com tempo e distancia por baixo.
class _MapPage extends StatelessWidget {
  final ActivityType type;
  final RecordingUiState state;
  final List<GeoPoint> route;
  final bool metric;
  const _MapPage({required this.type, required this.state, required this.route, required this.metric});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppShape.gutter),
      child: Column(
        children: [
          Expanded(
            child: RouteMap(
              key: const Key('recording_map'),
              route: route,
              mode: RouteMapMode.follow,
              height: null,
              color: c.sport(type).fill,
              borderRadius: AppShape.card,
            ),
          ),
          const SizedBox(height: 12),
          Opacity(
            opacity: state.isPaused ? 0.6 : 1,
            child: Row(
              children: [
                Expanded(
                  child: MetricTile(
                    label: 'Tempo',
                    value: formatDuration(state.timerMs),
                    role: c.tempo,
                    block: true,
                    valueStyle: AppText.metricM,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: MetricTile(
                    label: 'Distancia',
                    value: formatDistance(state.distanceMeters, metric: metric),
                    role: c.dist,
                    block: true,
                    valueStyle: AppText.metricM,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Indicador de deslizar entre metricas e mapa.
class _PageDots extends StatelessWidget {
  final int page;
  const _PageDots({required this.page});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < 2; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == page ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == page ? c.text : c.line,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  final RecordingUiState state;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final Future<Object?> Function() onLap;
  final VoidCallback onStop;
  final VoidCallback onClose;

  const _Controls({
    required this.state,
    required this.onPause,
    required this.onResume,
    required this.onLap,
    required this.onStop,
    required this.onClose,
  });

  static const double _height = 72;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    // So a pausa manual troca os botoes por Retomar/Encerrar. Na pausa
    // automatica a retomada vem sozinha ao se mover: seguem Volta e Pausar.
    if (state.state == RecordingState.manuallyPaused) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BigActionButton(
            key: const Key('resume'),
            label: 'Retomar',
            icon: Icons.play_arrow_rounded,
            variant: BigActionVariant.role,
            role: c.dist,
            height: _height,
            onPressed: onResume,
          ),
          const SizedBox(height: 12),
          BigActionButton(
            key: const Key('stop'),
            label: 'Encerrar',
            icon: Icons.stop_rounded,
            variant: BigActionVariant.hold,
            height: _height,
            onPressed: onStop,
          ),
        ],
      );
    }
    // Sem gravacao e com erro (ex.: permissao negada): so da para sair.
    if (!state.isActive && state.error != null) {
      return BigActionButton(
        key: const Key('close'),
        label: 'Fechar',
        icon: Icons.close_rounded,
        variant: BigActionVariant.role,
        role: c.ciano,
        height: _height,
        onPressed: onClose,
      );
    }
    // Gravando ou em pausa automatica; ainda iniciando, nada para pausar.
    final running = state.isActive;
    return Row(
      children: [
        _LapButton(onPressed: running ? () => onLap() : null),
        const SizedBox(width: 12),
        Expanded(
          child: BigActionButton(
            key: const Key('pause'),
            label: 'Pausar',
            icon: Icons.pause_rounded,
            variant: BigActionVariant.role,
            role: c.tempo,
            height: _height,
            onPressed: running ? onPause : null,
          ),
        ),
      ],
    );
  }
}

/// Volta: botao neutro ao lado de Pausar, com icone e rotulo.
class _LapButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const _LapButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppShape.panel),
      side: BorderSide(color: c.line),
    );
    final fg = onPressed == null ? c.textMuted : c.text;
    return SizedBox(
      width: 84,
      height: _Controls._height,
      child: Material(
        color: c.surface2,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const Key('lap'),
          onTap: onPressed,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.flag_rounded, color: fg, size: 24),
              const SizedBox(height: 4),
              Text('Volta', style: AppText.label.copyWith(color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}
