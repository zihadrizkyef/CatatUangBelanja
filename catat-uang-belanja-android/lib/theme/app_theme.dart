import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Centralizes fonts (Baloo2 = headings, Nunito = body, doc 2.6) and the
/// pastel light/dark ThemeData (doc 2.3/2.5), so screens use
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
    final isDark = brightness == Brightness.dark;
    final background = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.pink,
      onPrimary: textPrimary,
      secondary: AppColors.lavender,
      onSecondary: textPrimary,
      tertiary: AppColors.mint,
      onTertiary: textPrimary,
      error: AppColors.danger,
      onError: Colors.white,
      surface: surface,
      onSurface: textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      colorScheme: colorScheme,
      fontFamily: bodyFontFamily,
      textTheme: TextTheme(
        headlineMedium: heading(fontSize: 24, color: textPrimary),
        titleLarge: heading(fontSize: 20, color: textPrimary),
        bodyLarge: body(fontSize: 16, color: textPrimary),
        bodyMedium: body(fontSize: 14, color: textSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        titleTextStyle: heading(fontSize: 20, color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.pink,
        foregroundColor: Colors.white,
      ),
    );
  }
}
