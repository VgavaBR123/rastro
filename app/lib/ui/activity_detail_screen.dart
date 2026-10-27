// Detalhe de uma atividade: rota, metricas, perfil de elevacao, splits e
// voltas.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../activity/activity_providers.dart';
import '../activity/elevation_profile.dart';
import '../activity/lap_summary.dart';
import '../app/providers.dart';
import '../core/format/activity_labels.dart';
import '../core/format/measures.dart';
import '../persistence/database.dart';
import '../recording/domain/splits.dart';
import '../recording/domain/splits_from_waypoints.dart';
import 'elevation_chart.dart';
import 'laps_section.dart';
import 'route_map.dart';

class ActivityDetailScreen extends ConsumerWidget {
  final Activity activity;
  const ActivityDetailScreen({super.key, required this.activity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeAsync = ref.watch(activityRouteProvider(activity.guid));
    final splitsAsync = ref.watch(activitySplitsProvider(activity.guid));
    final laps =
        ref.watch(activityLapsProvider(activity.guid)).value ??
        const <LapSummary>[];
    final elevationAsync = ref.watch(
      activityElevationProfileProvider(activity.guid),
    );
    final metric = ref.watch(settingsProvider).useMetric;
    final pace = activity.distanceMeters > 0
        ? (activity.timerTimeMs / 1000.0) / activity.distanceMeters
        : null;

    return Scaffold(
      appBar: AppBar(title: Text(activityTypeLabel(activity.activityType))),
      // Column (e nao ListView) para todas as secoes existirem na arvore: o
      // conteudo e curto e os testes encontram as secoes sem rolar.
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            routeAsync.when(
              loading: () => const SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) =>
                  SizedBox(height: 220, child: Center(child: Text('Erro: $e'))),
              data: (route) => RouteMap(route: route),
            ),
            const SizedBox(height: 16),
            Text(
              formatDateTimeMs(activity.startTimestampMs),
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _row(
              'Distancia',
              formatDistance(activity.distanceMeters, metric: metric),
            ),
            _row('Tempo', formatDuration(activity.timerTimeMs)),
            _row('Pace', formatPace(pace, metric: metric)),
            if (_calories(activity) case final kcal?)
              _row('Calorias', kcal, key: const Key('detailCalories')),
            if (_batteryUsage(activity) case final bateria?)
              _row('Bateria', bateria, key: const Key('detailBattery')),
            _row('Sincronizacao', syncStateLabel(activity.syncState)),
            const Divider(height: 32),
            Text(
              metric ? 'Splits por km' : 'Splits por milha',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            splitsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Erro: $e'),
              data: (splits) => _splits(splits, metric),
            ),
            // Secoes opcionais: somem quando nao ha dados (ou deu erro).
            ..._optional(
              elevationAsync.value,
              (ElevationProfile p) =>
                  ElevationSection(profile: p, metric: metric),
            ),
            ..._optional(
              laps.isEmpty ? null : laps,
              (List<LapSummary> l) => LapsSection(laps: l, metric: metric),
            ),
          ],
        ),
      ),
    );
  }

  /// Divisor + secao, ou nada quando [value] e null.
  static List<Widget> _optional<T>(T? value, Widget Function(T) build) =>
      value == null ? const [] : [const Divider(height: 32), build(value)];

  /// Calorias estimadas, arredondadas; null quando nao foram calculadas.
  static String? _calories(Activity a) {
    final c = a.calories;
    if (c == null || !c.isFinite) return null;
    return '${c.round()} kcal';
  }

  /// Consumo de bateria (inicio - fim) em pontos percentuais; null sem leitura
  /// nas duas pontas. Se o aparelho carregou durante a atividade, mostra 0%.
  static String? _batteryUsage(Activity a) {
    final start = a.startBatteryLevel;
    final end = a.endBatteryLevel;
    if (start == null || end == null) return null;
    final used = start - end;
    return '${used < 0 ? 0 : used}%';
  }

  /// Tabela de splits. O ultimo trecho pode ser parcial (nao fechou a marca);
  /// e exibido com o rotulo "parcial" em vez de omitido, porque numa atividade
  /// curta (menos de 1 km) ele seria a unica informacao de ritmo disponivel.
  Widget _splits(List<ActiveSplit> splits, bool metric) {
    if (splits.isEmpty) {
      return const Text(
        'Sem splits nesta atividade.',
        style: TextStyle(color: Colors.grey),
      );
    }
    return Column(children: [for (final s in splits) _splitRow(s, metric)]);
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
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: s.complete ? null : Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              formatDistance(distancia, metric: metric),
              style: const TextStyle(color: Colors.grey),
            ),
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

  Widget _row(String label, String value, {Key? key}) => Padding(
    key: key,
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}
