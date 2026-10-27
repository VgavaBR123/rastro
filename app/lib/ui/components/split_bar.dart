// Barra de parcial (relatorio 11, SplitBar): altura 14, raio 7, largura
// proporcional a velocidade entre 55% e 100%. A mais rapida fica em dist, a
// mais lenta em tempo e as demais em pace. O calculo e funcao pura.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Menor e maior largura da barra, como fracao da faixa disponivel.
const double kSplitBarMinFraction = 0.55;
const double kSplitBarMaxFraction = 1.0;

const double kSplitBarHeight = 14;
const double kSplitBarRadius = 7;

/// Papel de uma parcial na comparacao com as outras.
enum SplitRank { fastest, slowest, normal }

/// Largura e papel de uma barra.
@immutable
class SplitBarSpec {
  final double fraction;
  final SplitRank rank;
  const SplitBarSpec(this.fraction, this.rank);

  @override
  bool operator ==(Object other) =>
      other is SplitBarSpec && other.fraction == fraction && other.rank == rank;

  @override
  int get hashCode => Object.hash(fraction, rank);

  @override
  String toString() => 'SplitBarSpec($fraction, $rank)';
}

/// Uma barra por velocidade (m/s). Velocidade invalida (<= 0, NaN) ganha a
/// largura minima e fica fora do ranking. Sem pelo menos duas velocidades
/// diferentes nao ha mais rapida nem mais lenta: todas normais, largura cheia.
/// Empates: todas as empatadas recebem o mesmo papel.
List<SplitBarSpec> splitBarSpecs(List<double> speeds) {
  bool ok(double v) => v.isFinite && v > 0;
  final valid = speeds.where(ok).toList();
  if (valid.isEmpty) {
    return [
      for (final _ in speeds)
        const SplitBarSpec(kSplitBarMinFraction, SplitRank.normal),
    ];
  }
  final lo = valid.reduce((a, b) => a < b ? a : b);
  final hi = valid.reduce((a, b) => a > b ? a : b);
  final span = hi - lo;
  return [
    for (final v in speeds)
      if (!ok(v))
        const SplitBarSpec(kSplitBarMinFraction, SplitRank.normal)
      else if (span <= 0)
        const SplitBarSpec(kSplitBarMaxFraction, SplitRank.normal)
      else
        SplitBarSpec(
          kSplitBarMinFraction +
              (kSplitBarMaxFraction - kSplitBarMinFraction) * (v - lo) / span,
          v == hi
              ? SplitRank.fastest
              : v == lo
              ? SplitRank.slowest
              : SplitRank.normal,
        ),
  ];
}

/// Cor de cada papel no tema atual.
RoleColors splitRankRole(AppColors c, SplitRank rank) => switch (rank) {
  SplitRank.fastest => c.dist,
  SplitRank.slowest => c.tempo,
  SplitRank.normal => c.pace,
};

/// A barra em si: ocupa [SplitBarSpec.fraction] da largura recebida.
class SplitBar extends StatelessWidget {
  final SplitBarSpec spec;
  const SplitBar({super.key, required this.spec});

  @override
  Widget build(BuildContext context) {
    final role = splitRankRole(AppColors.of(context), spec.rank);
    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: spec.fraction.clamp(0.0, 1.0),
        child: Container(
          height: kSplitBarHeight,
          decoration: BoxDecoration(
            color: role.fill,
            borderRadius: BorderRadius.circular(kSplitBarRadius),
          ),
        ),
      ),
    );
  }
}

/// Legenda das cores: mais rapida, mais lenta e demais.
class SplitBarLegend extends StatelessWidget {
  const SplitBarLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    Widget item(SplitRank rank, String text) {
      final role = splitRankRole(c, rank);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: role.fill,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(width: 6),
          Text(text, style: AppText.label.copyWith(color: c.textMuted)),
        ],
      );
    }

    return Wrap(
      key: const Key('splitLegend'),
      spacing: 16,
      runSpacing: 8,
      children: [
        item(SplitRank.fastest, 'Mais rapida'),
        item(SplitRank.slowest, 'Mais lenta'),
        item(SplitRank.normal, 'Demais'),
      ],
    );
  }
}
