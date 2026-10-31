// Inicio (relatorio 11): feed com o resumo da semana e as atividades recentes.
// Na abertura, oferece recuperar uma atividade que ficou sem finalizar (app
// morto, reboot). A escolha do esporte fica na tela Gravar.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../activity/week_summary.dart';
import '../app/providers.dart';
import '../app/router.dart';
import '../persistence/database.dart';
import '../sync/background/background_sync_provider.dart';
import 'components/activity_card.dart';
import 'components/app_nav_bar.dart';
import 'components/week_summary_card.dart';
import 'record_setup_screen.dart' show pushRecording;
import 'recovery_dialog.dart';
import 'share_activity.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'theme/app_typography.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkInterrupted());
  }

  Future<void> _checkInterrupted() async {
    final ctrl = ref.read(recordingControllerProvider.notifier);
    if (ref.read(recordingControllerProvider).isActive) return;
    final repo = ref.read(recordingRepositoryProvider);
    final list = await repo.interrupted(exceptGuid: ctrl.activityGuid);
    var changed = false;
    // Mais recente primeiro; so a primeira ainda pode ser retomada.
    for (var i = 0; i < list.length; i++) {
      final it = list[i];
      if (!mounted) return;
      final choice = await showRecoveryDialog(
        context,
        it,
        metric: ref.read(settingsProvider).useMetric,
        allowResume:
            i == 0 && canResume(it, DateTime.now().millisecondsSinceEpoch),
      );
      if (!mounted) return;
      switch (choice) {
        case RecoveryChoice.resume:
          await pushRecording(context, AppRoutes.record(it.activity.activityType), extra: it);
          return;
        case RecoveryChoice.save:
          await repo.finishInterrupted(it);
          ref.read(backgroundSyncSchedulerProvider).scheduleSoon();
          changed = true;
        case RecoveryChoice.discard:
          await repo.deleteActivity(it.activity.guid);
          changed = true;
        case null:
          return;
      }
    }
    if (changed) {
      ref.invalidate(recentActivitiesProvider);
      ref.invalidate(pendingCountProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final metric = ref.watch(settingsProvider.select((s) => s.useMetric));
    final recent = ref.watch(recentActivitiesProvider);
    final week = ref.watch(weekSummaryProvider).value;
    final today = ref.watch(weekClockProvider)().weekday - 1;

    final children = <Widget>[
      _Header(onSettings: () => context.push(AppRoutes.settings)),
      const SizedBox(height: 16),
      if (week != null) ...[
        WeekSummaryCard(summary: week, useMetric: metric, todayIndex: today),
        const SizedBox(height: 24),
      ],
      ...recent.when(
        loading: () => const [
          Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
        error: (e, _) => [
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text('Erro: $e', style: AppText.body.copyWith(color: c.danger)),
          ),
        ],
        data: (list) => list.isEmpty
            ? [const _EmptyFeed()]
            : [
                Text('Atividades recentes', style: AppText.sectionTitle.copyWith(color: c.text)),
                const SizedBox(height: 12),
                for (final a in list) ...[
                  RoutedActivityCard(
                    key: Key('card-${a.guid}'),
                    activity: a,
                    onOpen: () => _open(a),
                    onShare: () => shareActivity(context, a),
                  ),
                  const SizedBox(height: 14),
                ],
              ],
      ),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppShape.gutter,
            12,
            AppShape.gutter,
            AppNavBar.reservedHeight(context),
          ),
          children: children,
        ),
      ),
    );
  }

  void _open(Activity a) {
    context.push(AppRoutes.activity(a.guid), extra: a);
  }
}

/// Nome do app, titulo da tela e acesso as Configuracoes.
class _Header extends StatelessWidget {
  final VoidCallback onSettings;
  const _Header({required this.onSettings});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nome do app.
              Text('Rastro', style: AppText.label.copyWith(color: c.primaryText)),
              const SizedBox(height: 2),
              Text('Inicio', style: AppText.screenTitle.copyWith(color: c.text)),
            ],
          ),
        ),
        TextButton.icon(
          key: const Key('settings'),
          onPressed: onSettings,
          style: TextButton.styleFrom(foregroundColor: c.textMuted, minimumSize: const Size(44, 44)),
          icon: const Icon(Icons.tune_rounded),
          label: const Text('Ajustes'),
        ),
      ],
    );
  }
}

/// Feed vazio: convida a gravar a primeira atividade.
class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      key: const Key('home_empty'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppShape.card),
        border: Border.all(color: c.line),
      ),
      child: Column(
        children: [
          Icon(Icons.route_rounded, size: 40, color: c.dist.fg),
          const SizedBox(height: 12),
          Text('Nenhuma atividade ainda', style: AppText.sectionTitle.copyWith(color: c.text)),
          const SizedBox(height: 6),
          Text(
            'Grave sua primeira corrida, pedal ou caminhada.',
            textAlign: TextAlign.center,
            style: AppText.body.copyWith(color: c.textMuted),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('home_record'),
            onPressed: () => context.go(AppRoutes.recordSetup),
            icon: const Icon(Icons.fiber_manual_record_rounded),
            label: const Text('Gravar atividade'),
          ),
        ],
      ),
    );
  }
}
