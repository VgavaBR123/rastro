// Tokens de cor do design system (relatorio 11). Nenhuma tela escreve cor
// literal: tudo sai daqui, via `AppColors.of(context)`.
library;

import 'package:flutter/material.dart';

import '../../recording/domain/recording_models.dart';

/// Cor de uma funcao (distancia, tempo, pace...): [fill] para graficos e
/// preenchimentos, [fg] para texto e icone no tema atual, [tint] para fundo de
/// chips, pilulas e blocos de metrica.
@immutable
class RoleColors {
  final Color fill;
  final Color fg;
  final Color tint;
  const RoleColors({required this.fill, required this.fg, required this.tint});

  static RoleColors lerp(RoleColors a, RoleColors b, double t) => RoleColors(
        fill: Color.lerp(a.fill, b.fill, t)!,
        fg: Color.lerp(a.fg, b.fg, t)!,
        tint: Color.lerp(a.tint, b.tint, t)!,
      );
}

/// Paleta completa de um tema (escuro ou claro).
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color text;
  final Color textMuted;
  final Color line;
  final Color map;
  final Color mapRoad;
  final Color mapPark;
  final Color danger;
  final Color navBg;
  final Color navLine;
  final Color primary;
  final Color onPrimary;
  final Color primaryText;

  /// Texto sobre uma cor de funcao cheia.
  final Color onFill;

  final RoleColors dist;
  final RoleColors tempo;
  final RoleColors pace;
  final RoleColors subida;
  final RoleColors extra;
  final RoleColors ciano;

  const AppColors({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.text,
    required this.textMuted,
    required this.line,
    required this.map,
    required this.mapRoad,
    required this.mapPark,
    required this.danger,
    required this.navBg,
    required this.navLine,
    required this.primary,
    required this.onPrimary,
    required this.primaryText,
    required this.onFill,
    required this.dist,
    required this.tempo,
    required this.pace,
    required this.subida,
    required this.extra,
    required this.ciano,
  });

  static const AppColors dark = AppColors(
    bg: Color(0xFF0B0D12),
    surface: Color(0xFF161922),
    surface2: Color(0xFF20242F),
    text: Color(0xFFF4F6FA),
    textMuted: Color(0xFFA3ACBB),
    line: Color(0xFF272C38),
    map: Color(0xFF141820),
    mapRoad: Color(0xFF252C38),
    mapPark: Color(0xFF16261F),
    danger: Color(0xFFFF6B70),
    navBg: Color.fromRGBO(22, 25, 34, 0.88),
    navLine: Color.fromRGBO(255, 255, 255, 0.08),
    primary: Color(0xFFC6F432),
    onPrimary: Color(0xFF141A06),
    primaryText: Color(0xFFC6F432),
    onFill: Color(0xFF0B0D12),
    dist: RoleColors(
        fill: Color(0xFFC6F432), fg: Color(0xFFC6F432), tint: Color.fromRGBO(198, 244, 50, 0.14)),
    tempo: RoleColors(
        fill: Color(0xFFFF6B7A), fg: Color(0xFFFF6B7A), tint: Color.fromRGBO(255, 107, 122, 0.14)),
    pace: RoleColors(
        fill: Color(0xFF5B9BFF), fg: Color(0xFF5B9BFF), tint: Color.fromRGBO(91, 155, 255, 0.14)),
    subida: RoleColors(
        fill: Color(0xFFB08CFF), fg: Color(0xFFB08CFF), tint: Color.fromRGBO(176, 140, 255, 0.14)),
    extra: RoleColors(
        fill: Color(0xFFFFC53D), fg: Color(0xFFFFC53D), tint: Color.fromRGBO(255, 197, 61, 0.16)),
    ciano: RoleColors(
        fill: Color(0xFF2EE6D6), fg: Color(0xFF2EE6D6), tint: Color.fromRGBO(46, 230, 214, 0.14)),
  );

  static const AppColors light = AppColors(
    bg: Color(0xFFF4F5F7),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFECEEF2),
    text: Color(0xFF12141A),
    textMuted: Color(0xFF566072),
    line: Color(0xFFDDE1E7),
    map: Color(0xFFE9ECE6),
    mapRoad: Color(0xFFFFFFFF),
    mapPark: Color(0xFFD6E8D3),
    danger: Color(0xFFC8262E),
    navBg: Color.fromRGBO(255, 255, 255, 0.92),
    navLine: Color(0xFFDDE1E7),
    primary: Color(0xFFC6F432),
    onPrimary: Color(0xFF141A06),
    primaryText: Color(0xFF3F6A0A),
    onFill: Color(0xFF0B0D12),
    dist: RoleColors(
        fill: Color(0xFFC6F432), fg: Color(0xFF4D7C0F), tint: Color.fromRGBO(198, 244, 50, 0.14)),
    tempo: RoleColors(
        fill: Color(0xFFFF6B7A), fg: Color(0xFFC42840), tint: Color.fromRGBO(255, 107, 122, 0.14)),
    pace: RoleColors(
        fill: Color(0xFF5B9BFF), fg: Color(0xFF2459E0), tint: Color.fromRGBO(91, 155, 255, 0.14)),
    subida: RoleColors(
        fill: Color(0xFFB08CFF), fg: Color(0xFF6D28D9), tint: Color.fromRGBO(176, 140, 255, 0.14)),
    extra: RoleColors(
        fill: Color(0xFFFFC53D), fg: Color(0xFF9A6700), tint: Color.fromRGBO(255, 197, 61, 0.16)),
    ciano: RoleColors(
        fill: Color(0xFF2EE6D6), fg: Color(0xFF0E7C76), tint: Color.fromRGBO(46, 230, 214, 0.14)),
  );

  /// Ordem do anel multicolorido (botao Gravar, avatar), fechando no inicio.
  List<Color> get ringColors => [
        dist.fill,
        ciano.fill,
        pace.fill,
        subida.fill,
        tempo.fill,
        extra.fill,
        dist.fill,
      ];

  /// Cor fixa de cada esporte: Corrida = tempo, Pedal = pace, Caminhada = dist.
  RoleColors sport(ActivityType type) => switch (type) {
        ActivityType.run => tempo,
        ActivityType.ride => pace,
        ActivityType.walk => dist,
      };

  /// Paleta do tema atual. Sem a extensao (testes com MaterialApp cru), cai
  /// na paleta do brilho do tema.
  static AppColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AppColors>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  @override
  AppColors copyWith({
    Color? bg,
    Color? surface,
    Color? surface2,
    Color? text,
    Color? textMuted,
    Color? line,
    Color? map,
    Color? mapRoad,
    Color? mapPark,
    Color? danger,
    Color? navBg,
    Color? navLine,
    Color? primary,
    Color? onPrimary,
    Color? primaryText,
    Color? onFill,
    RoleColors? dist,
    RoleColors? tempo,
    RoleColors? pace,
    RoleColors? subida,
    RoleColors? extra,
    RoleColors? ciano,
  }) =>
      AppColors(
        bg: bg ?? this.bg,
        surface: surface ?? this.surface,
        surface2: surface2 ?? this.surface2,
        text: text ?? this.text,
        textMuted: textMuted ?? this.textMuted,
        line: line ?? this.line,
        map: map ?? this.map,
        mapRoad: mapRoad ?? this.mapRoad,
        mapPark: mapPark ?? this.mapPark,
        danger: danger ?? this.danger,
        navBg: navBg ?? this.navBg,
        navLine: navLine ?? this.navLine,
        primary: primary ?? this.primary,
        onPrimary: onPrimary ?? this.onPrimary,
        primaryText: primaryText ?? this.primaryText,
        onFill: onFill ?? this.onFill,
        dist: dist ?? this.dist,
        tempo: tempo ?? this.tempo,
        pace: pace ?? this.pace,
        subida: subida ?? this.subida,
        extra: extra ?? this.extra,
        ciano: ciano ?? this.ciano,
      );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      bg: c(bg, other.bg),
      surface: c(surface, other.surface),
      surface2: c(surface2, other.surface2),
      text: c(text, other.text),
      textMuted: c(textMuted, other.textMuted),
      line: c(line, other.line),
      map: c(map, other.map),
      mapRoad: c(mapRoad, other.mapRoad),
      mapPark: c(mapPark, other.mapPark),
      danger: c(danger, other.danger),
      navBg: c(navBg, other.navBg),
      navLine: c(navLine, other.navLine),
      primary: c(primary, other.primary),
      onPrimary: c(onPrimary, other.onPrimary),
      primaryText: c(primaryText, other.primaryText),
      onFill: c(onFill, other.onFill),
      dist: RoleColors.lerp(dist, other.dist, t),
      tempo: RoleColors.lerp(tempo, other.tempo, t),
      pace: RoleColors.lerp(pace, other.pace, t),
      subida: RoleColors.lerp(subida, other.subida, t),
      extra: RoleColors.lerp(extra, other.extra, t),
      ciano: RoleColors.lerp(ciano, other.ciano, t),
    );
  }
}
