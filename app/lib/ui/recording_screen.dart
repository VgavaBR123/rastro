// Tela de gravacao (relatorio 11, Gravando): sem navegacao, chip de estado,
// tempo e distancia grandes, pace atual, pace medio e subida em blocos, split e
// volta correntes, e o mapa a um deslize. Pausar/Retomar/Volta pela tela ou
// pela notificacao. Encerrar exige segurar e abre a tela Salvar; encerrar pela
// notificacao salva direto e fecha esta tela.
//
// Gravacao blindada (F01): faixa de aviso quando o GPS fica mudo e quando uma
// lacuna e registrada; cadeado que bloqueia os toques (desbloquear exige
// segurar), para o braco ou o bolso nao pausarem a gravacao sem querer.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../closing/closing_service.dart';
import '../core/format/measures.dart';
import '../narrator/narrator_providers.dart';
import '../persistence/recording_repository.dart';
import '../privacy/privacy_providers.dart';
import '../recording/domain/gap_monitor.dart';
import '../recording/domain/geo.dart';
import '../recording/domain/recording_health.dart';
import '../recording/domain/recording_models.dart';
import '../recording/presentation/recording_ui_state.dart';
import '../sync/background/background_sync_provider.dart';
import 'closing/closing_view.dart';
import 'components/big_action_button.dart';
import 'components/floating_map_button.dart';
import 'components/metric_tile.dart';
import 'components/notice_banner.dart';
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

  /// Rotina previsivel (F02): dica gentil no Salvar.
  bool _routineWarning = false;

  /// Salvar ou descartar em andamento: o fim da gravacao vem desta tela, que
  /// fecha sozinha depois.
  bool _finishing = false;

  bool _closed = false;

  /// Fechamento gentil (F04): depois de salvar, as frases e o que foi
  /// escolhido no Salvar. Null = ainda nao salvou.
  ({List<String> phrases, ActivityDraft draft, int timerMs})? _closing;

  /// Bloqueio contra toques ligado.
  bool _locked = false;

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
      // Narrador por voz (F03): passa a ouvir a gravacao antes dela comecar.
      ref.read(recordingNarrationProvider);
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
    if (s.isRecording) {
      // Pausa tecnica para abrir Salvar: o Narrador nao a anuncia.
      ref.read(recordingNarrationProvider).silenceNextPause();
      ref.read(recordingControllerProvider.notifier).pause();
    }
    setState(() {
      _saving = true;
      _locked = false;
      _page = 0;
      // Inicio do cabecalho: "agora menos o tempo" erraria com pausas.
      final startMs = ref.read(recordingControllerProvider.notifier).startTimestampMs;
      _startedAt = startMs != null
          ? DateTime.fromMillisecondsSinceEpoch(startMs)
          : DateTime.now().subtract(Duration(milliseconds: s.elapsedMs));
    });
    unawaited(_checkRoutine());
  }

  /// Confere a rotina (F02) com o inicio desta gravacao e as anteriores. A
  /// dica e opcional: se a consulta falhar, o Salvar segue sem ela.
  Future<void> _checkRoutine() async {
    final ctrl = ref.read(recordingControllerProvider.notifier);
    final route = ctrl.route;
    bool warn;
    try {
      warn = await routineWarningWithNew(
        ref.read(privacyRepositoryProvider),
        start: route.isEmpty ? null : route.first,
        startedAt: _startedAt ?? DateTime.now(),
        exceptGuid: ctrl.activityGuid,
      );
    } catch (e) {
      debugPrint('Aviso de rotina indisponivel: $e');
      warn = false;
    }
    if (mounted && warn != _routineWarning) setState(() => _routineWarning = warn);
  }

  Future<void> _save(ActivityDraft draft) async {
    setState(() => _finishing = true);
    final ctrl = ref.read(recordingControllerProvider.notifier);
    final repo = ref.read(recordingRepositoryProvider);
    // O guid fica no controller depois do fim; so grava os detalhes se havia
    // gravacao.
    final wasActive = ref.read(recordingControllerProvider).isActive;
    final guid = ctrl.activityGuid;
    final timerMs = ref.read(recordingControllerProvider).timerMs;
    // Detalhes antes do stop: o stop poe a atividade na fila de upload, e um
    // sync ja em andamento subiria sem RPE, humor e corte das pontas (o
    // servidor e idempotente por guid e nao atualiza depois). Se gravar os
    // detalhes falhar, a gravacao termina mesmo assim.
    try {
      if (wasActive && guid != null) {
        await repo.saveDetails(
          guid,
          title: draft.title,
          description: draft.description,
          visibility: draft.visibility,
          hideEdgesMeters: draft.hideEdgesMeters,
          rpe: draft.rpe,
          mood: draft.mood,
        );
      }
    } finally {
      await ctrl.stop();
    }
    if (!mounted) return;
    // A atividade ja esta salva: o upload nao espera o Concluir.
    ref.read(backgroundSyncSchedulerProvider).scheduleSoon();
    ref.invalidate(recentActivitiesProvider);
    ref.invalidate(pendingCountProvider);
    final phrases = guid == null ? const <String>[] : await _phrasesFor(guid);
    if (!mounted) return;
    setState(() => _closing = (phrases: phrases, draft: draft, timerMs: timerMs));
  }

  /// Frases do fechamento (F04). Sao um extra: se a consulta falhar, o
  /// fechamento abre so com a confirmacao.
  Future<List<String>> _phrasesFor(String guid) async {
    final settings = ref.read(settingsProvider);
    try {
      return await ref
          .read(closingServiceProvider)
          .phrasesFor(guid, gentle: settings.gentleMode, metric: settings.useMetric);
    } catch (e) {
      debugPrint('Frases do fechamento indisponiveis: $e');
      return const [];
    }
  }

  Future<void> _discard() async {
    setState(() => _finishing = true);
    final ctrl = ref.read(recordingControllerProvider.notifier);
    final repo = ref.read(recordingRepositoryProvider);
    // So apaga se havia gravacao: o guid fica no controller depois do fim.
    final wasActive = ref.read(recordingControllerProvider).isActive;
    final guid = ctrl.activityGuid;
    // Atividade apagada: o Narrador nao fala o resumo do fim.
    ref.read(recordingNarrationProvider).suppressNextFinish();
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
    final gentle = ref.watch(settingsProvider).gentleMode;
    final closing = _closing;

    final Widget body;
    if (closing != null) {
      body = ClosingView(
        type: _type,
        phrases: closing.phrases,
        rpe: closing.draft.rpe,
        mood: closing.draft.mood,
        timerMs: closing.timerMs,
        onDone: () => _close(sync: false),
      );
    } else if (_saving) {
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
        routineWarning: _routineWarning,
        gentle: gentle,
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
        gentle: gentle,
        pages: _pages,
        page: _page,
        onPageChanged: (i) => setState(() => _page = i),
        onTogglePage: _togglePage,
        onPause: ctrl.pause,
        onResume: ctrl.resume,
        onLap: ctrl.lap,
        onStop: _openSave,
        onClose: () => Navigator.of(context).pop(),
        locked: _locked && s.isActive,
        onLock: () => setState(() => _locked = true),
        onUnlock: () => setState(() => _locked = false),
        onDismissGap: ctrl.dismissGapNotice,
      );
    }

    // Sem navegacao durante a gravacao: o voltar do sistema nao sai da tela
    // (na tela Salvar, volta para a gravacao).
    return PopScope(
      canPop: !s.isActive && !_saving && closing == null,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // No fechamento, voltar e o mesmo que Concluir.
        if (closing != null) {
          if (!_closed) _close(sync: false);
          return;
        }
        if (_saving && !_finishing) setState(() => _saving = false);
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

  /// Modo Gentil (F04): sem pace na tela.
  final bool gentle;
  final PageController pages;
  final int page;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onTogglePage;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final Future<Object?> Function() onLap;
  final VoidCallback onStop;
  final VoidCallback onClose;
  final bool locked;
  final VoidCallback onLock;
  final VoidCallback onUnlock;
  final VoidCallback onDismissGap;

  const _RecordingBody({
    required this.type,
    required this.state,
    required this.route,
    required this.metric,
    required this.gentle,
    required this.pages,
    required this.page,
    required this.onPageChanged,
    required this.onTogglePage,
    required this.onPause,
    required this.onResume,
    required this.onLap,
    required this.onStop,
    required this.onClose,
    required this.locked,
    required this.onLock,
    required this.onUnlock,
    required this.onDismissGap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final s = state;
    final gap = s.gapNotice;
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
                  onPressed: locked ? null : onTogglePage,
                ),
                if (s.isActive) ...[
                  const SizedBox(width: 8),
                  _LockButton(locked: locked, onPressed: locked ? null : onLock),
                ],
              ],
            ),
          ),
          if (s.gpsSignalLost)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppShape.gutter, 0, AppShape.gutter, 8),
              child: NoticeBanner(
                key: const Key('gps_lost_banner'),
                icon: Icons.gps_off_rounded,
                title: 'Sem sinal de GPS',
                message: 'A gravacao continua. Se o sinal demorar, o trecho fica registrado como lacuna.',
                accent: c.danger,
              ),
            ),
          if (gap != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppShape.gutter, 0, AppShape.gutter, 8),
              child: AbsorbPointer(
                absorbing: locked,
                child: NoticeBanner(
                  key: const Key('gap_banner'),
                  icon: gap.reason == GapReason.noGpsSignal
                      ? Icons.gps_fixed_rounded
                      : Icons.restore_rounded,
                  title: gap.reason == GapReason.noGpsSignal
                      ? 'Sinal de GPS de volta'
                      : 'Gravacao retomada',
                  message: 'Lacuna de ${formatGapDuration(gap.durationMs)} '
                      '(${gapReasonLabel(gap.reason)}). O trecho ficou '
                      'registrado no relatorio da atividade.',
                  accent: c.extra.fill,
                  background: c.extra.tint,
                  actionLabel: 'Entendi',
                  actionKey: const Key('gap_banner_dismiss'),
                  onAction: onDismissGap,
                ),
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
            child: AbsorbPointer(
              absorbing: locked,
              child: PageView(
                controller: pages,
                onPageChanged: onPageChanged,
                children: [
                  _MetricsPage(state: s, metric: metric, gentle: gentle),
                  _MapPage(type: type, state: s, route: route, metric: metric),
                ],
              ),
            ),
          ),
          _PageDots(page: page),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppShape.gutter, 12, AppShape.gutter, 16),
            child: locked
                ? BigActionButton(
                    key: const Key('recording_unlock'),
                    label: 'Desbloquear',
                    icon: Icons.lock_open_rounded,
                    variant: BigActionVariant.hold,
                    holdHint: 'Segure para desbloquear',
                    height: _Controls._height,
                    onPressed: onUnlock,
                  )
                : _Controls(
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

  /// Modo Gentil (F04): sem o pace medio e, no split, o tempo no lugar do
  /// pace.
  final bool gentle;
  const _MetricsPage({required this.state, required this.metric, required this.gentle});

  /// Tempo do split corrente (pace x distancia); "--:--" sem pace.
  static String _splitTime(LiveSplit split) {
    final p = split.paceSecondsPerMeter;
    if (p == null || !p.isFinite || split.distanceMeters <= 0) return '--:--';
    return formatDuration((p * split.distanceMeters * 1000).round());
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final s = state;
    final split = s.split(metric: metric);
    final (avgPace, avgPaceUnit) = splitMeasure(formatPace(s.avgPaceSecondsPerMeter, metric: metric));
    final (dist, distUnit) = splitMeasure(formatDistance(s.distanceMeters, metric: metric));
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppShape.gutter),
      child: AnimatedOpacity(
        // Pausado: metricas a 60% (relatorio 11).
        opacity: s.isPaused ? 0.6 : 1,
        duration: const Duration(milliseconds: 200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tempo, pace medio e distancia empilhados, todos grandes e com o
            // mesmo peso, separados por linhas.
            _BigMetric(
              key: const Key('duration'),
              label: 'Tempo',
              value: formatDuration(s.timerMs),
              role: c.tempo,
            ),
            _MetricDivider(color: c.line),
            if (!gentle) ...[
              _BigMetric(
                key: const Key('pace'),
                label: 'Pace medio',
                value: avgPace,
                unit: avgPaceUnit,
                role: c.pace,
              ),
              _MetricDivider(color: c.line),
            ],
            _BigMetric(
              key: const Key('distance'),
              label: 'Distancia',
              value: dist,
              unit: distUnit,
              role: c.dist,
            ),
            const SizedBox(height: 20),
            _LiveRow(
              key: const Key('current_split'),
              label: '${metric ? 'Km' : 'Milha'} ${split.number}',
              distance: formatDistance(split.distanceMeters, metric: metric),
              detail: gentle
                  ? _splitTime(split)
                  : formatPace(split.paceSecondsPerMeter, metric: metric),
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

/// Metrica grande em metricXL, com a unidade menor ao lado. O valor com a
/// unidade e um Text unico (o teste de ponta a ponta le o ultimo Text debaixo
/// da Key).
class _BigMetric extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final RoleColors role;
  const _BigMetric({
    required this.label,
    required this.value,
    required this.role,
    this.unit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final style = AppText.metricXL.copyWith(color: role.fg);
    return Column(
      children: [
        Text(label, style: AppText.label.copyWith(color: c.textMuted)),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text.rich(
            TextSpan(
              text: value,
              children: [
                if (unit != null)
                  TextSpan(
                    text: ' $unit',
                    style: AppText.metricM.copyWith(color: c.textMuted),
                  ),
              ],
            ),
            maxLines: 1,
            style: style,
          ),
        ),
      ],
    );
  }
}

class _MetricDivider extends StatelessWidget {
  final Color color;
  const _MetricDivider({required this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Divider(height: 1, thickness: 1, color: color),
      );
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

/// Cadeado: bloqueia os toques da tela de gravacao (64 dp, cor extra do
/// bloqueio de tela).
class _LockButton extends StatelessWidget {
  final bool locked;
  final VoidCallback? onPressed;
  const _LockButton({required this.locked, required this.onPressed});

  static const double _size = 64;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppShape.panel),
      side: BorderSide(color: locked ? c.extra.fill : c.line),
    );
    return Semantics(
      button: true,
      label: locked ? 'Tela bloqueada' : 'Bloquear a tela',
      excludeSemantics: true,
      onTap: onPressed,
      child: Tooltip(
        message: locked ? 'Tela bloqueada' : 'Bloquear a tela',
        child: SizedBox(
          width: _size,
          height: _size,
          child: Material(
            color: locked ? c.extra.tint : c.surface2,
            shape: shape,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: const Key('recording_lock'),
              onTap: onPressed,
              child: Icon(
                locked ? Icons.lock_rounded : Icons.lock_open_rounded,
                color: locked ? c.extra.fg : c.text,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
