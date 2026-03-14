import 'package:flutter/material.dart';

/// App-wide reusable decorations
class AppDecorations {
  AppDecorations._();

  // ==================== Glassmorphism ====================

  /// Glass card decoration with blur effect
  static BoxDecoration glassCard({
    Color? color,
    double borderRadius = 20,
    double opacity = 0.1,
    double borderOpacity = 0.2,
  }) {
    return BoxDecoration(
      // ignore: deprecated_member_use
      color: (color ?? Colors.white).withOpacity(opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        // ignore: deprecated_member_use
        color: Colors.white.withOpacity(borderOpacity),
        width: 1.5,
      ),
    );
  }

  /// Dark glass card decoration
  static BoxDecoration darkGlassCard({
    double borderRadius = 20,
    double opacity = 0.2, // Slightly more opaque for better contrast
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.12),
        width: 1.5,
      ),
    );
  }

  // ==================== Gradient Containers ====================

  /// Primary gradient background
  static BoxDecoration primaryGradientBg({double borderRadius = 0}) {
    return BoxDecoration(
      borderRadius:
          borderRadius > 0 ? BorderRadius.circular(borderRadius) : null,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF006A4E), Color(0xFF1B8B6A)],
      ),
    );
  }

  /// Danger gradient for SOS
  static BoxDecoration dangerGradientBg({double borderRadius = 0}) {
    return BoxDecoration(
      borderRadius:
          borderRadius > 0 ? BorderRadius.circular(borderRadius) : null,
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFD32F2F), Color(0xFFF44336)],
      ),
    );
  }

  /// Subtle background gradient (light mode)
  static BoxDecoration subtleGradientLight() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE8F5F0), Color(0xFFF5F5F5)],
        stops: [0.0, 0.5],
      ),
    );
  }

  /// Subtle background gradient (dark mode)
  static BoxDecoration subtleGradientDark() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0F241F), // Deep Forest Green top
          Color(0xFF0A1210), // Midnight Green bottom
        ],
        stops: [0.0, 0.7],
      ),
    );
  }

  // ==================== Shadows ====================

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          // ignore: deprecated_member_use
          color: Colors.black.withOpacity(0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get mediumShadow => [
        BoxShadow(
          // ignore: deprecated_member_use
          color: Colors.black.withOpacity(0.1),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get heavyShadow => [
        BoxShadow(
          // ignore: deprecated_member_use
          color: Colors.black.withOpacity(0.15),
          blurRadius: 30,
          offset: const Offset(0, 15),
        ),
      ];

  static List<BoxShadow> coloredShadow(Color color, {double opacity = 0.3}) => [
        BoxShadow(
          // ignore: deprecated_member_use
          color: color.withOpacity(opacity),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  // ==================== Card Decoration ====================

  static BoxDecoration cardDecoration({
    required BuildContext context,
    double borderRadius = 16,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? const Color(0xFF141F1C) : Colors.white,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.05),
      ),
      boxShadow: isDark ? [] : softShadow,
    );
  }

  /// Elevated card with more shadow
  static BoxDecoration elevatedCard({
    required BuildContext context,
    double borderRadius = 16,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? const Color(0xFF1B2925) : Colors.white,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.black.withValues(alpha: 0.05),
      ),
      boxShadow: isDark
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ]
          : mediumShadow,
    );
  }
}
