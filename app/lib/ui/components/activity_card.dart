// Cartao de atividade do feed (relatorio 11, ActivityCard): chip do esporte com
// data, titulo, tres metricas, miniatura da rota na cor do esporte e as acoes
// Ver detalhe (tingido do esporte) e Compartilhar (contorno). A variante
// compacta (Historico) fica sem miniatura e sem os botoes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/format/activity_labels.dart';
import '../../core/format/measures.dart';
import '../../persistence/database.dart';
import '../../recording/domain/geo.dart';
import '../../recording/domain/recording_models.dart';
import '../route_preview.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'metric_tile.dart';
import 'sport_chip.dart';

class ActivityCard extends StatelessWidget {
  final Activity activity;
  final bool useMetric;

  /// Rota para a miniatura; null enquanto carrega.
  final List<GeoPoint>? route;

  final VoidCallback? onOpen;
  final VoidCallback? onShare;

  /// Sem miniatura e sem botoes; toque no cartao abre o detalhe.
  final bool compact;

  /// Modo Gentil (F04): esforco no lugar do pace ou da velocidade.
  final bool gentle;

  /// Acao extra no canto do cabecalho (menu do Historico).
  final Widget? trailing;

  const ActivityCard({
    super.key,
    required this.activity,
    required this.useMetric,
    this.route,
    this.onOpen,
    this.onShare,
    this.compact = false,
    this.gentle = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final sport = c.sport(activity.activityType);
    final type = activity.activityType;

    final (dist, distUnit) = splitMeasure(formatDistance(activity.distanceMeters, metric: useMetric));
    final seconds = activity.timerTimeMs / 1000.0;
    final (String, String?) middle;
    final String middleLabel;
    var middleRole = c.pace;
    if (gentle) {
      // Modo Gentil (F04): esforco percebido; "--" quando nao informado.
      middleLabel = 'Esforco';
      middleRole = c.extra;
      final rpe = activity.rpe;
      middle = (rpe != null && rpe >= 1 && rpe <= 10 ? '$rpe/10' : '--', null);
    } else if (type == ActivityType.ride) {
      middleLabel = 'Velocidade';
      middle = splitMeasure(formatSpeed(
        seconds > 0 ? activity.distanceMeters / seconds : 0,
        metric: useMetric,
      ));
    } else {
      middleLabel = 'Pace';
      middle = splitMeasure(formatPace(
        activity.distanceMeters > 0 ? seconds / activity.distanceMeters : null,
        metric: useMetric,
      ));
    }

    final metrics = Row(
      children: [
        Expanded(child: MetricTile(label: 'Distancia', value: dist, unit: distUnit, role: c.dist)),
        Expanded(child: MetricTile(label: middleLabel, value: middle.$1, unit: middle.$2, role: middleRole)),
        Expanded(
          child: MetricTile(label: 'Tempo', value: formatDuration(activity.timerTimeMs), role: c.tempo),
        ),
      ],
    );

    final body = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SportChip(type: type, trailing: formatDateTimeMs(activity.startTimestampMs)),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 10),
          Text(
            displayActivityTitle(
              activity.title,
              type,
              DateTime.fromMillisecondsSinceEpoch(activity.startTimestampMs),
            ),
            key: Key('title-${activity.guid}'),
            style: AppText.sectionTitle.copyWith(color: c.text),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          metrics,
          if (!compact) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppShape.tile),
              child: ColoredBox(
                color: c.map,
                child: RoutePreview(
                  key: const Key('card_route'),
                  route: route ?? const [],
                  color: sport.fill,
                  height: 140,
                  halo: true,
                  showStart: true,
                  emptyLabel: route == null ? '' : 'Sem rota gravada',
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    key: Key('open-${activity.guid}'),
                    style: FilledButton.styleFrom(
                      backgroundColor: sport.tint,
                      foregroundColor: sport.fg,
                      minimumSize: const Size(0, 44),
                    ),
                    onPressed: onOpen,
                    icon: const Icon(Icons.chevron_right_rounded),
                    label: const Text('Ver detalhe'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    key: Key('share-${activity.guid}'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.text,
                      side: BorderSide(color: c.line),
                      minimumSize: const Size(0, 44),
                    ),
                    onPressed: onShare,
                    icon: const Icon(Icons.ios_share_rounded),
                    label: const Text('Compartilhar'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppShape.card),
        side: BorderSide(color: c.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: compact ? InkWell(onTap: onOpen, child: body) : body,
    );
  }
}

/// ActivityCard que busca a propria rota (activityRouteProvider) e le a
/// unidade das configuracoes.
class RoutedActivityCard extends ConsumerWidget {
  final Activity activity;
  final VoidCallback? onOpen;
  final VoidCallback? onShare;
  final bool compact;
  final Widget? trailing;

  const RoutedActivityCard({
    super.key,
    required this.activity,
    this.onOpen,
    this.onShare,
    this.compact = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metric = ref.watch(settingsProvider.select((s) => s.useMetric));
    final gentle = ref.watch(settingsProvider.select((s) => s.gentleMode));
    final route = compact ? null : ref.watch(activityRouteProvider(activity.guid)).value;
    return ActivityCard(
      activity: activity,
      useMetric: metric,
      gentle: gentle,
      route: route,
      onOpen: onOpen,
      onShare: onShare,
      compact: compact,
      trailing: trailing,
    );
  }
}
