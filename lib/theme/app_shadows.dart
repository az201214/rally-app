import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Elevated shadow definitions for premium card and surface styling.
class AppShadows {
  AppShadows._();

  static List<BoxShadow> get card => <BoxShadow>[
    BoxShadow(
      color: AppColors.shadowColor.withValues(alpha: 0.25),
      blurRadius: 24,
      offset: const Offset(0, 16),
    ),
    BoxShadow(
      color: AppColors.accentPrimary.withValues(alpha: 0.08),
      blurRadius: 40,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get glow => <BoxShadow>[
    BoxShadow(
      color: AppColors.accentPrimary.withValues(alpha: 0.35),
      blurRadius: 36,
      offset: const Offset(0, 0),
    ),
  ];
}
