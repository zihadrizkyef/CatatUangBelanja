import 'package:flutter/material.dart';

/// Warm pastel palette (doc section 2.3): soft pink, peach, cream, mint,
/// lavender. Dark mode uses warm-tinted darks instead of neutral gray/black
/// so the app still feels friendly, not like a technical/office app.
class AppColors {
  AppColors._();

  // Pastel accents, shared across light and dark mode.
  static const Color pink = Color(0xFFF7C6D9);
  static const Color peach = Color(0xFFFBD8B5);
  static const Color cream = Color(0xFFFDF3E3);
  static const Color mint = Color(0xFFC4EBD9);
  static const Color lavender = Color(0xFFDCD3F0);

  static const Color success = Color(0xFF8FCB9B);
  static const Color warning = Color(0xFFF2B366);
  static const Color danger = Color(0xFFE68C8C);

  // Light theme surfaces.
  static const Color lightBackground = Color(0xFFFFFBF5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF4A3F3A);
  static const Color lightTextSecondary = Color(0xFF8A7B73);

  // Dark theme surfaces: warm charcoal/plum, not neutral gray/black.
  static const Color darkBackground = Color(0xFF2B2430);
  static const Color darkSurface = Color(0xFF3A3038);
  static const Color darkTextPrimary = Color(0xFFF3E9E4);
  static const Color darkTextSecondary = Color(0xFFCBB9C4);
}
