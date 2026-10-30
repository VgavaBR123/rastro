// Imagem de compartilhamento de uma atividade: rota na cor do esporte, titulo,
// esporte, data e metricas, no formato 9:16 (Stories). Dois estilos: Cartao
// (fundo do tema) e Transparente (so rota e texto, para colocar sobre uma
// foto). Sempre com os tokens do tema escuro, para a imagem sair igual em
// qualquer tema do app.
library;

import 'package:flutter/material.dart';

import '../../closing/domain/effort.dart';
import '../../core/format/activity_labels.dart';
import '../../core/format/measures.dart';
import '../../recording/domain/geo.dart';
import '../../recording/domain/recording_models.dart';
import '../components/sport_chip.dart';
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
  card('Cartao', Icons.crop_portrait_rounded),
  transparent('Transparente', Icons.layers_clear_rounded);

  final String label;
  final IconData icon;
  const ShareCardStyle(this.label, this.icon);
}

/// Quanto da atividade a imagem mostra (privacidade, F02).
enum ShareRouteMode {
  /// Rota sem as pontas ocultas (padrao).
  trimmed('Rota cortada'),

  /// Sem mapa: titulo, data e metricas.
  noMap('Sem mapa'),

  /// So as metricas (sem titulo, data nem mapa).
  metricsOnly('So metricas');

  final String label;
  const ShareRouteMode(this.label);
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

  /// Desenhar o mapa da rota (desligado em "Sem mapa" e "So metricas").
  final bool showRoute;

  /// Modo Gentil (F04): sem pace nem velocidade; o esforco entra no lugar.
  final bool gentle;

  /// Esforco percebido (F04), 1 a 10; null = nao informado.
  final int? rpe;

  /// Mostrar esporte, data e titulo (desligado em "So metricas").
  final bool showHeader;

  const ShareCardData({
    required this.title,
    required this.type,
    required this.startTimestampMs,
    required this.distanceMeters,
    required this.timerMs,
    required this.route,
    required this.metric,
    this.gainMeters,
    this.showRoute = true,
    this.showHeader = true,
    this.gentle = false,
    this.rpe,
  });
}

/// Metrica do cartao: rotulo, valor e funcao de cor.
typedef ShareMetric = ({String label, String value, RoleColors role});

/// Metricas na ordem do cartao: distancia, pace (velocidade no pedal), tempo
/// e, com leitura de altitude, subida. No Modo Gentil (F04): distancia,
/// tempo, esforco (quando informado) e subida. Funcao pura.
List<ShareMetric> shareCardMetrics(ShareCardData d, AppColors c) {
  final seconds = d.timerMs / 1000.0;
  final ride = d.type == ActivityType.ride;
  final gain = d.gainMeters;
  final rpe = d.rpe;
  final distance = (
    label: 'Distancia',
    value: formatDistance(d.distanceMeters, metric: d.metric),
    role: c.dist,
  );
  final time = (label: 'Tempo', value: formatDuration(d.timerMs), role: c.tempo);
  final ascent = gain != null && gain.isFinite
      ? (label: 'Subida', value: formatElevation(gain, metric: d.metric), role: c.subida)
      : null;
  if (d.gentle) {
    return [
      distance,
      time,
      if (isValidRpe(rpe)) (label: 'Esforco', value: '$rpe/10', role: c.extra),
      ?ascent,
    ];
  }
  return [
    distance,
    ride
        ? (
            label: 'Velocidade',
            value: formatSpeed(
              seconds > 0 ? d.distanceMeters / seconds : 0,
              metric: d.metric,
            ),
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
    time,
    ?ascent,
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
      child: Builder(
        builder: (context) => _content(context, AppColors.of(context)),
      ),
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
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data.showHeader) ...[
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
                        style: AppText.label.copyWith(
                          color: c.textMuted,
                          shadows: shadows,
                        ),
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
                  style: AppText.screenTitle.copyWith(
                    color: c.text,
                    shadows: shadows,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Expanded(
                child: !data.showRoute || data.route.length < 2
                    ? const SizedBox.expand()
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
              _MetricGrid(
                metrics: metrics,
                textColor: c.textMuted,
                shadows: shadows,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: c.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    kShareBrand,
                    style: AppText.bodyStrong.copyWith(
                      color: c.primaryText,
                      shadows: shadows,
                    ),
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

  const _MetricGrid({
    required this.metrics,
    required this.textColor,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < metrics.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: 14));
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _metric(metrics[i])),
            const SizedBox(width: 16),
            Expanded(
              child: i + 1 < metrics.length
                  ? _metric(metrics[i + 1])
                  : const SizedBox(),
            ),
          ],
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _metric(ShareMetric m) => Column(
    key: Key('share_metric_${m.label}'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        m.label,
        style: AppText.label.copyWith(color: textColor, shadows: shadows),
      ),
      const SizedBox(height: 2),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          m.value,
          style: AppText.metricM.copyWith(color: m.role.fg, shadows: shadows),
        ),
      ),
    ],
  );
}
