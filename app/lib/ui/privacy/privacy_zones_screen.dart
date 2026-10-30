// Configuracoes > Privacidade > Zonas de privacidade (F02): sugestoes de casa
// e trabalho detectadas no aparelho (aceitar ou ignorar), lista das zonas
// salvas (remover com confirmacao) e as duas formas de adicionar: no mapa ou
// a partir de uma atividade.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/format/activity_labels.dart';
import '../../core/format/measures.dart';
import '../../persistence/database.dart';
import '../../privacy/domain/privacy_zone.dart';
import '../../privacy/domain/zone_detection.dart';
import '../../privacy/privacy_providers.dart';
import '../../recording/domain/geo.dart';
import '../components/big_action_button.dart';
import '../components/segmented_selector.dart';
import '../section_card.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'zone_suggestion_card.dart';

class PrivacyZonesScreen extends ConsumerStatefulWidget {
  const PrivacyZonesScreen({super.key});

  @override
  ConsumerState<PrivacyZonesScreen> createState() => _PrivacyZonesScreenState();
}

class _PrivacyZonesScreenState extends ConsumerState<PrivacyZonesScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _refresh() {
    ref.invalidate(privacyZonesProvider);
    ref.invalidate(zoneSuggestionsProvider);
  }

  Future<void> _accept(ZoneSuggestion s) => _run(() async {
    await ref.read(privacyRepositoryProvider).addZone(s.toZone());
    _refresh();
  });

  Future<void> _dismiss(ZoneSuggestion s) => _run(() async {
    await ref.read(privacyRepositoryProvider).dismissSuggestion(s.center);
    _refresh();
  });

  Future<void> _remove(PrivacyZone z) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final c = AppColors.of(ctx);
        return AlertDialog(
          title: Text('Remover "${z.label}"?'),
          content: const Text(
            'O inicio e o fim das atividades neste local voltam a aparecer '
            'no que voce compartilhar.',
          ),
          actions: [
            TextButton(
              key: const Key('zone_remove_cancel'),
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              key: const Key('zone_remove_confirm'),
              style: TextButton.styleFrom(foregroundColor: c.danger),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Remover'),
            ),
          ],
        );
      },
    );
    if (ok != true || z.id == null) return;
    await _run(() async {
      await ref.read(privacyRepositoryProvider).removeZone(z.id!);
      _refresh();
    });
  }

  Future<void> _addOnMap() async {
    // O mapa abre no inicio da atividade mais recente, se houver.
    final last = await ref
        .read(privacyRepositoryProvider)
        .activityEndpoints(limit: 1);
    if (!mounted) return;
    await context.push<void>(
      AppRoutes.privacyAddZone,
      extra: last.isEmpty ? null : last.first.start,
    );
    _refresh();
  }

  /// Escolhe uma atividade com rota e cria a zona no inicio ou no fim dela.
  /// Tudo dentro de [_run]: um segundo toque enquanto carrega nao abre outra
  /// folha.
  Future<void> _addFromActivity() => _run(() async {
    final repo = ref.read(recordingRepositoryProvider);
    final privacy = ref.read(privacyRepositoryProvider);
    // So atividades com pontos de GPS (esteira e indoor nao tem inicio/fim).
    final withRoute = {
      for (final e in await privacy.activityEndpoints(limit: 30)) e.guid,
    };
    final activities = [
      for (final a in await repo.recent(limit: 30))
        if (withRoute.contains(a.guid)) a,
    ];
    if (!mounted) return;
    final metric = ref.read(settingsProvider).useMetric;
    final picked = await showModalBottomSheet<Activity>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (ctx) => _ActivityPicker(activities: activities, metric: metric),
    );
    if (picked == null || !mounted) return;
    final route = await repo.routePoints(picked.guid);
    if (!mounted) return;
    if (route.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta atividade nao tem trajeto de GPS.')),
      );
      return;
    }
    final zone = await showDialog<PrivacyZone>(
      context: context,
      builder: (_) => _ZoneFromActivityDialog(route: route),
    );
    if (zone == null) return;
    await privacy.addZone(zone);
    _refresh();
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final zones = ref.watch(privacyZonesProvider);
    final suggestions = ref.watch(zoneSuggestionsProvider).value ?? const [];
    final metric = ref.watch(settingsProvider).useMetric;
    final muted = AppText.body.copyWith(color: c.textMuted);

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        key: const Key('privacy_zones_screen'),
        padding: const EdgeInsets.fromLTRB(
          AppShape.gutter,
          0,
          AppShape.gutter,
          24,
        ),
        children: [
          const ScreenTitle(
            'Zonas de privacidade',
            subtitle:
                'O inicio e o fim das atividades dentro destes locais saem '
                'cortados da imagem e do upload. Os locais ficam so neste aparelho.',
          ),
          for (final s in suggestions)
            ZoneSuggestionCard(
              suggestion: s,
              busy: _busy,
              onAccept: () => _accept(s),
              onDismiss: () => _dismiss(s),
            ),
          SectionCard(
            title: 'Seus locais',
            child: switch (zones) {
              AsyncData(:final value) when value.isEmpty => Padding(
                key: const Key('privacy_empty'),
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Nenhum local protegido ainda. Adicione sua casa ou seu '
                  'trabalho para esconder o inicio e o fim das atividades.',
                  style: muted,
                ),
              ),
              AsyncData(:final value) => Column(
                children: [
                  for (var i = 0; i < value.length; i++) ...[
                    if (i > 0) const SectionDivider(),
                    ListTile(
                      minTileHeight: 56,
                      leading: Icon(Icons.shield_outlined, color: c.subida.fg),
                      title: Text(value[i].label),
                      subtitle: Text(
                        'Raio de ${formatDistance(value[i].radiusMeters, metric: metric)}',
                      ),
                      trailing: IconButton(
                        key: Key('zone_remove_$i'),
                        tooltip: 'Remover',
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: c.danger,
                        ),
                        onPressed: _busy ? null : () => _remove(value[i]),
                      ),
                    ),
                  ],
                ],
              ),
              AsyncError(:final error) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Erro: $error', style: muted),
              ),
              _ => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            },
          ),
          BigActionButton(
            key: const Key('zone_add_map'),
            label: 'Adicionar no mapa',
            icon: Icons.add_location_alt_outlined,
            height: 56,
            onPressed: _busy ? null : _addOnMap,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            key: const Key('zone_add_activity'),
            style: TextButton.styleFrom(
              foregroundColor: c.ciano.fg,
              minimumSize: const Size(44, 48),
            ),
            onPressed: _busy ? null : _addFromActivity,
            icon: const Icon(Icons.route_rounded),
            label: const Text('A partir de uma atividade'),
          ),
        ],
      ),
    );
  }
}

/// Folha com as atividades recentes para escolher de onde tirar o local.
class _ActivityPicker extends StatelessWidget {
  final List<Activity> activities;
  final bool metric;
  const _ActivityPicker({required this.activities, required this.metric});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    if (activities.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppShape.gutter,
          0,
          AppShape.gutter,
          32,
        ),
        child: Text(
          'Nenhuma atividade com trajeto de GPS ainda.',
          style: AppText.body.copyWith(color: c.textMuted),
        ),
      );
    }
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppShape.gutter,
              0,
              AppShape.gutter,
              8,
            ),
            child: Text(
              'Escolha a atividade',
              style: AppText.sectionTitle.copyWith(color: c.text),
            ),
          ),
          for (final a in activities)
            ListTile(
              minTileHeight: 56,
              title: Text(
                displayActivityTitle(
                  a.title,
                  a.activityType,
                  DateTime.fromMillisecondsSinceEpoch(a.startTimestampMs),
                ),
              ),
              subtitle: Text(
                '${formatDateTimeMs(a.startTimestampMs)} | '
                '${formatDistance(a.distanceMeters, metric: metric)}',
              ),
              onTap: () => Navigator.of(context).pop(a),
            ),
        ],
      ),
    );
  }
}

/// Qual ponta da atividade vira zona.
enum _Endpoint { start, end }

/// Dialogo "novo local a partir da atividade": nome e inicio ou fim.
class _ZoneFromActivityDialog extends StatefulWidget {
  final List<GeoPoint> route;
  const _ZoneFromActivityDialog({required this.route});

  @override
  State<_ZoneFromActivityDialog> createState() =>
      _ZoneFromActivityDialogState();
}

class _ZoneFromActivityDialogState extends State<_ZoneFromActivityDialog> {
  final TextEditingController _label = TextEditingController();
  _Endpoint _point = _Endpoint.start;

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  void _save() {
    final p = _point == _Endpoint.start
        ? widget.route.first
        : widget.route.last;
    Navigator.of(context).pop(
      PrivacyZone(
        latitude: p.latitude,
        longitude: p.longitude,
        radiusMeters: kDefaultZoneRadiusMeters,
        label: _label.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AlertDialog(
      key: const Key('zone_from_activity_dialog'),
      title: const Text('Novo local protegido'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedSelector<_Endpoint>(
            options: [
              SegmentOption(
                key: const Key('zone_point_start'),
                value: _Endpoint.start,
                label: 'Inicio',
                role: c.subida,
              ),
              SegmentOption(
                key: const Key('zone_point_end'),
                value: _Endpoint.end,
                label: 'Fim',
                role: c.subida,
              ),
            ],
            selected: _point,
            onChanged: (v) => setState(() => _point = v),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('zone_from_activity_label'),
            controller: _label,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Nome (ex.: Casa)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('zone_from_activity_save'),
          onPressed: _save,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
