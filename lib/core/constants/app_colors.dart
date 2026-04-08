import 'package:flutter/material.dart';

class AppColors {
  // Dark Mode
  static const Color darkBg = Color(0xFF0E0E14);
  static const Color darkSurface = Color(0xFF1A1A26);
  static const Color darkSurfaceElevated = Color(0xFF22223A);
  static const Color darkBorder = Color(0xFF2E2E48);

  // Light Mode
  static const Color lightBg = Color(0xFFF4F3FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE8E7F0);

  // Accents (shared)
  static const Color primary = Color(0xFF7C6EF5);
  static const Color primaryLight = Color(0xFF9D92F8);
  static const Color primaryDark = Color(0xFF5A4ED1);
  static const Color secondary = Color(0xFF36D7A0);
  static const Color secondaryLight = Color(0xFF5FEAB9);
  static const Color warning = Color(0xFFF5885A);
  static const Color warningLight = Color(0xFFFFA07A);
  static const Color danger = Color(0xFFEF5350);
  static const Color info = Color(0xFF42A5F5);

  // Text Dark
  static const Color darkTextPrimary = Color(0xFFF0EFF8);
  static const Color darkTextSecondary = Color(0xFF9896B0);
  static const Color darkTextHint = Color(0xFF5E5C78);

  // Text Light
  static const Color lightTextPrimary = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Color(0xFF7B7A90);
  static const Color lightTextHint = Color(0xFFB0AFBF);

  // Priority colors
  static const Color priorityHigh = Color(0xFFEF5350);
  static const Color priorityMedium = Color(0xFFFFA726);
  static const Color priorityLow = Color(0xFF66BB6A);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7C6EF5), Color(0xFF36D7A0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF7C6EF5), Color(0xFF5A4ED1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF36D7A0), Color(0xFF1DB77D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFF5885A), Color(0xFFD4603A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
