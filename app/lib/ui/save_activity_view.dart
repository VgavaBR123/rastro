// Tela Salvar (relatorio 11): voltar a gravacao, miniatura da rota, quatro
// metricas, titulo sugerido pelo horario, descricao, quem pode ver, Salvar
// (primaria) e Descartar (danger, com confirmacao). Mostrada pela
// RecordingScreen depois de segurar Encerrar; a gravacao fica pausada ate a
// escolha.
library;

import 'package:flutter/material.dart';

import '../core/format/activity_labels.dart';
import '../core/format/measures.dart';
import '../persistence/activity_visibility.dart';
import '../recording/domain/geo.dart';
import '../recording/domain/recording_models.dart';
import 'components/big_action_button.dart';
import 'components/metric_tile.dart';
import 'components/segmented_selector.dart';
import 'components/sport_chip.dart';
import 'route_map.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'theme/app_typography.dart';

export '../persistence/activity_visibility.dart';

/// O que o usuario preencheu na tela Salvar.
class ActivityDraft {
  final String title;
  final String description;
  final ActivityVisibility visibility;
  const ActivityDraft({
    required this.title,
    required this.description,
    required this.visibility,
  });
}

class SaveActivityView extends StatefulWidget {
  final ActivityType type;
  final List<GeoPoint> route;
  final double distanceMeters;
  final int timerMs;
  final double? avgPaceSecondsPerMeter;
  final double ascentMeters;
  final bool metric;
  final DateTime startedAt;

  /// Salvar ou descartar em andamento: botoes desligados.
  final bool busy;

  final VoidCallback onBack;
  final ValueChanged<ActivityDraft> onSave;

  /// Chamado so depois da confirmacao.
  final VoidCallback onDiscard;

  const SaveActivityView({
    super.key,
    required this.type,
    required this.route,
    required this.distanceMeters,
    required this.timerMs,
    required this.avgPaceSecondsPerMeter,
    required this.ascentMeters,
    required this.metric,
    required this.startedAt,
    required this.onBack,
    required this.onSave,
    required this.onDiscard,
    this.busy = false,
  });

  @override
  State<SaveActivityView> createState() => _SaveActivityViewState();
}

class _SaveActivityViewState extends State<SaveActivityView> with WidgetsBindingObserver {
  late final TextEditingController _title = TextEditingController(
    text: suggestedActivityTitle(widget.type, widget.startedAt),
  );
  final TextEditingController _description = TextEditingController();
  ActivityVisibility _visibility = ActivityVisibility.everyone;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  /// O teclado abriu ou fechou: reavalia se os botoes aparecem.
  @override
  void didChangeMetrics() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _save() {
    final title = _title.text.trim();
    widget.onSave(ActivityDraft(
      title: title.isEmpty ? suggestedActivityTitle(widget.type, widget.startedAt) : title,
      description: _description.text.trim(),
      visibility: _visibility,
    ));
  }

  Future<void> _confirmDiscard() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final c = AppColors.of(ctx);
        return AlertDialog(
          key: const Key('discard_dialog'),
          title: const Text('Descartar atividade?'),
          content: const Text('A gravacao sera apagada deste aparelho e nao da para desfazer.'),
          actions: [
            TextButton(
              key: const Key('discard_cancel'),
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              key: const Key('discard_confirm'),
              style: TextButton.styleFrom(foregroundColor: c.danger),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Descartar'),
            ),
          ],
        );
      },
    );
    if (ok == true) widget.onDiscard();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final sport = c.sport(widget.type);
    final m = widget.metric;
    final (dist, distUnit) = splitMeasure(formatDistance(widget.distanceMeters, metric: m));
    final (pace, paceUnit) = splitMeasure(formatPace(widget.avgPaceSecondsPerMeter, metric: m));
    final (ascent, ascentUnit) = splitMeasure(formatElevation(widget.ascentMeters, metric: m));
    final muted = AppText.label.copyWith(color: c.textMuted);
    // GRA-04: com o teclado aberto os botoes fixos somem e o formulario usa a
    // altura toda; voltam quando o teclado fecha (tocar fora ou rolar). Le o
    // View e nao o MediaQuery: o Scaffold de fora tira o teclado do MediaQuery
    // do corpo.
    final keyboardOpen = View.of(context).viewInsets.bottom > 0;

    return SafeArea(
      key: const Key('save_activity_view'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, AppShape.gutter, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('save_back'),
                style: TextButton.styleFrom(foregroundColor: c.ciano.fg, minimumSize: const Size(44, 44)),
                onPressed: widget.busy ? null : widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Voltar a gravacao'),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(AppShape.gutter, 4, AppShape.gutter, 16),
              children: [
                Text('Salvar atividade', style: AppText.screenTitle.copyWith(color: c.text)),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SportChip(
                    type: widget.type,
                    trailing: formatDateTimeMs(widget.startedAt.millisecondsSinceEpoch),
                  ),
                ),
                const SizedBox(height: 14),
                RouteMap(
                  key: const Key('save_route'),
                  route: widget.route,
                  height: 160,
                  color: sport.fill,
                  borderRadius: AppShape.panel,
                  emptyLabel: 'Sem trajeto gravado',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: MetricTile(
                        key: const Key('save_distance'),
                        label: 'Distancia',
                        value: dist,
                        unit: distUnit,
                        role: c.dist,
                        block: true,
                        valueStyle: AppText.metricM,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: MetricTile(
                        key: const Key('save_duration'),
                        label: 'Tempo',
                        value: formatDuration(widget.timerMs),
                        role: c.tempo,
                        block: true,
                        valueStyle: AppText.metricM,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: MetricTile(
                        key: const Key('save_pace'),
                        label: 'Pace medio',
                        value: pace,
                        unit: paceUnit,
                        role: c.pace,
                        block: true,
                        valueStyle: AppText.metricM,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: MetricTile(
                        key: const Key('save_elevation'),
                        label: 'Subida',
                        value: ascent,
                        unit: ascentUnit,
                        role: c.subida,
                        block: true,
                        valueStyle: AppText.metricM,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Titulo', style: muted),
                const SizedBox(height: 6),
                TextField(
                  key: const Key('save_title'),
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  style: AppText.bodyStrong.copyWith(color: c.text),
                ),
                const SizedBox(height: 14),
                Text('Descricao', style: muted),
                const SizedBox(height: 6),
                TextField(
                  key: const Key('save_description'),
                  controller: _description,
                  minLines: 2,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  style: AppText.body.copyWith(color: c.text),
                  decoration: const InputDecoration(hintText: 'Como foi o treino?'),
                ),
                const SizedBox(height: 14),
                Text('Quem pode ver', style: muted),
                const SizedBox(height: 6),
                SegmentedSelector<ActivityVisibility>(
                  key: const Key('save_visibility'),
                  options: [
                    SegmentOption(
                      value: ActivityVisibility.onlyMe,
                      label: 'So eu',
                      role: c.subida,
                      icon: Icons.lock_rounded,
                      key: const Key('visibility_only_me'),
                    ),
                    SegmentOption(
                      value: ActivityVisibility.followers,
                      label: 'Seguidores',
                      role: c.pace,
                      icon: Icons.group_rounded,
                      key: const Key('visibility_followers'),
                    ),
                    SegmentOption(
                      value: ActivityVisibility.everyone,
                      label: 'Todos',
                      role: c.ciano,
                      icon: Icons.public_rounded,
                      key: const Key('visibility_everyone'),
                    ),
                  ],
                  selected: _visibility,
                  onChanged: widget.busy ? null : (v) => setState(() => _visibility = v),
                ),
              ],
            ),
          ),
          if (!keyboardOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppShape.gutter, 8, AppShape.gutter, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BigActionButton(
                    key: const Key('save_activity'),
                    label: 'Salvar',
                    icon: Icons.check_rounded,
                    onPressed: widget.busy ? null : _save,
                  ),
                  const SizedBox(height: 12),
                  BigActionButton(
                    key: const Key('discard_activity'),
                    label: 'Descartar',
                    icon: Icons.delete_outline_rounded,
                    variant: BigActionVariant.danger,
                    height: 56,
                    onPressed: widget.busy ? null : _confirmDiscard,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
