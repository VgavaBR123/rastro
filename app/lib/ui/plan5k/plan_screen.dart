// Tela do plano Do Zero aos 5 km (F06): aviso de saude, "Voz do plano",
// comecar (com a semana inicial), proxima sessao, decisao do fim de semana,
// as 10 semanas com as sessoes feitas/parciais/proximas e reiniciar.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../plan5k/domain/plan_progress.dart';
import '../../plan5k/domain/plan_table.dart';
import '../../plan5k/plan_providers.dart';
import '../components/big_action_button.dart';
import '../components/notice_banner.dart';
import '../section_card.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'plan_actions.dart';

class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  int _startWeek = 1;
  bool _busy = false;
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Semana completa sem esforco alto: segue sozinha ao abrir.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final r = await ref.read(planServiceProvider).resolveWeek();
      if (r == WeekResolution.advance && mounted) ref.invalidate(planProgressProvider);
    });
  }

  Future<void> _guard(Future<void> Function() op) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await op();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _begin() => _guard(() async {
    await ref.read(planServiceProvider).startPlan(_startWeek);
    ref.invalidate(planProgressProvider);
    // O botao Comecar fica no fim de um cartao alto: depois dele a lista
    // estaria rolada para baixo e o cartao da proxima sessao (que entra no
    // topo) ficaria fora da tela. Volta ao topo.
    await ref.read(planProgressProvider.future);
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  });

  Future<void> _restart() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('plan_restart_dialog'),
        title: const Text('Reiniciar o plano?'),
        content: const Text(
          'O progresso do plano volta ao comeco. As atividades gravadas '
          'continuam no seu historico.',
        ),
        actions: [
          TextButton(
            key: const Key('plan_restart_cancel'),
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('plan_restart_confirm'),
            style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _guard(() async {
      await ref.read(planServiceProvider).reset();
      ref.invalidate(planProgressProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final progress = ref.watch(planProgressProvider);
    final voice = ref.watch(settingsProvider.select((s) => s.plan5kVoice));

    return Scaffold(
      appBar: AppBar(),
      body: progress.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Nao foi possivel abrir o plano: $e')),
        data: (p) => ListView(
          key: const Key('plan_list'),
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(AppShape.gutter, 0, AppShape.gutter, 32),
          children: [
            const ScreenTitle(
              'Do zero aos 5 km',
              subtitle: '10 semanas, 3 sessoes por semana, alternando correr e caminhar',
            ),
            NoticeBanner(
              key: const Key('plan_health_notice'),
              icon: Icons.favorite_rounded,
              title: 'Cuide de voce',
              message: 'Se voce tem alguma condicao de saude, converse com um '
                  'profissional antes de comecar. Se sentir dor, pare e descanse.',
              accent: c.extra.fill,
              background: c.extra.tint,
            ),
            const SizedBox(height: 12),
            SectionCard(
              child: SwitchListTile(
                key: const Key('plan_voice_toggle'),
                title: const Text('Voz do plano'),
                subtitle: const Text(
                  'Avisa as trocas de correr e caminhar. Sem voz, o celular vibra.',
                ),
                value: voice,
                onChanged: (v) => ref.read(settingsProvider.notifier).setPlan5kVoice(v),
              ),
            ),
            if (!p.state.started) _startCard(c),
            if (p.weekComplete && p.resolution == WeekResolution.suggestRepeat)
              _decisionCard(c, p),
            if (p.next case final next?) _nextCard(c, next),
            if (p.state.finished)
              SectionCard(
                key: const Key('plan_finished'),
                child: Padding(
                  padding: const EdgeInsets.all(AppShape.gutter),
                  child: Text(
                    'Plano concluido. Voce correu 30 minutos sem parar!',
                    style: AppText.bodyStrong.copyWith(color: c.text),
                  ),
                ),
              ),
            for (var w = 1; w <= kPlanWeeks; w++) _week(c, p, w),
            if (p.state.started)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton.icon(
                  key: const Key('plan_restart'),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    foregroundColor: c.danger,
                  ),
                  onPressed: _busy ? null : _restart,
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('Reiniciar o plano'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _startCard(AppColors c) {
    final first = ref.read(planServiceProvider).table[(_startWeek - 1) * kSessionsPerWeek];
    return SectionCard(
      key: const Key('plan_start_card'),
      title: 'Comecar',
      child: Padding(
        padding: const EdgeInsets.all(AppShape.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Semana inicial', style: AppText.bodyStrong.copyWith(color: c.text)),
            const SizedBox(height: 4),
            Text(
              'Ja corre um pouco? Comece mais adiante.',
              style: AppText.label.copyWith(color: c.textMuted),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var w = 1; w <= kPlanWeeks; w++)
                  ChoiceChip(
                    key: Key('plan_start_week_$w'),
                    label: Text('$w'),
                    selected: _startWeek == w,
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    onSelected: (_) => setState(() => _startWeek = w),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Primeira sessao: ${first.summary}, ${formatPlanDuration(first.totalMs)} no total.',
              key: const Key('plan_start_preview'),
              style: AppText.body.copyWith(color: c.textMuted),
            ),
            const SizedBox(height: 12),
            BigActionButton(
              key: const Key('plan_begin'),
              label: 'Comecar o plano',
              icon: Icons.flag_rounded,
              onPressed: _busy ? null : _begin,
            ),
          ],
        ),
      ),
    );
  }

  Widget _nextCard(AppColors c, PlanSession next) => SectionCard(
    key: const Key('plan_next_card'),
    title: 'Proxima sessao',
    child: Padding(
      padding: const EdgeInsets.all(AppShape.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(next.label, style: AppText.bodyStrong.copyWith(color: c.text)),
          const SizedBox(height: 4),
          Text(
            '${next.summary}. ${formatPlanDuration(next.totalMs)} com o aquecimento '
            'e o desaquecimento.',
            style: AppText.body.copyWith(color: c.textMuted),
          ),
          const SizedBox(height: 12),
          BigActionButton(
            key: const Key('plan_start_next'),
            label: 'Iniciar sessao',
            icon: Icons.play_arrow_rounded,
            variant: BigActionVariant.role,
            role: c.tempo,
            onPressed: () => startPlanSession(context, ref),
          ),
        ],
      ),
    ),
  );

  Widget _decisionCard(AppColors c, PlanProgress p) {
    final week = p.state.currentWeek;
    return SectionCard(
      key: const Key('plan_week_decision'),
      title: 'Semana $week concluida',
      child: Padding(
        padding: const EdgeInsets.all(AppShape.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Uma sessao desta semana teve esforco 8 ou mais. Repetir a semana '
              'ajuda o corpo a se acostumar antes de subir.',
              style: AppText.body.copyWith(color: c.textMuted),
            ),
            const SizedBox(height: 12),
            BigActionButton(
              key: const Key('plan_decision_repeat'),
              label: 'Repetir a semana',
              icon: Icons.replay_rounded,
              onPressed: _busy ? null : () => _guard(() => applyWeekChoice(ref, WeekChoice.repeat)),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('plan_decision_advance'),
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: _busy ? null : () => _guard(() => applyWeekChoice(ref, WeekChoice.advance)),
              child: Text(week >= kPlanWeeks ? 'Concluir o plano' : 'Seguir para a semana ${week + 1}'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _week(AppColors c, PlanProgress p, int w) {
    final repeats = p.state.repeatsOf(w);
    return SectionCard(
      key: Key('plan_week_$w'),
      title: repeats == 0
          ? 'Semana $w'
          : 'Semana $w (repetida ${repeats == 1 ? '1 vez' : '$repeats vezes'})',
      child: Column(
        children: [
          for (var n = 1; n <= kSessionsPerWeek; n++) ...[
            if (n > 1) const SectionDivider(),
            _sessionRow(c, p, w, n),
          ],
        ],
      ),
    );
  }

  Widget _sessionRow(AppColors c, PlanProgress p, int w, int n) {
    final s = p.sessionOf(w, n);
    final mark = p.markOf(w, n);
    final (IconData icon, Color color, String status) = switch (mark) {
      SessionMark.done => (Icons.check_circle_rounded, c.dist.fg, 'Concluida'),
      SessionMark.partial => (Icons.timelapse_rounded, c.extra.fg, 'Parcial, fica para a proxima'),
      SessionMark.next => (Icons.play_circle_rounded, c.tempo.fg, 'Proxima'),
      SessionMark.skipped => (Icons.skip_next_rounded, c.textMuted, 'Pulada'),
      SessionMark.upcoming => (Icons.radio_button_unchecked_rounded, c.textMuted, 'A fazer'),
    };
    return Semantics(
      key: Key('plan_session_${w}_$n'),
      container: true,
      label: 'Sessao $n. $status. ${s.summary}. ${formatPlanDuration(s.totalMs)}',
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppShape.gutter, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sessao $n - ${formatPlanDuration(s.totalMs)}',
                        style: AppText.bodyStrong.copyWith(color: c.text),
                      ),
                      Text(s.summary, style: AppText.label.copyWith(color: c.textMuted)),
                      Text(
                        status,
                        key: Key('plan_session_status_${w}_$n'),
                        style: AppText.label.copyWith(color: color),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
