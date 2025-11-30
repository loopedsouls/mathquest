import 'package:flutter/material.dart';

/// Application Color Palette
class AppColors {
  // === PRIMARY COLORS - Modern Design System ===
  static const Color primary = Color(0xFF03BC62);
  static const Color primaryDark = Color(0xFF009640);
  static const Color primaryLight = Color(0xFF04CF73);
  static const Color primaryAccent = Color(0xFF01A951);

  // === SECONDARY COLORS ===
  static const Color secondary = Color(0xFF05E284);
  static const Color secondaryDark = Color(0xFF009640);
  static const Color secondaryLight = Color(0xFF04CF73);

  // === STATUS COLORS ===
  static const Color success = Color(0xFF03BC62);
  static const Color error = Color(0xFFE53E3E);
  static const Color warning = Color(0xFFFF8C00);
  static const Color info = Color(0xFF3182CE);

  // === DARK MODE COLORS ===
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2D2D2D);

  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB3B3B3);
  static const Color darkTextHint = Color(0xFF757575);

  static const Color darkBorder = Color(0xFF404040);
  static const Color darkDivider = Color(0xFF404040);

  // === LIGHT MODE COLORS ===
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);

  static const Color lightTextPrimary = Color(0xFF2D3748);
  static const Color lightTextSecondary = Color(0xFF4A5568);
  static const Color lightTextHint = Color(0xFF718096);

  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightDivider = Color(0xFFE2E8F0);

  // === GLASSMORPHISM & ELEVATION COLORS ===
  static Color glassLight = const Color(0xFFFFFFFF).withValues(alpha: 0.8);
  static Color glassDark = const Color(0xFF000000).withValues(alpha: 0.2);
  static Color blurOverlay = const Color(0xFF000000).withValues(alpha: 0.4);

  // === MODERN GRADIENTS ===
  static const List<Color> gradientPrimary = [
    Color(0xFF05E284),
    Color(0xFF009640),
  ];
  static const List<Color> gradientSecondary = [
    Color(0xFF04CF73),
    Color(0xFF01A951),
  ];
  static const List<Color> gradientTertiary = [
    Color(0xFF03BC62),
    Color(0xFF009640),
  ];

  // === NEUTRAL GRADIENTS ===
  static const List<Color> gradientNeutralLight = [
    Color(0xFFF7FAFC),
    Color(0xFFEDF2F7),
  ];
  static const List<Color> gradientNeutralDark = [
    Color(0xFF2D3748),
    Color(0xFF1A202C),
  ];

  // === COMPLEMENTARY COLORS ===
  static const Color accent = Color(0xFF04CF73);
  static const Color highlight = Color(0xFF05E284);
  static const Color overlay = Color(0x80000000);

  // === PERFORMANCE COLORS ===
  static const Color excellent = Color(0xFF03BC62);
  static const Color good = Color(0xFF3182CE);
  static const Color regular = Color(0xFFFF8C00);
  static const Color low = Color(0xFFE53E3E);
  static const Color neutral = Color(0xFF718096);

  // === PERMISSION COLORS ===
  static const Color assignment = Color(0xFF3182CE);
  static const Color grade = Color(0xFF03BC62);
  static const Color submission = Color(0xFF805AD5);
  static const Color profile = Color(0xFFFF8C00);
  static const Color announcement = Color(0xFFE53E3E);

  /// Get color based on severity level
  static Color getSeverityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'ERROR':
        return error;
      case 'WARNING':
        return warning;
      case 'INFO':
        return info;
      case 'SUCCESS':
        return success;
      default:
        return neutral;
    }
  }

  /// Get color based on performance status
  static Color getPerformanceColor(String status) {
    switch (status.toLowerCase()) {
      case 'excelente':
        return excellent;
      case 'bom':
        return good;
      case 'regular':
        return regular;
      case 'baixo':
        return low;
      default:
        return neutral;
    }
  }

  /// Get color based on user type
  static Color getUserTypeColor(String userType) {
    switch (userType.toLowerCase()) {
      case 'admin':
        return error;
      case 'professor':
        return primary;
      case 'gestor':
        return submission;
      case 'aluno':
        return info;
      default:
        return neutral;
    }
  }

  /// Get permission color by category
  static Color getPermissionColor(String category) {
    final categoryLower = category.toLowerCase();
    if (categoryLower.contains('assignment')) return assignment;
    if (categoryLower.contains('grade')) return grade;
    if (categoryLower.contains('submission')) return submission;
    if (categoryLower.contains('profile')) return profile;
    if (categoryLower.contains('announcement')) return announcement;
    return neutral;
  }
}
