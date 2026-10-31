// Entrada do plano 5 km (F06) na folha da tela Gravar: mostra a proxima
// sessao (semana, sessao, blocos e duracao) com o botao para gravar guiado,
// ou leva a tela do plano (comecar, decidir a semana, plano concluido).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../plan5k/domain/plan_progress.dart';
import '../../plan5k/domain/plan_table.dart';
import '../../plan5k/plan_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'plan_actions.dart';

class PlanEntry extends ConsumerWidget {
  const PlanEntry({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final p = ref.watch(planProgressProvider).value;
    final next = p?.next;
    final (String title, String subtitle) = _texts(p, next);

    Future<void> openPlan() async {
      await context.push(AppRoutes.plan5k);
      ref.invalidate(planProgressProvider);
    }

    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        key: const Key('plan_entry'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        minTileHeight: 48,
        leading: Icon(Icons.flag_rounded, color: c.tempo.fg),
        title: Text(title, style: AppText.bodyStrong.copyWith(color: c.text)),
        subtitle: Text(
          subtitle,
          key: const Key('plan_entry_subtitle'),
          style: AppText.label.copyWith(color: c.textMuted),
        ),
        trailing: next == null
            ? Icon(Icons.chevron_right_rounded, color: c.textMuted)
            : FilledButton(
                key: const Key('plan_entry_start'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  backgroundColor: c.tempo.fill,
                  foregroundColor: c.onFill,
                ),
                onPressed: () => startPlanSession(context, ref),
                child: const Text('Gravar'),
              ),
        onTap: openPlan,
      ),
    );
  }

  static (String, String) _texts(PlanProgress? p, PlanSession? next) {
    if (p == null || !p.state.started) {
      return ('Plano 5 km', 'Do zero aos 5 km em 10 semanas');
    }
    if (next != null) {
      return (
        'Plano 5 km: semana ${next.week}, sessao ${next.number}',
        '${next.summary} - ${formatPlanDuration(next.totalMs)}',
      );
    }
    if (p.state.finished) return ('Plano 5 km', 'Plano concluido. Parabens!');
    return ('Plano 5 km', 'Semana ${p.state.currentWeek} concluida. Toque para seguir.');
  }
}
