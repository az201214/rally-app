import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Elevated shadow definitions for premium card and surface styling.
class AppShadows {
  AppShadows._();

  static List<BoxShadow> get card => <BoxShadow>[
    BoxShadow(
      color: AppColors.shadowColor.withValues(alpha: 0.34),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> get glow => <BoxShadow>[
    BoxShadow(
      color: AppColors.accentPrimary.withValues(alpha: 0.22),
      blurRadius: 24,
      offset: const Offset(0, 0),
    ),
  ];
}
