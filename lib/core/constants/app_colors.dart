import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Core palette
  static const Color background = Color(0xFF1A1A1A);
  static const Color surface = Color(0xFF2C2C2C);
  static const Color surfaceVariant = Color(0xFF383838);
  static const Color accent = Color(0xFFF5C518);
  static const Color accentDark = Color(0xFFD4A800);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFAAAAAA);
  static const Color textDisabled = Color(0xFF666666);

  // Semantic
  static const Color error = Color(0xFFFF4444);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF29B6F6);

  // Status badges
  static const Color statusPending = Color(0xFFF5C518);
  static const Color statusSent = Color(0xFF4CAF50);
  static const Color statusCancelled = Color(0xFF666666);

  // UI elements
  static const Color divider = Color(0xFF3A3A3A);
  static const Color cardBorder = Color(0xFF404040);
  static const Color shimmer = Color(0xFF3D3D3D);
  static const Color shimmerHighlight = Color(0xFF4D4D4D);

  // Gradient stops
  static const List<Color> accentGradient = [Color(0xFFF5C518), Color(0xFFE8A500)];
  static const List<Color> backgroundGradient = [Color(0xFF1A1A1A), Color(0xFF0D0D0D)];
}
