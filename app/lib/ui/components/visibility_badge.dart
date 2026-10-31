// Selo discreto de quem pode ver a atividade (E2E-05): icone e rotulo em
// textMuted, so quando ela nao e publica. Usado no Detalhe e no cartao.
library;

import 'package:flutter/material.dart';

import '../../persistence/activity_visibility.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Rotulo curto, o mesmo do seletor da tela Salvar.
String visibilityLabel(ActivityVisibility v) => switch (v) {
  ActivityVisibility.onlyMe => 'Só eu',
  ActivityVisibility.followers => 'Seguidores',
  ActivityVisibility.everyone => 'Todos',
};

/// Icone de cada opcao, o mesmo do seletor da tela Salvar.
IconData visibilityIcon(ActivityVisibility v) => switch (v) {
  ActivityVisibility.onlyMe => Icons.lock_rounded,
  ActivityVisibility.followers => Icons.group_rounded,
  ActivityVisibility.everyone => Icons.public_rounded,
};

class VisibilityBadge extends StatelessWidget {
  final ActivityVisibility visibility;
  const VisibilityBadge({super.key, required this.visibility});

  /// Le a coluna `activities.visibility` direto.
  VisibilityBadge.fromDb(String? value, {Key? key})
      : this(key: key, visibility: ActivityVisibility.fromDb(value));

  @override
  Widget build(BuildContext context) {
    // Publica e o caso comum: sem selo, para nao poluir o cartao.
    if (visibility == ActivityVisibility.everyone) return const SizedBox.shrink();
    final c = AppColors.of(context);
    final style = AppText.label.copyWith(color: c.textMuted);
    final label = visibilityLabel(visibility);
    return Semantics(
      label: 'Quem pode ver: $label',
      excludeSemantics: true,
      child: Row(
        key: const Key('visibility_badge'),
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icone na altura do texto, acompanhando a fonte do sistema.
          Icon(
            visibilityIcon(visibility),
            size: MediaQuery.textScalerOf(context).scale(style.fontSize!),
            color: c.textMuted,
          ),
          const SizedBox(width: 4),
          Text(label, style: style, maxLines: 1),
        ],
      ),
    );
  }
}
