// Tela Gravar (relatorio 11): mapa em tela cheia, chip de GPS e Camadas no
// topo, folha inferior com o seletor de esporte e o botao Iniciar na cor do
// esporte. O esporte marcado e o da atividade mais recente (relatorio 10:
// o padrao e o ultimo usado, nao um valor fixo). O mapa centraliza na posicao
// atual; o chip de GPS mostra o estado real e recentraliza ao toque.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers.dart';
import '../app/router.dart';
import '../core/format/activity_labels.dart';
import '../recording/domain/geo.dart';
import '../recording/domain/recording_models.dart';
import '../recording/source/current_position.dart';
import 'components/app_nav_bar.dart';
import 'components/big_action_button.dart';
import 'components/floating_map_button.dart';
import 'components/segmented_selector.dart';
import 'map_style.dart';
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

/// Abre a gravacao em [location] (ver [AppRoutes.record]). Se ela fechar com
/// uma atividade salva, avisa "Atividade salva" com Ver, que abre o Detalhe
/// (E2E-04): sem isso o app voltava ao preparo sem nenhuma confirmacao.
Future<void> pushRecording(BuildContext context, String location, {Object? extra}) async {
  // Pegos antes do await: o messenger e o router sao da raiz do app.
  final router = GoRouter.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final guid = await router.push<String>(location, extra: extra);
  if (guid == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: const Text('Atividade salva'),
        // Com acao o SnackBar ficaria na tela ate alguem fechar.
        persist: false,
        action: SnackBarAction(
          label: 'Ver',
          onPressed: () => router.push(AppRoutes.activity(guid)),
        ),
      ),
    );
}

/// Estado do GPS antes de gravar.
enum GpsStatus {
  /// Esperando a permissao ou o primeiro fix.
  searching,

  /// Ha posicao no mapa.
  ready,

  /// Localizacao desligada, sem permissao ou sem fix a tempo.
  unavailable,
}

class RecordSetupScreen extends ConsumerStatefulWidget {
  const RecordSetupScreen({super.key});

  @override
  ConsumerState<RecordSetupScreen> createState() => _RecordSetupScreenState();
}

class _RecordSetupScreenState extends ConsumerState<RecordSetupScreen> {
  /// Escolha feita nesta tela; null = segue o ultimo usado.
  ActivityType? _picked;

  GpsStatus _gps = GpsStatus.searching;
  GeoPoint? _position;
  int _recenter = 0;

  @override
  void initState() {
    super.initState();
    _locate(request: true);
  }

  /// Le a ultima posicao conhecida (rapida) e depois um fix atual.
  Future<void> _locate({bool request = false}) async {
    final source = ref.read(currentPositionSourceProvider);
    if (_gps != GpsStatus.searching) setState(() => _gps = GpsStatus.searching);
    if (!await source.hasAccess(request: request)) {
      if (mounted) setState(() => _gps = GpsStatus.unavailable);
      return;
    }
    final last = await source.lastKnown();
    if (!mounted) return;
    if (last != null) {
      setState(() {
        _position = last;
        _gps = GpsStatus.ready;
      });
    }
    final now = await source.current();
    if (!mounted) return;
    setState(() {
      if (now != null) _position = now;
      _gps = _position == null ? GpsStatus.unavailable : GpsStatus.ready;
    });
  }

  void _onGpsTap() {
    switch (_gps) {
      case GpsStatus.ready:
        setState(() => _recenter++);
      case GpsStatus.unavailable:
        _locate(request: true);
      case GpsStatus.searching:
        break;
    }
  }

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
              userLocation: _position,
              recenterRequest: _recenter,
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
                  icon: switch (_gps) {
                    GpsStatus.searching => Icons.gps_not_fixed_rounded,
                    GpsStatus.ready => Icons.gps_fixed_rounded,
                    GpsStatus.unavailable => Icons.gps_off_rounded,
                  },
                  tooltip: switch (_gps) {
                    GpsStatus.searching => 'Procurando sinal de GPS',
                    GpsStatus.ready => 'Centralizar na minha posição',
                    GpsStatus.unavailable => 'Tentar o GPS de novo',
                  },
                  label: switch (_gps) {
                    GpsStatus.searching => 'Buscando GPS',
                    GpsStatus.ready => 'GPS pronto',
                    GpsStatus.unavailable => 'Sem GPS',
                  },
                  iconColor: switch (_gps) {
                    GpsStatus.searching => c.textMuted,
                    GpsStatus.ready => c.ciano.fg,
                    GpsStatus.unavailable => c.danger,
                  },
                  onPressed: _gps == GpsStatus.searching ? null : _onGpsTap,
                ),
                const Spacer(),
                FloatingMapButton(
                  key: const Key('map_layers'),
                  icon: Icons.layers_rounded,
                  tooltip: 'Camadas do mapa',
                  label: 'Camadas',
                  onPressed: () => showMapLayersSheet(context),
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
              onStart: () => pushRecording(context, AppRoutes.record(type)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Folha de Camadas: escolhe o estilo do mapa (ou volta a seguir o tema).
Future<void> showMapLayersSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  // No navegador raiz: o da aba fica abaixo da navegacao flutuante do shell,
  // que cobriria o fim da folha.
  useRootNavigator: true,
  // Altura pelo conteudo (rola em tela baixa ou deitada).
  isScrollControlled: true,
  builder: (_) => const _LayersSheet(),
);

class _LayersSheet extends ConsumerWidget {
  const _LayersSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final choice = ref.watch(mapStyleChoiceProvider);
    final auto = MapStyle.forBrightness(Theme.of(context).brightness);

    void pick(MapStyle? s) {
      ref.read(mapStyleChoiceProvider.notifier).state = s;
      Navigator.of(context).pop();
    }

    Widget option({
      required Key key,
      required IconData icon,
      required String label,
      String? hint,
      required bool selected,
      required VoidCallback onTap,
    }) => ListTile(
      key: key,
      leading: Icon(icon, color: selected ? c.primary : c.textMuted),
      title: Text(label, style: AppText.body.copyWith(color: c.text)),
      subtitle: hint == null ? null : Text(hint, style: AppText.label.copyWith(color: c.textMuted)),
      trailing: selected ? Icon(Icons.check_rounded, color: c.primary) : null,
      onTap: onTap,
    );

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppShape.gutter, 0, AppShape.gutter, 8),
              child: Text('Estilo do mapa', style: AppText.sectionTitle.copyWith(color: c.text)),
            ),
            option(
              key: const Key('map_style_auto'),
              icon: Icons.brightness_auto_rounded,
              label: 'Automático',
              hint: 'Segue o tema (${auto.label})',
              selected: choice == null,
              onTap: () => pick(null),
            ),
            for (final s in MapStyle.values)
              option(
                key: Key('map_style_${s.name}'),
                icon: s.icon,
                label: s.label,
                selected: choice == s,
                onTap: () => pick(s),
              ),
            const SizedBox(height: 8),
          ],
        ),
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
        : 'Último usado: ${activityTypeLabel(lastUsed!)}';
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
