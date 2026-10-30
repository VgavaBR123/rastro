// Fechamento gentil (F04): seletores da tela Salvar. Esforco percebido de 1 a
// 10 (duas linhas de 5, rotulo da faixa embaixo) e humor (5 opcoes com icone e
// texto). Os dois sao opcionais: tocar de novo na escolha desmarca.
library;

import 'package:flutter/material.dart';

import '../../closing/domain/effort.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// Icone de cada humor (do mais feliz ao mais pesado).
IconData moodIcon(Mood m) => switch (m) {
  Mood.great => Icons.sentiment_very_satisfied_rounded,
  Mood.good => Icons.sentiment_satisfied_rounded,
  Mood.ok => Icons.sentiment_neutral_rounded,
  Mood.tired => Icons.sentiment_dissatisfied_rounded,
  Mood.awful => Icons.sentiment_very_dissatisfied_rounded,
};

/// Texto "7 - Forte".
String rpeText(int rpe) => '$rpe - ${rpeLabel(rpe)}';

/// Altura dos botoes dos seletores (alvo >= 44 dp).
const double kEffortTarget = 48;

class RpePicker extends StatelessWidget {
  final int? selected;
  final ValueChanged<int?>? onChanged;

  const RpePicker({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final role = c.extra;
    Widget cell(int v) {
      final on = v == selected;
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Semantics(
            button: true,
            selected: on,
            label: 'Esforco ${rpeText(v)}',
            excludeSemantics: true,
            child: Material(
              color: on ? role.tint : c.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppShape.tile),
                side: BorderSide(color: on ? role.fill : c.line),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: Key('rpe_$v'),
                onTap: onChanged == null ? null : () => onChanged!(on ? null : v),
                child: SizedBox(
                  height: kEffortTarget,
                  child: Center(
                    child: Text(
                      '$v',
                      style: AppText.metricS.copyWith(color: on ? role.fg : c.text),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final s = selected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [for (var v = 1; v <= 5; v++) cell(v)]),
        const SizedBox(height: 6),
        Row(children: [for (var v = 6; v <= 10; v++) cell(v)]),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
          child: Text(
            s == null ? '1-2 leve, 5-6 moderado, 9-10 maximo' : rpeText(s),
            key: const Key('rpe_label'),
            style: AppText.label.copyWith(color: s == null ? c.textMuted : role.fg),
          ),
        ),
      ],
    );
  }
}

class MoodPicker extends StatelessWidget {
  final Mood? selected;
  final ValueChanged<Mood?>? onChanged;

  const MoodPicker({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final role = c.ciano;
    return Row(
      children: [
        for (final m in Mood.values)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Semantics(
                button: true,
                selected: m == selected,
                child: Material(
                  color: m == selected ? role.tint : c.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppShape.tile),
                    side: BorderSide(color: m == selected ? role.fill : c.line),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: Key('mood_${m.dbValue}'),
                    onTap: onChanged == null
                        ? null
                        : () => onChanged!(m == selected ? null : m),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 64),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              moodIcon(m),
                              size: 24,
                              color: m == selected ? role.fg : c.textMuted,
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                m.label,
                                maxLines: 1,
                                style: AppText.label.copyWith(
                                  color: m == selected ? role.fg : c.text,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
