// Dica de rotina previsivel (F02), a mesma no Salvar e no Compartilhar.
library;

import 'package:flutter/material.dart';

import '../components/notice_banner.dart';
import '../theme/app_colors.dart';

class RoutineWarningBanner extends StatelessWidget {
  const RoutineWarningBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return NoticeBanner(
      icon: Icons.schedule_rounded,
      title: 'Rotina previsivel',
      message:
          'Suas ultimas atividades comecam no mesmo lugar e no mesmo horario. '
          'Quem as ve pode prever onde voce vai estar. Vale variar o horario, '
          'cortar a rota ou deixar como "So eu".',
      accent: c.extra.fg,
      background: c.extra.tint,
    );
  }
}
