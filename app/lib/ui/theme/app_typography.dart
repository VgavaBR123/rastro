// Tipografia do design system (relatorio 11): Inter para texto e Barlow Semi
// Condensed com algarismos tabulares para numeros. Os estilos nao fixam cor;
// a cor vem do contexto ou de `.copyWith(color: ...)`.
library;

import 'package:flutter/painting.dart';

abstract final class AppFonts {
  static const String text = 'Inter';
  static const String numbers = 'BarlowSemiCondensed';
}

abstract final class AppText {
  // A Inter vem como fonte variavel: o peso precisa ir tambem no eixo wght.
  static TextStyle _inter(double size, int weight, {double? letterSpacing}) => TextStyle(
        fontFamily: AppFonts.text,
        fontSize: size,
        fontWeight: FontWeight.values[(weight ~/ 100) - 1],
        fontVariations: [FontVariation.weight(weight.toDouble())],
        letterSpacing: letterSpacing,
      );

  static TextStyle _metric(double size, {FontWeight weight = FontWeight.w700}) => TextStyle(
        fontFamily: AppFonts.numbers,
        fontSize: size,
        fontWeight: weight,
        height: 1.0,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Tempo e distancia na tela Gravando.
  static final TextStyle metricXL = _metric(96);

  /// Pace na gravacao.
  static final TextStyle metricL = _metric(44);

  /// Resumo da semana, grade do detalhe, totais do perfil.
  static final TextStyle metricM = _metric(30);

  /// Linha de metricas do cartao, parciais, recordes.
  static final TextStyle metricS = _metric(20);

  static final TextStyle screenTitle = _inter(27, 700, letterSpacing: -0.54);
  static final TextStyle sectionTitle = _inter(17.5, 700);
  static final TextStyle body = _inter(14.5, 500);
  static final TextStyle bodyStrong = _inter(14.5, 600);
  static final TextStyle label = _inter(12.5, 600);
  static final TextStyle navLabel = _inter(10.5, 600);
  static final TextStyle navLabelActive = _inter(10.5, 700);

  /// Texto dos BigActionButton.
  static final TextStyle action = _inter(19, 800);
}
