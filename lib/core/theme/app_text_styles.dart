import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Font Family for Bangla
  static const String banglaPrimary = 'HindSiliguri';
  
  // Base text style with Bangla support
  static TextStyle get _baseStyle => const TextStyle(
        fontFamily: banglaPrimary,
        fontFamilyFallback: ['Roboto'],
      );

  // Display Styles (Large headings)
  static TextStyle displayLarge({Color? color, FontWeight? fontWeight}) =>
      _baseStyle.copyWith(
        fontSize: 32,
        fontWeight: fontWeight ?? FontWeight.bold,
        color: color ?? AppColors.textPrimary,
        height: 1.3,
      );

  static TextStyle displayMedium({Color? color, FontWeight? fontWeight}) =>
      _baseStyle.copyWith(
        fontSize: 28,
        fontWeight: fontWeight ?? FontWeight.bold,
        color: color ?? AppColors.textPrimary,
        height: 1.3,
      );

  static TextStyle displaySmall({Color? color, FontWeight? fontWeight}) =>
      _baseStyle.copyWith(
        fontSize: 24,
        fontWeight: fontWeight ?? FontWeight.bold,
        color: color ?? AppColors.textPrimary,
        height: 1.3,
      );

  // Headline Styles
  static TextStyle headlineLarge({Color? color, FontWeight? fontWeight}) =>
      _baseStyle.copyWith(
        fontSize: 22,
        fontWeight: fontWeight ?? FontWeight.w600,
        color: color ?? AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle headlineMedium({Color? color, FontWeight? fontWeight}) =>
      _baseStyle.copyWith(
        fontSize: 20,
        fontWeight: fontWeight ?? FontWeight.w600,
        color: color ?? AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle headlineSmall({Color? color, FontWeight? fontWeight}) =>
      _baseStyle.copyWith(
        fontSize: 18,
        fontWeight: fontWeight ?? FontWeight.w600,
        color: color ?? AppColors.textPrimary,
        height: 1.4,
      );

  // Title Styles
  static TextStyle titleLarge({Color? color, FontWeight? fontWeight}) =>
      _baseStyle.copyWith(
        fontSize: 18,
        fontWeight: fontWeight ?? FontWeight.w500,
        color: color ?? AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle titleMedium({Color? color, FontWeight? fontWeight}) =>
      _baseStyle.copyWith(
        fontSize: 16,
        fontWeight: fontWeight ?? FontWeight.w500,
        color: color ?? AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle titleSmall({Color? color, FontWeight? fontWeight}) =>
      _baseStyle.copyWith(
        fontSize: 14,
        fontWeight: fontWeight ?? FontWeight.w500,
        color: color ?? AppColors.textPrimary,
        height: 1.5,
      );

  // Body Styles
  static TextStyle bodyLarge({Color? color, FontWeight? fontWeight}) =>
      _baseStyle.copyWith(
        fontSize: 16,
        fontWeight: fontWeight ?? FontWeight.normal,
        color: color ?? AppColors.textPrimary,
        height: 1.6,
      );

  static TextStyle bodyMedium({Color? color, FontWeight? fontWeight}) =>
      _baseStyle.copyWith(
        fontSize: 14,
        fontWeight: fontWeight ?? FontWeight.normal,
        color: color ?? AppColors.textPrimary,
        height: 1.6,
      );

  static TextStyle bodySmall({Color? color, FontWeight? fontWeight}) =>
      _baseStyle.copyWith(
        fontSize: 12,
        fontWeight: fontWeight ?? FontWeight.normal,
        color: color ?? AppColors.textSecondary,
        height: 1.6,
      );

  // Label Styles
  static TextStyle labelLarge({Color? color, FontWeight? fontWeight}) =>
      _baseStyle.copyWith(
        fontSize: 14,
        fontWeight: fontWeight ?? FontWeight.w500,
        color: color ?? AppColors.textPrimary,
        height: 1.4,
        letterSpacing: 0.1,
      );

  static TextStyle labelMedium({Color? color, FontWeight? fontWeight}) =>
      _baseStyle.copyWith(
        fontSize: 12,
        fontWeight: fontWeight ?? FontWeight.w500,
        color: color ?? AppColors.textPrimary,
        height: 1.4,
        letterSpacing: 0.5,
      );

  static TextStyle labelSmall({Color? color, FontWeight? fontWeight}) =>
      _baseStyle.copyWith(
        fontSize: 11,
        fontWeight: fontWeight ?? FontWeight.w500,
        color: color ?? AppColors.textSecondary,
        height: 1.4,
        letterSpacing: 0.5,
      );

  // Special Purpose Styles
  static TextStyle get buttonLarge => _baseStyle.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: 0.5,
      );

  static TextStyle get buttonMedium => _baseStyle.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: 0.5,
      );

  static TextStyle get buttonSmall => _baseStyle.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: 0.5,
      );

  // Check-in Button Text
  static TextStyle get checkinButton => _baseStyle.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        height: 1.2,
      );

  static TextStyle get checkinTimer => _baseStyle.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.white70,
        height: 1.3,
      );

  // Caption & Helper Text
  static TextStyle get caption => _baseStyle.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  static TextStyle get overline => _baseStyle.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.6,
        letterSpacing: 1.5,
      );

  // Error Text
  static TextStyle get errorText => _baseStyle.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.error,
        height: 1.4,
      );

  // Link Text
  static TextStyle get linkText => _baseStyle.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.primary,
        decoration: TextDecoration.underline,
        height: 1.5,
      );

  // Onboarding Styles
  static TextStyle get onboardingTitle => _baseStyle.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get onboardingSubtitle => _baseStyle.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
        height: 1.6,
      );

  // Dark Mode Variants
  static TextStyle displayLargeDark({Color? color, FontWeight? fontWeight}) =>
      displayLarge(
        color: color ?? AppColors.textPrimaryDark,
        fontWeight: fontWeight,
      );

  static TextStyle bodyMediumDark({Color? color, FontWeight? fontWeight}) =>
      bodyMedium(
        color: color ?? AppColors.textPrimaryDark,
        fontWeight: fontWeight,
      );
}