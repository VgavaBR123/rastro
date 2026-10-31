// Rastro Seguro (F08) na tela de gravacao: a faixa "Rastro Seguro ativo -
// chegada prevista 07:45" com Estender (+15/+30), Cheguei e "Mandar minha
// posicao agora" (segurar para confirmar, como o Encerrar), e o aviso grande
// "Esta tudo bem?" por cima da gravacao, com contagem ate o prazo, Estou bem
// e Estender 15 min. Depois de alertado, a faixa diz que os contatos foram
// avisados e o Estou bem continua.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../safety/safety_models.dart';
import '../../safety/safety_providers.dart';
import '../../safety/safety_session_controller.dart';
import '../components/big_action_button.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'safety_setup.dart' show formatClock;

class SafetyBanner extends ConsumerWidget {
  /// Tela bloqueada contra toques: so o SOS (que exige segurar) funciona.
  final bool locked;
  const SafetyBanner({super.key, this.locked = false});

  Future<void> _arrived(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chegou?'),
        content: const Text('O Rastro Seguro encerra e seus contatos nao serao mais avisados. A gravacao continua.'),
        actions: [
          TextButton(
            key: const Key('safety_arrived_cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Ainda nao'),
          ),
          FilledButton(
            key: const Key('safety_arrived_confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cheguei'),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(safetySessionProvider.notifier).arrive();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(safetySessionProvider);
    final session = s.session;
    if (!s.active || session == null) return const SizedBox.shrink();
    final c = AppColors.of(context);
    final ctrl = ref.read(safetySessionProvider.notifier);
    final alerted = s.alerted;
    final accent = alerted ? c.danger : c.ciano.fg;
    final title = alerted
        ? 'Seus contatos foram avisados'
        : 'Rastro Seguro ativo - chegada prevista ${formatClock(session.etaMs)}';
    final message = alerted
        ? 'Se estiver tudo bem, toque em Estou bem: eles recebem o aviso.'
        : s.offline
        ? 'Sem rede: a posicao vai assim que a conexao voltar.'
        : 'Sua posicao vai para os contatos a cada minuto.';

    Widget small(Key key, String label, VoidCallback? onPressed, {bool strong = false}) => Expanded(
      child: strong
          ? FilledButton(
              key: key,
              style: FilledButton.styleFrom(
                minimumSize: const Size(44, 48),
                backgroundColor: c.danger,
                foregroundColor: c.bg,
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
              onPressed: onPressed,
              child: Text(label, maxLines: 1),
            )
          : OutlinedButton(
              key: key,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(44, 48),
                foregroundColor: c.text,
                side: BorderSide(color: c.line),
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
              onPressed: onPressed,
              child: Text(label, maxLines: 1),
            ),
    );

    final busy = s.busy;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppShape.gutter, 0, AppShape.gutter, 8),
      child: Semantics(
        container: true,
        liveRegion: true,
        child: Container(
          key: const Key('safety_banner'),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: alerted ? c.danger.withValues(alpha: 0.12) : c.ciano.tint,
            borderRadius: BorderRadius.circular(AppShape.tile),
            border: Border.all(color: accent, width: alerted ? 1.5 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(alerted ? Icons.warning_rounded : Icons.shield_rounded, color: accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          key: const Key('safety_banner_text'),
                          style: AppText.bodyStrong.copyWith(color: c.text),
                        ),
                        Text(message, style: AppText.label.copyWith(color: c.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
              if (s.message != null) ...[
                const SizedBox(height: 6),
                Text(
                  s.message!,
                  key: const Key('safety_banner_message'),
                  style: AppText.label.copyWith(color: c.text),
                ),
              ],
              const SizedBox(height: 10),
              AbsorbPointer(
                absorbing: locked,
                child: Row(
                  children: [
                    if (alerted) ...[
                      small(const Key('safety_banner_ok'), 'Estou bem', busy ? null : ctrl.ok, strong: true),
                      const SizedBox(width: 8),
                    ],
                    small(const Key('safety_extend_15'), '+15 min', busy ? null : () => ctrl.extend(15)),
                    const SizedBox(width: 8),
                    small(const Key('safety_extend_30'), '+30 min', busy ? null : () => ctrl.extend(30)),
                    const SizedBox(width: 8),
                    small(const Key('safety_arrived'), 'Cheguei', busy ? null : () => _arrived(context, ref)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              BigActionButton(
                key: const Key('safety_sos'),
                label: 'Mandar minha posicao agora',
                icon: Icons.sos_rounded,
                variant: BigActionVariant.hold,
                holdHint: 'Segure para avisar seus contatos',
                height: 72,
                onPressed: busy ? null : ctrl.sos,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Aviso grande "Esta tudo bem?" por cima da gravacao enquanto ha checagem.
/// Nao some com o bloqueio de tela: precisa ser respondido.
class SafetyCheckOverlay extends ConsumerStatefulWidget {
  const SafetyCheckOverlay({super.key});

  @override
  ConsumerState<SafetyCheckOverlay> createState() => _SafetyCheckOverlayState();
}

class _SafetyCheckOverlayState extends ConsumerState<SafetyCheckOverlay> {
  StreamSubscription<void>? _tick;
  int? _announced;

  @override
  void initState() {
    super.initState();
    _tick = ref.read(safetyCountdownTickerProvider).ticks(const Duration(seconds: 1)).listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  static String _remaining(int ms) {
    if (ms <= 0) return '0:00';
    final secs = (ms / 1000).ceil();
    return '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(safetySessionProvider);
    final check = s.alerted ? null : s.check; // alertado: a faixa assume
    if (check == null) {
      _announced = null;
      return const SizedBox.shrink();
    }
    if (_announced != check.startedAt) {
      _announced = check.startedAt;
      final view = View.of(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SemanticsService.sendAnnouncement(
          view,
          'Esta tudo bem? Toque em Estou bem.',
          TextDirection.ltr,
          assertiveness: Assertiveness.assertive,
        );
      });
    }
    final c = AppColors.of(context);
    final ctrl = ref.read(safetySessionProvider.notifier);
    final left = check.deadlineMs - ref.read(safetyClockProvider)();
    final reason = switch (check.reason) {
      CheckReason.silence => 'O app ficou um tempo sem mandar sua posicao.',
      CheckReason.stopped => 'Voce nao se move ha um tempo e a gravacao nao esta pausada.',
      CheckReason.eta => 'Passou do horario previsto de chegada.',
      null => 'O Rastro Seguro quer saber se voce esta bem.',
    };
    return Positioned.fill(
      child: Material(
        key: const Key('safety_check'),
        color: c.bg.withValues(alpha: 0.94),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppShape.gutter),
            child: Semantics(
              container: true,
              liveRegion: true,
              label: 'Esta tudo bem? Toque em Estou bem.',
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.help_rounded, size: 64, color: c.extra.fg),
                  const SizedBox(height: 16),
                  Text(
                    'Esta tudo bem?',
                    textAlign: TextAlign.center,
                    style: AppText.screenTitle.copyWith(color: c.text),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    reason,
                    textAlign: TextAlign.center,
                    style: AppText.body.copyWith(color: c.textMuted),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _remaining(left),
                    key: const Key('safety_check_countdown'),
                    textAlign: TextAlign.center,
                    style: AppText.metricL.copyWith(color: c.extra.fg),
                  ),
                  Text(
                    'Sem resposta, seus contatos sao avisados.',
                    textAlign: TextAlign.center,
                    style: AppText.label.copyWith(color: c.textMuted),
                  ),
                  if (s.message != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      s.message!,
                      textAlign: TextAlign.center,
                      style: AppText.body.copyWith(color: c.danger),
                    ),
                  ],
                  const SizedBox(height: 28),
                  BigActionButton(
                    key: const Key('safety_check_ok'),
                    label: 'Estou bem',
                    icon: Icons.check_rounded,
                    height: 80,
                    onPressed: s.busy ? null : ctrl.ok,
                  ),
                  const SizedBox(height: 12),
                  BigActionButton(
                    key: const Key('safety_check_extend'),
                    label: 'Estender 15 min',
                    icon: Icons.more_time_rounded,
                    variant: BigActionVariant.role,
                    role: c.ciano,
                    height: 64,
                    onPressed: s.busy ? null : () => ctrl.extend(15),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mensagem do Iniciar quando o Rastro Seguro nao ligou (a gravacao segue).
String? safetyBeginMessage(SafetyBeginResult r) => switch (r) {
  SafetyBeginResult.started => null,
  SafetyBeginResult.signedOut => 'Rastro Seguro desligado: entre na sua conta. A gravacao segue normalmente.',
  SafetyBeginResult.offline => 'Sem rede: gravando sem Rastro Seguro. A gravacao segue normalmente.',
  SafetyBeginResult.invalidEta =>
    'O horario de chegada precisa ficar entre 5 minutos e 12 horas. Gravando sem Rastro Seguro.',
  SafetyBeginResult.rejected => 'O Rastro Seguro nao pode ser ligado (confira os contatos). Gravando sem ele.',
  SafetyBeginResult.otherDevice => 'Ja ha um Rastro Seguro ativo em outro aparelho. Gravando sem Rastro Seguro.',
  SafetyBeginResult.cancelled => null,
};
