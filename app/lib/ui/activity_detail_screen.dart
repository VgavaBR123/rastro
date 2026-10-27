// Detalhe de uma atividade (relatorio 11, tela Detalhe): mapa no topo com
// botoes flutuantes, chip do esporte, titulo, grade 3 x 2 de metricas,
// splits com SplitBar, perfil de elevacao e voltas.
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
import '../recording/domain/geo.dart';
import '../recording/domain/recording_models.dart';
import 'components/floating_map_button.dart';
import 'components/metric_tile.dart';
import 'components/sport_chip.dart';
import 'elevation_chart.dart';
import 'laps_section.dart';
import 'route_map.dart';
import 'section_card.dart';
import 'share_activity.dart';
import 'splits_section.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'theme/app_typography.dart';

/// Altura do mapa no topo do detalhe.
const double kDetailMapHeight = 280;

/// Cor do chip de sincronizacao por estado.
RoleColors syncRole(AppColors c, SyncState s) => switch (s) {
  SyncState.synced => c.dist,
  SyncState.pending => c.extra,
  SyncState.uploading => c.pace,
  SyncState.recording || SyncState.failed => c.tempo,
};

class ActivityDetailScreen extends ConsumerWidget {
  final Activity activity;
  const ActivityDetailScreen({super.key, required this.activity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final routeAsync = ref.watch(activityRouteProvider(activity.guid));
    final splitsAsync = ref.watch(activitySplitsProvider(activity.guid));
    final laps =
        ref.watch(activityLapsProvider(activity.guid)).value ??
        const <LapSummary>[];
    final profile = ref
        .watch(activityElevationProfileProvider(activity.guid))
        .value;
    final metric = ref.watch(settingsProvider).useMetric;
    final muted = AppText.body.copyWith(color: c.textMuted);

    return Scaffold(
      // Column (e nao ListView) para todas as secoes existirem na arvore: o
      // conteudo e curto e os testes encontram as secoes sem rolar.
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _mapHeader(context, ref, c, routeAsync),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppShape.gutter,
                16,
                AppShape.gutter,
                24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SportChip(
                      type: activity.activityType,
                      trailing: formatDateTimeMs(activity.startTimestampMs),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    displayActivityTitle(
                      activity.title,
                      activity.activityType,
                      DateTime.fromMillisecondsSinceEpoch(activity.startTimestampMs),
                    ),
                    key: const Key('detailTitle'),
                    style: AppText.screenTitle.copyWith(color: c.text),
                  ),
                  if (activity.description?.trim().isNotEmpty ?? false) ...[
                    const SizedBox(height: 6),
                    Text(
                      activity.description!.trim(),
                      key: const Key('detailDescription'),
                      style: AppText.body.copyWith(color: c.textMuted),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SportChip.custom(
                      key: const Key('detailSync'),
                      label: syncStateLabel(activity.syncState),
                      role: syncRole(c, activity.syncState),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _metricGrid(_tiles(c, profile, metric)),
                  const SizedBox(height: 20),
                  _card(
                    splitsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => Text('Erro: $e', style: muted),
                      data: (splits) =>
                          SplitsSection(splits: splits, metric: metric),
                    ),
                  ),
                  // Secoes opcionais: somem quando nao ha dados (ou deu erro).
                  if (profile != null)
                    _card(ElevationSection(profile: profile, metric: metric)),
                  if (laps.isNotEmpty)
                    _card(LapsSection(laps: laps, metric: metric)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mapa da rota com Voltar e Compartilhar flutuando por cima.
  Widget _mapHeader(
    BuildContext context,
    WidgetRef ref,
    AppColors c,
    AsyncValue<List<GeoPoint>> routeAsync,
  ) {
    final muted = AppText.body.copyWith(color: c.textMuted);
    return SizedBox(
      height: kDetailMapHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: c.map,
            child: switch (routeAsync) {
              AsyncData(:final value) => RouteMap(
                route: value,
                height: null,
                borderRadius: 0,
                color: c.sport(activity.activityType).fill,
              ),
              AsyncError(:final error) => Center(
                child: Text('Erro: $error', style: muted),
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
          Positioned(
            left: AppShape.gutter,
            right: AppShape.gutter,
            top: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    FloatingMapButton(
                      key: const Key('detailBack'),
                      icon: Icons.arrow_back,
                      tooltip: 'Voltar',
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const Spacer(),
                    FloatingMapButton(
                      key: const Key('detailShare'),
                      icon: Icons.ios_share,
                      tooltip: 'Compartilhar',
                      label: 'Compartilhar',
                      onPressed: () => shareActivity(context, activity),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Metricas da grade, na ordem: distancia, tempo, pace (ou velocidade no
  /// pedal), subida, calorias e bateria. As duas ultimas somem sem leitura.
  List<_Tile> _tiles(AppColors c, ElevationProfile? profile, bool metric) {
    final seconds = activity.timerTimeMs / 1000.0;
    final ride = activity.activityType == ActivityType.ride;
    final pace = activity.distanceMeters > 0
        ? seconds / activity.distanceMeters
        : null;
    final speed = seconds > 0 ? activity.distanceMeters / seconds : 0.0;
    return [
      _Tile(
        'Distancia',
        formatDistance(activity.distanceMeters, metric: metric),
        c.dist,
        const Key('detailDistance'),
      ),
      _Tile(
        'Tempo',
        formatDuration(activity.timerTimeMs),
        c.tempo,
        const Key('detailTime'),
      ),
      ride
          ? _Tile(
              'Velocidade',
              formatSpeed(speed, metric: metric),
              c.pace,
              const Key('detailPace'),
            )
          : _Tile(
              'Pace',
              formatPace(pace, metric: metric),
              c.pace,
              const Key('detailPace'),
            ),
      _Tile(
        'Subida',
        formatElevation(profile?.gainMeters ?? double.nan, metric: metric),
        c.subida,
        const Key('detailAscent'),
      ),
      if (_calories(activity) case final kcal?)
        _Tile('Calorias', kcal, c.extra, const Key('detailCalories')),
      if (_batteryUsage(activity) case final bateria?)
        _Tile('Bateria', bateria, c.ciano, const Key('detailBattery')),
    ];
  }

  /// Grade de 3 colunas; a ultima linha e completada com espaco vazio.
  static Widget _metricGrid(List<_Tile> tiles) {
    const cols = 3;
    const gap = 8.0;
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += cols) {
      final cells = <Widget>[];
      for (var j = i; j < i + cols; j++) {
        if (j > i) cells.add(const SizedBox(width: gap));
        cells.add(
          Expanded(child: j < tiles.length ? tiles[j] : const SizedBox()),
        );
      }
      if (i > 0) rows.add(const SizedBox(height: gap));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: cells,
          ),
        ),
      );
    }
    return Column(key: const Key('detailMetrics'), children: rows);
  }

  /// Secao em cartao surface (raio 22), com o espacamento padrao abaixo.
  static Widget _card(Widget child) =>
      SectionCard(padding: const EdgeInsets.all(16), child: child);

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
}

/// Bloco tingido da grade. O valor encolhe (sem cortar) quando nao cabe na
/// coluna, por isso o fundo e montado aqui e nao no MetricTile.
class _Tile extends StatelessWidget {
  final String label;
  final String formatted;
  final RoleColors role;

  const _Tile(this.label, this.formatted, this.role, Key key) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final (value, unit) = splitMeasure(formatted);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: role.tint,
        borderRadius: BorderRadius.circular(AppShape.tile),
      ),
      alignment: Alignment.centerLeft,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: MetricTile(
          label: label,
          value: value,
          unit: unit,
          role: role,
          valueStyle: AppText.metricM,
        ),
      ),
    );
  }
}
