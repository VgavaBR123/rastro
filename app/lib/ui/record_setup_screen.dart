// Tela Gravar (relatorio 11): mapa em tela cheia, chip de GPS e Camadas no
// topo, folha inferior com o seletor de esporte e o botao Iniciar na cor do
// esporte. O esporte marcado e o da atividade mais recente (relatorio 10:
// o padrao e o ultimo usado, nao um valor fixo).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers.dart';
import '../app/router.dart';
import '../core/format/activity_labels.dart';
import '../recording/domain/recording_models.dart';
import 'components/app_nav_bar.dart';
import 'components/big_action_button.dart';
import 'components/floating_map_button.dart';
import 'components/segmented_selector.dart';
import 'route_map.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'theme/app_typography.dart';

/// Icone de cada esporte (sempre ao lado do nome).
IconData sportIcon(ActivityType t) => switch (t) {
      ActivityType.run => Icons.directions_run_rounded,
      ActivityType.ride => Icons.directions_bike_rounded,
      ActivityType.walk => Icons.directions_walk_rounded,
    };

class RecordSetupScreen extends ConsumerStatefulWidget {
  const RecordSetupScreen({super.key});

  @override
  ConsumerState<RecordSetupScreen> createState() => _RecordSetupScreenState();
}

class _RecordSetupScreenState extends ConsumerState<RecordSetupScreen> {
  /// Escolha feita nesta tela; null = segue o ultimo usado.
  ActivityType? _picked;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final recent = ref.watch(recentActivitiesProvider).value;
    final last = recent == null || recent.isEmpty ? null : recent.first.activityType;
    final type = _picked ?? last ?? ActivityType.run;
    final role = c.sport(type);
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: RouteMap(
              route: const [],
              height: null,
              borderRadius: 0,
              color: role.fill,
              emptyLabel: '',
            ),
          ),
          Positioned(
            top: top + 12,
            left: AppShape.gutter,
            right: AppShape.gutter,
            child: Row(
              children: [
                FloatingMapButton(
                  key: const Key('gps_chip'),
                  icon: Icons.gps_fixed_rounded,
                  tooltip: 'GPS',
                  label: 'GPS',
                  iconColor: c.ciano.fg,
                  onPressed: null,
                ),
                const Spacer(),
                FloatingMapButton(
                  key: const Key('map_layers'),
                  icon: Icons.layers_rounded,
                  tooltip: 'Camadas do mapa',
                  label: 'Camadas',
                  // Ainda sem troca de estilo do mapa.
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Camadas do mapa em breve')),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _SetupSheet(
              type: type,
              lastUsed: last,
              onPicked: (t) => setState(() => _picked = t),
              onStart: () => context.push(AppRoutes.record(type)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupSheet extends StatelessWidget {
  final ActivityType type;
  final ActivityType? lastUsed;
  final ValueChanged<ActivityType> onPicked;
  final VoidCallback onStart;

  const _SetupSheet({
    required this.type,
    required this.lastUsed,
    required this.onPicked,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final hint = lastUsed == null
        ? 'Escolha o esporte antes de iniciar'
        : 'Ultimo usado: ${activityTypeLabel(lastUsed!)}';
    return Container(
      key: const Key('record_setup_sheet'),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppShape.card)),
        border: Border(top: BorderSide(color: c.line)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppShape.gutter,
        10,
        AppShape.gutter,
        AppNavBar.reservedHeight(context),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: c.line, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 14),
          Text('Esporte', style: AppText.sectionTitle.copyWith(color: c.text)),
          const SizedBox(height: 4),
          Text(hint, style: AppText.label.copyWith(color: c.textMuted)),
          const SizedBox(height: 12),
          SegmentedSelector<ActivityType>(
            options: [
              for (final t in ActivityType.values)
                SegmentOption(
                  value: t,
                  label: activityTypeLabel(t),
                  role: c.sport(t),
                  icon: sportIcon(t),
                  key: Key('sport_${t.name}'),
                ),
            ],
            selected: type,
            onChanged: onPicked,
          ),
          const SizedBox(height: 16),
          BigActionButton(
            key: const Key('record_start'),
            label: 'Iniciar',
            icon: Icons.play_arrow_rounded,
            variant: BigActionVariant.role,
            role: c.sport(type),
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}
