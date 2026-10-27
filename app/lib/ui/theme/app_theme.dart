// ThemeData escuro e claro montados a mao a partir dos tokens (relatorio 11),
// sem `fromSeed`: os widgets Material ja nascem com as cores e formas certas.
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Raios e espacos do design system.
abstract final class AppShape {
  static const double card = 22;
  static const double tile = 16;
  static const double panel = 18;
  static const double nav = 32;
  static const double navActive = 28;

  /// Margem lateral padrao das telas.
  static const double gutter = 16;
}

abstract final class AppTheme {
  static ThemeData get dark => _build(AppColors.dark, Brightness.dark);
  static ThemeData get light => _build(AppColors.light, Brightness.light);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      primaryContainer: c.dist.tint,
      onPrimaryContainer: c.primaryText,
      secondary: c.ciano.fill,
      onSecondary: c.onFill,
      tertiary: c.subida.fill,
      onTertiary: c.onFill,
      error: c.danger,
      onError: brightness == Brightness.dark ? c.onFill : Colors.white,
      surface: c.surface,
      onSurface: c.text,
      onSurfaceVariant: c.textMuted,
      surfaceContainerLowest: c.bg,
      surfaceContainerLow: c.surface,
      surfaceContainer: c.surface,
      surfaceContainerHigh: c.surface2,
      surfaceContainerHighest: c.surface2,
      outline: c.line,
      outlineVariant: c.line,
      inverseSurface: c.text,
      onInverseSurface: c.bg,
      shadow: Colors.black,
      scrim: Colors.black,
    );

    final textTheme = TextTheme(
      headlineMedium: AppText.screenTitle,
      headlineSmall: AppText.screenTitle.copyWith(fontSize: 22),
      titleLarge: AppText.sectionTitle.copyWith(fontSize: 20),
      titleMedium: AppText.sectionTitle,
      titleSmall: AppText.bodyStrong,
      bodyLarge: AppText.body.copyWith(fontSize: 15),
      bodyMedium: AppText.body,
      bodySmall: AppText.label.copyWith(fontWeight: FontWeight.w500),
      labelLarge: AppText.bodyStrong,
      labelMedium: AppText.label,
      labelSmall: AppText.navLabel,
    ).apply(bodyColor: c.text, displayColor: c.text);

    const pill = StadiumBorder();
    const buttonSize = Size(64, 48);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: AppFonts.text,
      textTheme: textTheme,
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.bg,
      dividerColor: c.line,
      extensions: [c],
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        foregroundColor: c.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppText.sectionTitle.copyWith(fontSize: 20, color: c.text),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppShape.card),
          side: BorderSide(color: c.line),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          disabledBackgroundColor: c.surface2,
          disabledForegroundColor: c.textMuted,
          minimumSize: buttonSize,
          shape: pill,
          textStyle: AppText.bodyStrong.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.surface2,
          foregroundColor: c.text,
          elevation: 0,
          minimumSize: buttonSize,
          shape: pill,
          textStyle: AppText.bodyStrong,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.text,
          side: BorderSide(color: c.line),
          minimumSize: buttonSize,
          shape: pill,
          textStyle: AppText.bodyStrong,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.ciano.fg,
          minimumSize: const Size(44, 44),
          shape: pill,
          textStyle: AppText.bodyStrong,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: c.text,
          minimumSize: const Size(44, 44),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        labelStyle: AppText.body.copyWith(color: c.textMuted),
        hintStyle: AppText.body.copyWith(color: c.textMuted),
        helperStyle: AppText.label.copyWith(color: c.textMuted),
        errorStyle: AppText.label.copyWith(color: c.danger),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppShape.tile),
          borderSide: BorderSide(color: c.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppShape.tile),
          borderSide: BorderSide(color: c.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppShape.tile),
          borderSide: BorderSide(color: c.ciano.fill, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppShape.tile),
          borderSide: BorderSide(color: c.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppShape.tile),
          borderSide: BorderSide(color: c.danger, width: 1.5),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: c.textMuted,
        textColor: c.text,
        titleTextStyle: AppText.bodyStrong.copyWith(color: c.text),
        subtitleTextStyle: AppText.label.copyWith(color: c.textMuted, fontWeight: FontWeight.w500),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppShape.gutter),
        minVerticalPadding: 10,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.onPrimary : c.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.primary : c.surface2,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.transparent : c.line,
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.primaryText : c.textMuted,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.primary : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(c.onPrimary),
        side: BorderSide(color: c.textMuted, width: 1.5),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: c.surface,
          foregroundColor: c.textMuted,
          selectedBackgroundColor: c.dist.tint,
          selectedForegroundColor: c.primaryText,
          side: BorderSide(color: c.line),
          minimumSize: const Size(44, 44),
          textStyle: AppText.bodyStrong,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surface2,
        side: BorderSide.none,
        shape: pill,
        labelStyle: AppText.label.copyWith(color: c.text),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppShape.card)),
        titleTextStyle: AppText.sectionTitle.copyWith(fontSize: 20, color: c.text),
        contentTextStyle: AppText.body.copyWith(color: c.textMuted),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: c.line,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppShape.card)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.surface2,
        contentTextStyle: AppText.body.copyWith(color: c.text),
        actionTextColor: c.primaryText,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppShape.tile)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primary,
        linearTrackColor: c.surface2,
        circularTrackColor: Colors.transparent,
      ),
      badgeTheme: BadgeThemeData(backgroundColor: c.tempo.fill, textColor: c.onFill),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: AppText.label.copyWith(color: c.text),
      ),
    );
  }
}
