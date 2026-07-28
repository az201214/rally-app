import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography scale for Rally with Inter as the primary typeface.
class AppTypography {
  AppTypography._();

  static TextTheme textTheme(Brightness brightness) {
    final baseTheme = ThemeData(brightness: brightness).textTheme;
    final interTheme = GoogleFonts.interTextTheme(baseTheme);
    final isDark = brightness == Brightness.dark;

    return interTheme.copyWith(
      displayLarge: interTheme.displayLarge?.copyWith(
        color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.03,
        height: 1.08,
      ),
      displayMedium: interTheme.displayMedium?.copyWith(
        color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02,
        height: 1.1,
      ),
      headlineMedium: interTheme.headlineMedium?.copyWith(
        color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.01,
      ),
      titleLarge: interTheme.titleLarge?.copyWith(
        color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
        fontWeight: FontWeight.w600,
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
      labelLarge: interTheme.labelLarge?.copyWith(
        color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  static TextTheme get darkTextTheme => textTheme(Brightness.dark);

  static TextTheme get lightTextTheme => textTheme(Brightness.light);
}
