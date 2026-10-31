// Acoes do plano 5 km (F06) usadas pela tela Gravar, pela tela do plano e
// pelo fim da gravacao: iniciar a sessao guiada e decidir o fim da semana.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../plan5k/domain/plan_progress.dart';
import '../../plan5k/domain/plan_table.dart';
import '../../plan5k/plan_providers.dart';

/// Abre a gravacao guiada da proxima sessao. Antes da primeira gravacao passa
/// pelo checklist "Gravacao confiavel" (F01), como o Iniciar comum.
Future<void> startPlanSession(BuildContext context, WidgetRef ref) async {
  await ref.read(settingsProvider.notifier).ensureLoaded();
  if (!context.mounted) return;
  if (!ref.read(settingsProvider).reliabilityChecklistSeen) {
    final go = await context.push<bool>(AppRoutes.reliabilityBeforeRecording);
    if (go != true || !context.mounted) return;
  }
  // A sessao pode ter deixado de existir (semana esperando decisao, plano
  // reiniciado em outra tela): confere antes de abrir a gravacao.
  final progress = await ref.read(planServiceProvider).progress();
  if (!context.mounted) return;
  if (progress.next == null) {
    ref.invalidate(planProgressProvider);
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('Sem sessao do plano agora.')),
    );
    return;
  }
  await context.push(AppRoutes.planSession);
  ref.invalidate(planProgressProvider);
}

/// Escolha do fim de uma semana pesada.
enum WeekChoice { repeat, advance }

/// Dialogo "pesada demais repete a semana". O padrao (botao cheio, com foco)
/// e Repetir. Null = fechou sem escolher (a decisao fica pendente na tela do
/// plano).
Future<WeekChoice?> showRepeatWeekDialog(BuildContext context, {required int week}) {
  final last = week >= kPlanWeeks;
  return showDialog<WeekChoice>(
    context: context,
    useRootNavigator: true,
    builder: (context) => AlertDialog(
      key: const Key('plan_repeat_dialog'),
      title: Text('A semana $week foi puxada'),
      content: const Text(
        'Voce marcou esforco 8 ou mais em uma sessao desta semana. Repetir a '
        'semana ajuda o corpo a se acostumar antes de subir. A escolha e sua.',
      ),
      actions: [
        TextButton(
          key: const Key('plan_advance_week'),
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: () => Navigator.of(context).pop(WeekChoice.advance),
          child: Text(last ? 'Concluir o plano' : 'Seguir para a semana ${week + 1}'),
        ),
        FilledButton(
          key: const Key('plan_repeat_week'),
          autofocus: true,
          style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: () => Navigator.of(context).pop(WeekChoice.repeat),
          child: const Text('Repetir a semana'),
        ),
      ],
    ),
  );
}

/// Fim de semana: sem esforco alto segue sozinho; com esforco alto pergunta.
/// Devolve true se algo mudou no plano.
Future<bool> resolvePlanWeek(BuildContext context, WidgetRef ref) async {
  final service = ref.read(planServiceProvider);
  final before = await service.progress();
  final r = await service.resolveWeek();
  if (r == null) return false;
  if (r == WeekResolution.advance) {
    ref.invalidate(planProgressProvider);
    return true;
  }
  if (!context.mounted) return false;
  final choice = await showRepeatWeekDialog(context, week: before.state.currentWeek);
  if (choice == null) return false;
  await applyWeekChoice(ref, choice);
  return true;
}

Future<void> applyWeekChoice(WidgetRef ref, WeekChoice choice) async {
  final service = ref.read(planServiceProvider);
  if (choice == WeekChoice.repeat) {
    await service.repeatWeek();
  } else {
    await service.advanceWeek();
  }
  ref.invalidate(planProgressProvider);
}
