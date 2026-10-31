// Detalhe de uma atividade (relatorio 11, tela Detalhe): mapa no topo com
// botoes flutuantes, chip do esporte, titulo, grade 3 x 2 de metricas,
// splits com SplitBar, perfil de elevacao, voltas e saude da gravacao (F01).
// Fechamento gentil (F04): esforco, carga e humor; Modo Gentil sem pace.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../activity/activity_providers.dart';
import '../activity/elevation_profile.dart';
import '../activity/lap_summary.dart';
import '../app/providers.dart';
import '../closing/domain/effort.dart';
import '../core/format/activity_labels.dart';
import '../core/format/measures.dart';
import '../persistence/database.dart';
import '../recording/domain/geo.dart';
import '../recording/domain/recording_models.dart';
import 'closing/closing_summary_section.dart';
import 'components/floating_map_button.dart';
import 'components/metric_tile.dart';
import 'components/sport_chip.dart';
import 'elevation_chart.dart';
import 'laps_section.dart';
import 'recording_health_section.dart';
import 'route_map.dart';
import 'section_card.dart';
import 'share_activity.dart';
import 'splits_section.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'theme/app_typography.dart';
import 'your_data/export_activity_gpx.dart';
import '../your_data/domain/import_models.dart';

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
    final health = ref.watch(activityHealthProvider(activity.guid)).value;
    final metric = ref.watch(settingsProvider).useMetric;
    final gentle = ref.watch(settingsProvider).gentleMode;
    final mood = Mood.fromDb(activity.mood);
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SportChip.custom(
                        key: const Key('detailSync'),
                        label: syncStateLabel(activity.syncState),
                        role: syncRole(c, activity.syncState),
                      ),
                      // Seus dados (F07): de onde veio a importada.
                      if (ImportFormat.fromDb(activity.importSource) case final f?)
                        SportChip.custom(
                          key: const Key('detailImportSource'),
                          label: 'Importada de ${f.label}',
                          role: c.ciano,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _metricGrid(_tiles(c, profile, metric, gentle: gentle)),
                  if (ClosingSummarySection.hasData(activity.rpe, mood)) ...[
                    const SizedBox(height: 8),
                    ClosingSummarySection(
                      rpe: activity.rpe,
                      mood: mood,
                      timerMs: activity.timerTimeMs,
                    ),
                  ],
                  const SizedBox(height: 20),
                  _card(
                    splitsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => Text('Erro: $e', style: muted),
                      data: (splits) => SplitsSection(
                        splits: splits,
                        metric: metric,
                        gentle: gentle,
                      ),
                    ),
                  ),
                  // Secoes opcionais: somem quando nao ha dados (ou deu erro).
                  if (profile != null)
                    _card(ElevationSection(profile: profile, metric: metric)),
                  if (laps.isNotEmpty)
                    _card(LapsSection(laps: laps, metric: metric, gentle: gentle)),
                  if (health != null)
                    _card(
                      RecordingHealthSection(health: health, metric: metric),
                    ),
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
                    const SizedBox(width: 8),
                    Builder(
                      builder: (buttonContext) => FloatingMapButton(
                        key: const Key('detailMenu'),
                        icon: Icons.more_horiz_rounded,
                        tooltip: 'Mais acoes',
                        onPressed: () => _openMenu(buttonContext, ref),
                      ),
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

  /// Menu "Mais acoes" ancorado no botao: Exportar GPX (F07).
  Future<void> _openMenu(BuildContext buttonContext, WidgetRef ref) async {
    final box = buttonContext.findRenderObject()! as RenderBox;
    final overlay =
        Navigator.of(buttonContext).overlay!.context.findRenderObject()! as RenderBox;
    final topLeft = box.localToGlobal(Offset(0, box.size.height), ancestor: overlay);
    final bottomRight = box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay);
    final choice = await showMenu<String>(
      context: buttonContext,
      position: RelativeRect.fromRect(Rect.fromPoints(topLeft, bottomRight), Offset.zero & overlay.size),
      items: const [
        PopupMenuItem(
          key: Key('detailExportGpx'),
          value: 'gpx',
          child: Text('Exportar GPX'),
        ),
      ],
    );
    if (choice == 'gpx' && buttonContext.mounted) {
      await exportActivityGpx(buttonContext, ref, activity);
    }
  }

  /// Metricas da grade, na ordem: distancia, tempo, pace (ou velocidade no
  /// pedal), subida, calorias e bateria. As duas ultimas somem sem leitura.
  /// Modo Gentil (F04): sem o bloco de pace/velocidade.
  List<_Tile> _tiles(
    AppColors c,
    ElevationProfile? profile,
    bool metric, {
    bool gentle = false,
  }) {
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
      if (!gentle && ride)
        _Tile(
          'Velocidade',
          formatSpeed(speed, metric: metric),
          c.pace,
          const Key('detailPace'),
        )
      else if (!gentle)
        _Tile(
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
