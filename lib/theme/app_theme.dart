import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_shadows.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Material 3 theme definition for Rally with a dark-first premium aesthetic.
class AppTheme {
  AppTheme._();

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accentPrimary,
      onPrimary: AppColors.textInverse,
      secondary: AppColors.accentSecondary,
      onSecondary: AppColors.textInverse,
      surface: AppColors.surfacePrimary,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceElevated,
      outline: AppColors.borderStrong,
      outlineVariant: AppColors.borderSubtle,
      tertiary: AppColors.accentTertiary,
      error: AppColors.error,
      onError: AppColors.textPrimary,
    ),
    scaffoldBackgroundColor: AppColors.surfacePrimary,
    cardColor: AppColors.surfaceSecondary,
    dividerColor: AppColors.borderSubtle,
    textTheme: AppTypography.darkTextTheme,
    fontFamily: GoogleFonts.inter().fontFamily,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surfacePrimary,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceElevated,
      border: OutlineInputBorder(
        borderRadius: AppRadius.medium,
        borderSide: const BorderSide(color: AppColors.borderSubtle),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.medium,
        borderSide: const BorderSide(color: AppColors.borderSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.medium,
        borderSide: const BorderSide(color: AppColors.accentPrimary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentPrimary,
        foregroundColor: AppColors.textInverse,
        padding: AppSpacing.buttonPadding,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
        elevation: 0,
        textStyle: AppTypography.darkTextTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.borderStrong),
        padding: AppSpacing.buttonPadding,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
        textStyle: AppTypography.darkTextTheme.labelLarge,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceSecondary,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
      margin: const EdgeInsets.all(AppSpacing.sm),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceElevated,
      selectedColor: AppColors.accentPrimary,
      side: const BorderSide(color: AppColors.borderSubtle),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.pillRadius),
      labelStyle: AppTypography.darkTextTheme.bodyMedium,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surfaceSecondary,
      indicatorColor: AppColors.accentPrimary.withValues(alpha: 0.16),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected)
            ? AppTypography.darkTextTheme.labelMedium?.copyWith(color: AppColors.accentPrimary)
            : AppTypography.darkTextTheme.labelMedium?.copyWith(color: AppColors.textSecondary);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        return IconThemeData(
          color: states.contains(WidgetState.selected) ? AppColors.accentPrimary : AppColors.textSecondary,
        );
      }),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surfaceSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
    ),
    extensions: <ThemeExtension<dynamic>>[
      AppThemeExtension(
        cardShadow: AppShadows.card,
        glowShadow: AppShadows.glow,
        spacing: AppSpacing.screenPadding,
      ),
    ],
  );

  static ThemeData lightTheme = darkTheme.copyWith(
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColors.accentPrimary,
      onPrimary: AppColors.textInverse,
      secondary: AppColors.accentSecondary,
      onSecondary: AppColors.textInverse,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textPrimaryLight,
      surfaceContainerHighest: AppColors.surfaceElevatedLight,
      outline: AppColors.borderLight,
      outlineVariant: AppColors.borderLight,
      tertiary: AppColors.accentTertiary,
      error: AppColors.error,
      onError: AppColors.textPrimary,
    ),
    scaffoldBackgroundColor: AppColors.surfaceLight,
    cardColor: AppColors.surfaceElevatedLight,
    dividerColor: AppColors.borderLight,
    textTheme: AppTypography.lightTextTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surfaceLight,
      foregroundColor: AppColors.textPrimaryLight,
      elevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceElevatedLight,
      border: OutlineInputBorder(
        borderRadius: AppRadius.medium,
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.medium,
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.medium,
        borderSide: const BorderSide(color: AppColors.accentPrimary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentPrimary,
        foregroundColor: AppColors.textInverse,
        padding: AppSpacing.buttonPadding,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
        elevation: 0,
        textStyle: AppTypography.lightTextTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimaryLight,
        side: const BorderSide(color: AppColors.borderLight),
        padding: AppSpacing.buttonPadding,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
        textStyle: AppTypography.lightTextTheme.labelLarge,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceElevatedLight,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
      margin: const EdgeInsets.all(AppSpacing.sm),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceLight,
      selectedColor: AppColors.accentPrimary,
      side: const BorderSide(color: AppColors.borderLight),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.pillRadius),
      labelStyle: AppTypography.lightTextTheme.bodyMedium,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surfaceElevatedLight,
      indicatorColor: AppColors.accentPrimary.withValues(alpha: 0.14),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected)
            ? AppTypography.lightTextTheme.labelMedium?.copyWith(color: AppColors.accentPrimary)
            : AppTypography.lightTextTheme.labelMedium?.copyWith(color: AppColors.textSecondaryLight);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        return IconThemeData(
          color: states.contains(WidgetState.selected) ? AppColors.accentPrimary : AppColors.textSecondaryLight,
        );
      }),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surfaceElevatedLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
    ),
    extensions: <ThemeExtension<dynamic>>[
      AppThemeExtension(
        cardShadow: AppShadows.card,
        glowShadow: AppShadows.glow,
        spacing: AppSpacing.screenPadding,
      ),
    ],
  );
}

/// Custom theme extension for Rally-specific visual tokens.
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    required this.cardShadow,
    required this.glowShadow,
    required this.spacing,
  });

  final List<BoxShadow> cardShadow;
  final List<BoxShadow> glowShadow;
  final EdgeInsets spacing;

  @override
  AppThemeExtension copyWith({
    List<BoxShadow>? cardShadow,
    List<BoxShadow>? glowShadow,
    EdgeInsets? spacing,
  }) {
    return AppThemeExtension(
      cardShadow: cardShadow ?? this.cardShadow,
      glowShadow: glowShadow ?? this.glowShadow,
      spacing: spacing ?? this.spacing,
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) {
      return this;
    }

    return AppThemeExtension(
      cardShadow: other.cardShadow,
      glowShadow: other.glowShadow,
      spacing: EdgeInsets.lerp(spacing, other.spacing, t) ?? spacing,
    );
  }
}
