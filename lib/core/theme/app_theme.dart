import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  // Light Theme
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        
        // Color Scheme
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          primaryContainer: AppColors.primaryContainer,
          onPrimaryContainer: AppColors.primaryDark,
          
          secondary: AppColors.secondary,
          onSecondary: Colors.white,
          secondaryContainer: AppColors.secondaryContainer,
          onSecondaryContainer: AppColors.secondaryDark,
          
          tertiary: AppColors.accent,
          onTertiary: Colors.white,
          
          error: AppColors.error,
          onError: Colors.white,
          errorContainer: AppColors.errorLight,
          onErrorContainer: AppColors.errorDark,
          
          background: AppColors.background,
          onBackground: AppColors.textPrimary,
          
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          surfaceVariant: AppColors.surfaceVariant,
          onSurfaceVariant: AppColors.textSecondary,
          
          outline: AppColors.border,
          outlineVariant: AppColors.divider,
          
          shadow: Colors.black26,
          scrim: AppColors.scrim,
        ),

        // Typography
        textTheme: TextTheme(
          displayLarge: AppTextStyles.displayLarge(),
          displayMedium: AppTextStyles.displayMedium(),
          displaySmall: AppTextStyles.displaySmall(),
          
          headlineLarge: AppTextStyles.headlineLarge(),
          headlineMedium: AppTextStyles.headlineMedium(),
          headlineSmall: AppTextStyles.headlineSmall(),
          
          titleLarge: AppTextStyles.titleLarge(),
          titleMedium: AppTextStyles.titleMedium(),
          titleSmall: AppTextStyles.titleSmall(),
          
          bodyLarge: AppTextStyles.bodyLarge(),
          bodyMedium: AppTextStyles.bodyMedium(),
          bodySmall: AppTextStyles.bodySmall(),
          
          labelLarge: AppTextStyles.labelLarge(),
          labelMedium: AppTextStyles.labelMedium(),
          labelSmall: AppTextStyles.labelSmall(),
        ),

        // AppBar Theme
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: AppTextStyles.titleLarge(
            fontWeight: FontWeight.bold,
          ),
          iconTheme: const IconThemeData(
            color: AppColors.textPrimary,
            size: 24,
          ),
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),

        // Card Theme
        cardTheme: CardThemeData(
          elevation: 2,
          color: AppColors.surface,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),

        // Elevated Button Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: AppTextStyles.buttonMedium,
          ),
        ),

        // Outlined Button Theme
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: AppTextStyles.buttonMedium,
          ),
        ),

        // Text Button Theme
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            textStyle: AppTextStyles.buttonMedium,
          ),
        ),

        // Input Decoration Theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceVariant,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error, width: 2),
          ),
          labelStyle: AppTextStyles.bodyMedium(
            color: AppColors.textSecondary,
          ),
          hintStyle: AppTextStyles.bodyMedium(
            color: AppColors.textTertiary,
          ),
          errorStyle: AppTextStyles.errorText,
        ),

        // Floating Action Button Theme
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 4,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: CircleBorder(),
        ),

        // Bottom Navigation Bar Theme
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          elevation: 8,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: AppTextStyles.labelSmall(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: AppTextStyles.labelSmall(),
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
        ),

        // Chip Theme
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.surfaceVariant,
          deleteIconColor: AppColors.textSecondary,
          labelStyle: AppTextStyles.labelMedium(),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),

        // Dialog Theme
        dialogTheme: DialogThemeData(
          elevation: 8,
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titleTextStyle: AppTextStyles.titleLarge(
            fontWeight: FontWeight.bold,
          ),
          contentTextStyle: AppTextStyles.bodyMedium(),
        ),

        // Snackbar Theme
        snackBarTheme: SnackBarThemeData(
          elevation: 6,
          backgroundColor: AppColors.textPrimary,
          contentTextStyle: AppTextStyles.bodyMedium(
            color: Colors.white,
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),

        // Divider Theme
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 1,
          space: 1,
        ),

        // Icon Theme
        iconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: 24,
        ),

        // Switch Theme
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return AppColors.primary;
            }
            return AppColors.textSecondary;
          }),
          trackColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return AppColors.primaryLight.withOpacity(0.5);
            }
            return AppColors.border;
          }),
        ),

        // Progress Indicator Theme
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.primary,
          linearTrackColor: AppColors.primaryContainer,
        ),

        // Scaffold Background
        scaffoldBackgroundColor: AppColors.background,
      );

  // Dark Theme
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primaryLight,
          onPrimary: Colors.black,
          primaryContainer: AppColors.primaryDark,
          onPrimaryContainer: AppColors.primaryLight,
          
          secondary: AppColors.secondaryLight,
          onSecondary: Colors.black,
          secondaryContainer: AppColors.secondaryDark,
          onSecondaryContainer: AppColors.secondaryLight,
          
          tertiary: AppColors.accentLight,
          onTertiary: Colors.black,
          
          error: AppColors.errorLight,
          onError: Colors.black,
          errorContainer: AppColors.errorDark,
          onErrorContainer: AppColors.errorLight,
          
          background: AppColors.backgroundDark,
          onBackground: AppColors.textPrimaryDark,
          
          surface: AppColors.surfaceDark,
          onSurface: AppColors.textPrimaryDark,
          surfaceVariant: AppColors.surfaceVariantDark,
          onSurfaceVariant: AppColors.textSecondaryDark,
          
          outline: AppColors.borderDark,
          outlineVariant: AppColors.dividerDark,
          
          shadow: Colors.black54,
          scrim: AppColors.scrim,
        ),

        textTheme: TextTheme(
          displayLarge: AppTextStyles.displayLargeDark(),
          displayMedium: AppTextStyles.displayMedium(
            color: AppColors.textPrimaryDark,
          ),
          displaySmall: AppTextStyles.displaySmall(
            color: AppColors.textPrimaryDark,
          ),
          headlineLarge: AppTextStyles.headlineLarge(
            color: AppColors.textPrimaryDark,
          ),
          headlineMedium: AppTextStyles.headlineMedium(
            color: AppColors.textPrimaryDark,
          ),
          headlineSmall: AppTextStyles.headlineSmall(
            color: AppColors.textPrimaryDark,
          ),
          titleLarge: AppTextStyles.titleLarge(
            color: AppColors.textPrimaryDark,
          ),
          titleMedium: AppTextStyles.titleMedium(
            color: AppColors.textPrimaryDark,
          ),
          titleSmall: AppTextStyles.titleSmall(
            color: AppColors.textPrimaryDark,
          ),
          bodyLarge: AppTextStyles.bodyLarge(
            color: AppColors.textPrimaryDark,
          ),
          bodyMedium: AppTextStyles.bodyMediumDark(),
          bodySmall: AppTextStyles.bodySmall(
            color: AppColors.textSecondaryDark,
          ),
          labelLarge: AppTextStyles.labelLarge(
            color: AppColors.textPrimaryDark,
          ),
          labelMedium: AppTextStyles.labelMedium(
            color: AppColors.textPrimaryDark,
          ),
          labelSmall: AppTextStyles.labelSmall(
            color: AppColors.textSecondaryDark,
          ),
        ),

        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: AppColors.surfaceDark,
          foregroundColor: AppColors.textPrimaryDark,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: AppTextStyles.titleLarge(
            color: AppColors.textPrimaryDark,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: const IconThemeData(
            color: AppColors.textPrimaryDark,
            size: 24,
          ),
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),

        cardTheme: CardThemeData(
          elevation: 2,
          color: AppColors.surfaceDark,
          shadowColor: Colors.black45,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),

        scaffoldBackgroundColor: AppColors.backgroundDark,
      );
}