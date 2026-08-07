import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Rally's athletic display and highly legible interface type system.
class AppTypography {
  AppTypography._();

  static TextTheme textTheme(Brightness brightness) {
    final baseTheme = ThemeData(brightness: brightness).textTheme;
    final interTheme = GoogleFonts.interTextTheme(baseTheme);
    final athletic = GoogleFonts.barlowCondensedTextTheme(baseTheme);
    final isDark = brightness == Brightness.dark;

    return interTheme.copyWith(
      displayLarge: athletic.displayLarge?.copyWith(
        color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 0.98,
      ),
      displayMedium: athletic.displayMedium?.copyWith(
        color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        height: 1,
      ),
      headlineLarge: athletic.headlineLarge?.copyWith(
        color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        height: 1.05,
      ),
      headlineMedium: interTheme.headlineMedium?.copyWith(
        color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.01,
      ),
      titleLarge: interTheme.titleLarge?.copyWith(
        color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: interTheme.titleMedium?.copyWith(
        color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: interTheme.bodyLarge?.copyWith(
        color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
        height: 1.5,
      ),
      bodyMedium: interTheme.bodyMedium?.copyWith(
        color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
        height: 1.45,
      ),
      labelSmall: interTheme.labelSmall?.copyWith(
        color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      labelMedium: interTheme.labelMedium?.copyWith(
        color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      labelLarge: interTheme.labelLarge?.copyWith(
        color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }

  static TextTheme get darkTextTheme => textTheme(Brightness.dark);

  static TextTheme get lightTextTheme => textTheme(Brightness.light);
}
