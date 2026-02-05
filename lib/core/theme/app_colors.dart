import 'package:flutter/material.dart';

/// Bangladesh-inspired color palette
/// Primary: Bangladesh Green (#006A4E)
/// Secondary: Red from flag (#DC143C)
/// Accent: Warm Orange for positive actions
class AppColors {
  AppColors._();

  // Primary Colors (Bangladesh Green)
  static const Color primary = Color(0xFF006A4E);
  static const Color primaryLight = Color(0xFF1B8B6A);
  static const Color primaryDark = Color(0xFF004D38);
  static const Color primaryContainer = Color(0xFFE8F5F0);

  // Secondary Colors (Bangladesh Red)
  static const Color secondary = Color(0xFFDC143C);
  static const Color secondaryLight = Color(0xFFFF4458);
  static const Color secondaryDark = Color(0xFFB01030);
  static const Color secondaryContainer = Color(0xFFFFE5E9);

  // Accent Colors
  static const Color accent = Color(0xFFFFA500);
  static const Color accentLight = Color(0xFFFFB733);
  static const Color accentDark = Color(0xFFE69500);

  // Semantic Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFF81C784);
  static const Color successDark = Color(0xFF388E3C);

  static const Color warning = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFB74D);
  static const Color warningDark = Color(0xFFF57C00);

  static const Color error = Color(0xFFF44336);
  static const Color errorLight = Color(0xFFE57373);
  static const Color errorDark = Color(0xFFD32F2F);
  static const Color danger = error; // Alias for consistency with some UI code
  static const Color dangerLight = errorLight;
  static const Color dangerDark = errorDark;

  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFF64B5F6);
  static const Color infoDark = Color(0xFF1976D2);

  // Neutral Colors (Light Mode)
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF8F9FA);
  
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textTertiary = Color(0xFF9E9E9E);
  static const Color textDisabled = Color(0xFFBDBDBD);

  // Dark Mode Colors
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceVariantDark = Color(0xFF2C2C2C);
  
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB3B3B3);
  static const Color textTertiaryDark = Color(0xFF808080);

  // Borders & Dividers
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderDark = Color(0xFF424242);
  static const Color divider = Color(0xFFEEEEEE);
  static const Color dividerDark = Color(0xFF373737);

  // Special Purpose Colors
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
  
  static const Color overlay = Color(0x66000000);
  static const Color scrim = Color(0x99000000);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Status-based gradients for check-in button
  static LinearGradient getStatusGradient(int hoursLeft) {
    if (hoursLeft > 24) {
      return const LinearGradient(
        colors: [success, successLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (hoursLeft > 6) {
      return const LinearGradient(
        colors: [warning, warningLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      return const LinearGradient(
        colors: [error, errorLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }

  // SOS Button Colors
  static const Color sosButton = Color(0xFFD32F2F);
  static const LinearGradient sosGradient = LinearGradient(
    colors: [Color(0xFFD32F2F), Color(0xFFE57373)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Check-in Button Safe State
  static const LinearGradient safeGradient = LinearGradient(
    colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}