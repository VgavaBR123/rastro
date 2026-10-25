// Detalhe de uma atividade: rota + metricas.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../core/format/activity_labels.dart';
import '../core/format/measures.dart';
import '../persistence/database.dart';
import 'route_preview.dart';

class ActivityDetailScreen extends ConsumerWidget {
  final Activity activity;
  const ActivityDetailScreen({super.key, required this.activity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeAsync = ref.watch(activityRouteProvider(activity.guid));
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
