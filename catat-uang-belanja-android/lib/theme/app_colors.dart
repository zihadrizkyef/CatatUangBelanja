import 'package:flutter/material.dart';

/// Palette transcribed from the Claude Design mockups (project "Membuat
/// aplikasi baru"), unified into one canonical set of tokens even where the
/// individual per-screen mockups diverged slightly (e.g. `borderStrong`).
class AppColors {
  AppColors._();

  // Brightness-independent accents.
  static const Color accent = Color(0xFFE8637C); // headers, active nav, FAB
  static const Color gold = Color(0xFFD19A3D); // income / positive amounts
  static const Color peach = Color(0xFFE58A3D); // expense accent
  static const Color okBar = Color(0xFF7FA88A); // healthy budget bar / "hemat"
  static const Color warningBar = Color(0xFFE8A945); // near-limit budget bar
  static const Color dangerBar = Color(0xFFC0455C); // over-limit budget bar

  // Donut/legend cycle (Rangkuman/SummaryScreen breakdown chart).
  static const List<Color> legend = [
    Color(0xFFE8637C),
    Color(0xFFE8935D),
    Color(0xFF9B8FBD),
    Color(0xFFD4B84A),
    Color(0xFF7FA88A),
  ];

  // Light theme tokens.
  static const Color lightPageBg = Color(0xFFF3ECE6);
  static const Color lightScreenBg = Color(0xFFFFF8F2);
  static const Color lightCardBg = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF3A2C2E);
  static const Color lightTextSecondary = Color(0xFF8A7570);
  static const Color lightBorder = Color(0xFFF3ECE6);
  static const Color lightBorderStrong = Color(0xFFC9A98A);
  static const Color lightChipNeutral = Color(0xFFF3ECE6);
  static const Color lightChipKey = Color(0xFFFDF6F1);
  static const Color lightWarningBg = Color(0xFFFCE0E1);
  static const Color lightWarningText = Color(0xFFB04961);
  static const Color lightSafeBg = Color(0xFFEAF3EC);
  static const Color lightNavBg = Color(0xFFFFFFFF);
  static const Color lightToastBg = Color(0xFF3A2C2E);
  static const Color lightToastText = Color(0xFFFFFFFF);
  static const Color lightOverlay = Color(0x733A2C2E); // rgba(58,44,46,0.45)
  static const Color lightSwitchOff = Color(0xFFE4D6CB);

  // Dark theme tokens.
  static const Color darkPageBg = Color(0xFF14100E);
  static const Color darkScreenBg = Color(0xFF1D1613);
  static const Color darkCardBg = Color(0xFF28201D);
  static const Color darkTextPrimary = Color(0xFFF3E9E4);
  static const Color darkTextSecondary = Color(0xFFB29A92);
  static const Color darkBorder = Color(0xFF392E2A);
  static const Color darkBorderStrong = Color(0xFF6B5850);
  static const Color darkChipNeutral = Color(0xFF332925);
  static const Color darkChipKey = Color(0xFF2E2622);
  static const Color darkWarningBg = Color(0xFF3D232A);
  static const Color darkWarningText = Color(0xFFF0899C);
  static const Color darkSafeBg = Color(0xFF1C2A21);
  static const Color darkNavBg = Color(0xFF221A18);
  static const Color darkToastBg = Color(0xFFF3E9E4);
  static const Color darkToastText = Color(0xFF1D1613);
  static const Color darkOverlay = Color(0x99000000); // rgba(0,0,0,0.6)
  static const Color darkSwitchOff = Color(0xFF4A3B35);
}
