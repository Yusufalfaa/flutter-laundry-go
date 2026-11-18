
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = ThemeData.light().textTheme.apply(
      fontFamily: 'PlusJakartaSans',
    );

    final textTheme = baseTextTheme.copyWith(
      // H1 - Page Title
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.deepNavy,
      ),

      // H2 - Section Title
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.deepNavy,
      ),

      // Saldo
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.deepNavy,
      ),

      // Body
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.deepNavy,
      ),

      // Body Strong
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.deepNavy,
      ),

      // Button
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),

      // Caption
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),

      // Bottom Navigation
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.primaryBright,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      textTheme: textTheme,
    );
  }
}
