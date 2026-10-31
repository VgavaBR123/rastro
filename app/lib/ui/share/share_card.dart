// Imagem de compartilhamento de uma atividade: rota na cor do esporte, titulo,
// esporte, data e metricas, no formato 9:16 (Stories). Dois estilos: Cartao
// (fundo do tema) e Transparente (so rota e texto, para colocar sobre uma
// foto). Sempre com os tokens do tema escuro, para a imagem sair igual em
// qualquer tema do app.
library;

import 'package:flutter/material.dart';

import '../../core/format/activity_labels.dart';
import '../../core/format/measures.dart';
import '../../recording/domain/geo.dart';
import '../../recording/domain/recording_models.dart';
import '../components/sport_chip.dart';
import '../record_setup_screen.dart' show sportIcon;
import '../route_preview.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// Nome que assina a imagem.
const String kShareBrand = 'Rastro';

/// Tamanho logico do cartao; capturado a [kShareCardPixelRatio] vira
/// 1080 x 1920.
const Size kShareCardSize = Size(360, 640);
const double kShareCardPixelRatio = 3;

enum ShareCardStyle {
  card('Cartão', Icons.crop_portrait_rounded),
  transparent('Transparente', Icons.layers_clear_rounded);

  final String label;
  final IconData icon;
  const ShareCardStyle(this.label, this.icon);
}

/// O que o cartao mostra.
class ShareCardData {
  final String title;
  final ActivityType type;
  final int startTimestampMs;
  final double distanceMeters;
  final int timerMs;

  /// Ganho de elevacao; null sem leitura de altitude.
  final double? gainMeters;
  final List<GeoPoint> route;
  final bool metric;

  const ShareCardData({
    required this.title,
    required this.type,
    required this.startTimestampMs,
    required this.distanceMeters,
    required this.timerMs,
    required this.route,
    required this.metric,
    this.gainMeters,
  });
}

/// Metrica do cartao: rotulo, valor e funcao de cor.
typedef ShareMetric = ({String label, String value, RoleColors role});

/// Metricas na ordem do cartao: distancia, pace (velocidade no pedal), tempo
/// e, com leitura de altitude, subida. Funcao pura.
List<ShareMetric> shareCardMetrics(ShareCardData d, AppColors c) {
  final seconds = d.timerMs / 1000.0;
  final ride = d.type == ActivityType.ride;
  final gain = d.gainMeters;
  return [
    (
      label: 'Distância',
      value: formatDistance(d.distanceMeters, metric: d.metric),
      role: c.dist,
    ),
    ride
        ? (
            label: 'Velocidade',
            value: formatSpeed(seconds > 0 ? d.distanceMeters / seconds : 0, metric: d.metric),
            role: c.pace,
          )
        : (
            label: 'Pace',
            value: formatPace(
              d.distanceMeters > 0 ? seconds / d.distanceMeters : null,
              metric: d.metric,
            ),
            role: c.pace,
          ),
    (label: 'Tempo', value: formatDuration(d.timerMs), role: c.tempo),
    if (gain != null && gain.isFinite)
      (label: 'Subida', value: formatElevation(gain, metric: d.metric), role: c.subida),
  ];
}

class ShareCard extends StatelessWidget {
  final ShareCardData data;
  final ShareCardStyle style;

  const ShareCard({super.key, required this.data, required this.style});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.dark,
      child: Builder(builder: (context) => _content(context, AppColors.of(context))),
    );
  }

  Widget _content(BuildContext context, AppColors c) {
    final transparent = style == ShareCardStyle.transparent;
    // Sobre foto, uma sombra suave do fundo segura a leitura do texto.
    final shadows = transparent
        ? [Shadow(color: c.bg.withValues(alpha: 0.6), blurRadius: 8)]
        : null;
    final role = c.sport(data.type);
    final metrics = shareCardMetrics(data, c);

    return SizedBox.fromSize(
      size: kShareCardSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: transparent ? null : c.bg,
          gradient: transparent
              ? null
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [c.surface, c.bg],
                ),
          // Sem a linha, o fim do degrade some no fundo e o cartao parece
          // cortado (INI-11).
          border: transparent ? null : Border.all(color: c.line),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SportChip(type: data.type),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      formatDateTimeMs(data.startTimestampMs),
                      key: const Key('share_card_date'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.label.copyWith(color: c.textMuted, shadows: shadows),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                data.title,
                key: const Key('share_card_title'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.screenTitle.copyWith(color: c.text, shadows: shadows),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: data.route.length < 2
                    // Sem trajeto (INI-11/HIS-07): o esporte no lugar da rota,
                    // em vez de um vazio no meio do cartao.
                    ? Center(
                        child: Container(
                          key: const Key('share_card_no_route'),
                          width: 112,
                          height: 112,
                          decoration: BoxDecoration(color: role.tint, shape: BoxShape.circle),
                          child: Icon(sportIcon(data.type), size: 56, color: role.fg),
                        ),
                      )
                    : LayoutBuilder(
                        builder: (_, box) => RoutePreview(
                          key: const Key('share_card_route'),
                          route: data.route,
                          color: role.fill,
                          height: box.maxHeight,
                          halo: true,
                          showStart: true,
                          emptyLabel: '',
                          compactWhenEmpty: false,
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              _MetricGrid(metrics: metrics, textColor: c.textMuted, shadows: shadows),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    kShareBrand,
                    style: AppText.bodyStrong.copyWith(color: c.primaryText, shadows: shadows),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Metricas em duas colunas.
class _MetricGrid extends StatelessWidget {
  final List<ShareMetric> metrics;
  final Color textColor;
  final List<Shadow>? shadows;

  const _MetricGrid({required this.metrics, required this.textColor, this.shadows});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < metrics.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: 14));
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _metric(metrics[i])),
          const SizedBox(width: 16),
          Expanded(child: i + 1 < metrics.length ? _metric(metrics[i + 1]) : const SizedBox()),
        ],
      ));
    }
    return Column(children: rows);
  }

  Widget _metric(ShareMetric m) => Column(
    key: Key('share_metric_${m.label}'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(m.label, style: AppText.label.copyWith(color: textColor, shadows: shadows)),
      const SizedBox(height: 2),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(m.value, style: AppText.metricM.copyWith(color: m.role.fg, shadows: shadows)),
      ),
    ],
  );
}
