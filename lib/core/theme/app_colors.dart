import 'package:flutter/material.dart';

/// Paleta de colores de la aplicacion My Gym App.
/// Colores oscuros y energeticos para ambiente de gimnasio.
abstract class AppColors {
  // Primary - Naranja energetico
  static const Color primary = Color(0xFFFF6B35);
  static const Color primaryLight = Color(0xFFFF8F5E);
  static const Color primaryDark = Color(0xFFE55A2B);

  // Secondary - Azul oscuro
  static const Color secondary = Color(0xFF1A237E);
  static const Color secondaryLight = Color(0xFF534BAE);
  static const Color secondaryDark = Color(0xFF000051);

  // Background
  static const Color background = Color(0xFF121212);
  static const Color backgroundLight = Color(0xFF1E1E1E);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color surfaceVariant = Color(0xFF2C2C2C);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textHint = Color(0xFF757575);
  static const Color textDisabled = Color(0xFF505050);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFF81C784);
  static const Color warning = Color(0xFFFFC107);
  static const Color warningLight = Color(0xFFFFD54F);
  static const Color error = Color(0xFFF44336);
  static const Color errorLight = Color(0xFFE57373);
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFF64B5F6);

  // Muscle group colors (para badges/chips)
  static const Color muscleChest = Color(0xFFE53935);
  static const Color muscleBack = Color(0xFF1E88E5);
  static const Color muscleLegs = Color(0xFF43A047);
  static const Color muscleShoulders = Color(0xFFFB8C00);
  static const Color muscleArms = Color(0xFF8E24AA);
  static const Color muscleCore = Color(0xFF00ACC1);

  // Dividers & borders
  static const Color divider = Color(0xFF2C2C2C);
  static const Color border = Color(0xFF3C3C3C);
  static const Color borderFocused = Color(0xFFFF6B35);

  // Card
  static const Color cardBackground = Color(0xFF1E1E1E);
  static const Color cardElevated = Color(0xFF252525);

  // Shimmer (loading placeholders)
  static const Color shimmerBase = Color(0xFF2C2C2C);
  static const Color shimmerHighlight = Color(0xFF3C3C3C);
}
