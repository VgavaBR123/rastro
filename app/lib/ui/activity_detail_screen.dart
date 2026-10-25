// Detalhe de uma atividade: rota + metricas.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../core/format/activity_labels.dart';
import '../core/format/measures.dart';
import '../persistence/database.dart';
import '../recording/domain/splits.dart';
import '../recording/domain/splits_from_waypoints.dart';
import 'route_preview.dart';

class ActivityDetailScreen extends ConsumerWidget {
  final Activity activity;
  const ActivityDetailScreen({super.key, required this.activity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeAsync = ref.watch(activityRouteProvider(activity.guid));
    final splitsAsync = ref.watch(activitySplitsProvider(activity.guid));
    final metric = ref.watch(settingsProvider).useMetric;
    final pace = activity.distanceMeters > 0
        ? (activity.timerTimeMs / 1000.0) / activity.distanceMeters
        : null;

    return Scaffold(
      appBar: AppBar(title: Text(activityTypeLabel(activity.activityType))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          routeAsync.when(
            loading: () => const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SizedBox(height: 220, child: Center(child: Text('Erro: $e'))),
            data: (route) => RoutePreview(route: route),
          ),
          const SizedBox(height: 16),
          Text(formatDateTimeMs(activity.startTimestampMs),
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          _row('Distancia', formatDistance(activity.distanceMeters, metric: metric)),
          _row('Tempo', formatDuration(activity.timerTimeMs)),
          _row('Pace', formatPace(pace, metric: metric)),
          _row('Sincronizacao', activity.syncState.name),
          const Divider(height: 32),
          Text(metric ? 'Splits por km' : 'Splits por milha',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          splitsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Erro: $e'),
            data: (splits) => _splits(splits, metric),
          ),
        ],
      ),
    );
  }

  /// Tabela de splits. O ultimo trecho pode ser parcial (nao fechou a marca);
  /// e exibido com o rotulo "parcial" em vez de omitido, porque numa atividade
  /// curta (menos de 1 km) ele seria a unica informacao de ritmo disponivel.
  Widget _splits(List<ActiveSplit> splits, bool metric) {
    if (splits.isEmpty) {
      return const Text('Sem splits nesta atividade.',
          style: TextStyle(color: Colors.grey));
    }
    return Column(
      children: [
        for (final s in splits) _splitRow(s, metric),
      ],
    );
  }

  Widget _splitRow(ActiveSplit s, bool metric) {
    final label = s.complete ? '${s.number}' : '${s.number} (parcial)';
    // Trecho fechado: mostra a marca atingida (1 km, 2 km, ...). Trecho
    // parcial: nao ha marca, entao mostra a distancia percorrida nele.
    final distancia = s.complete ? s.endDistanceMeters : s.distanceMeters;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(label,
                style: TextStyle(
                  fontSize: 16,
                  color: s.complete ? null : Colors.grey,
                )),
          ),
          Expanded(
            child: Text(formatDistance(distancia, metric: metric),
                style: const TextStyle(color: Colors.grey)),
          ),
          SizedBox(
            width: 72,
            child: Text(formatDuration(s.durationMs), textAlign: TextAlign.end),
          ),
          SizedBox(
            width: 96,
            child: Text(
              formatPace(splitPaceSecondsPerMeter(s), metric: metric),
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      );
}
