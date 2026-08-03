import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

abstract final class RallySnackbar {
  static void show(
    BuildContext context, {
    required String message,
    IconData icon = Icons.check_circle_rounded,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          margin: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          padding: EdgeInsets.zero,
          duration: const Duration(seconds: 3),
          content: Semantics(
            liveRegion: true,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated.withValues(alpha: 0.98),
                borderRadius: AppRadius.medium,
                border: Border.all(
                  color: AppColors.electricGreen.withValues(alpha: 0.26),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Icon(icon, color: AppColors.electricGreen, size: 21),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
  }
}
