import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Centralizes fonts (Baloo2 = headings, Nunito = body, doc 2.6) and the
/// mockup-derived light/dark ThemeData, so screens use
/// AppTheme.heading(...)/AppTheme.body(...) instead of ad-hoc TextStyles.
class AppTheme {
  AppTheme._();

  static const String headingFontFamily = 'Baloo2';
  static const String bodyFontFamily = 'Nunito';

  static TextStyle heading({
    double fontSize = 22,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: headingFontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  static TextStyle body({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: bodyFontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  static ThemeData get light => _buildTheme(brightness: Brightness.light);

  static ThemeData get dark => _buildTheme(brightness: Brightness.dark);

  static ThemeData _buildTheme({required Brightness brightness}) {
    final palette = AppPalette.forBrightness(brightness);

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.accent,
      onPrimary: Colors.white,
      secondary: AppColors.gold,
      onSecondary: Colors.white,
      tertiary: AppColors.peach,
      onTertiary: Colors.white,
      error: AppColors.dangerBar,
      onError: Colors.white,
      surface: palette.cardBg,
      onSurface: palette.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: palette.screenBg,
      colorScheme: colorScheme,
      fontFamily: bodyFontFamily,
      textTheme: TextTheme(
        headlineMedium: heading(fontSize: 24, color: palette.textPrimary),
        titleLarge: heading(fontSize: 20, color: palette.textPrimary),
        bodyLarge: body(fontSize: 16, color: palette.textPrimary),
        bodyMedium: body(fontSize: 14, color: palette.textSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: heading(fontSize: 20, color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: palette.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
      ),
    );
  }
}

/// Resolved theme tokens for the current brightness — the single place
/// screens read mockup colors from, instead of branching on
/// `Theme.of(context).brightness` themselves everywhere.
class AppPalette {
  const AppPalette({
    required this.pageBg,
    required this.screenBg,
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.borderStrong,
    required this.chipNeutral,
    required this.chipKey,
    required this.warningBg,
    required this.warningText,
    required this.safeBg,
    required this.navBg,
    required this.toastBg,
    required this.toastText,
    required this.overlay,
    required this.switchOff,
  });

  final Color pageBg;
  final Color screenBg;
  final Color cardBg;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color borderStrong;
  final Color chipNeutral;
  final Color chipKey;
  final Color warningBg;
  final Color warningText;
  final Color safeBg;
  final Color navBg;
  final Color toastBg;
  final Color toastText;
  final Color overlay;
  final Color switchOff;

  static const AppPalette light = AppPalette(
    pageBg: AppColors.lightPageBg,
    screenBg: AppColors.lightScreenBg,
    cardBg: AppColors.lightCardBg,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    border: AppColors.lightBorder,
    borderStrong: AppColors.lightBorderStrong,
    chipNeutral: AppColors.lightChipNeutral,
    chipKey: AppColors.lightChipKey,
    warningBg: AppColors.lightWarningBg,
    warningText: AppColors.lightWarningText,
    safeBg: AppColors.lightSafeBg,
    navBg: AppColors.lightNavBg,
    toastBg: AppColors.lightToastBg,
    toastText: AppColors.lightToastText,
    overlay: AppColors.lightOverlay,
    switchOff: AppColors.lightSwitchOff,
  );

  static const AppPalette dark = AppPalette(
    pageBg: AppColors.darkPageBg,
    screenBg: AppColors.darkScreenBg,
    cardBg: AppColors.darkCardBg,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    border: AppColors.darkBorder,
    borderStrong: AppColors.darkBorderStrong,
    chipNeutral: AppColors.darkChipNeutral,
    chipKey: AppColors.darkChipKey,
    warningBg: AppColors.darkWarningBg,
    warningText: AppColors.darkWarningText,
    safeBg: AppColors.darkSafeBg,
    navBg: AppColors.darkNavBg,
    toastBg: AppColors.darkToastBg,
    toastText: AppColors.darkToastText,
    overlay: AppColors.darkOverlay,
    switchOff: AppColors.darkSwitchOff,
  );

  factory AppPalette.forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;

  factory AppPalette.of(BuildContext context) =>
      AppPalette.forBrightness(Theme.of(context).brightness);
}
