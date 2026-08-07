import 'package:flutter/material.dart';

import '../../theme/app_radius.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';

/// Premium Rally surface for grouping related content.
class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    this.padding = AppSpacing.cardPadding,
    this.accented = false,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool accented;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      container: true,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: accented
                ? AppColors.accentPrimary.withValues(alpha: 0.42)
                : colorScheme.outlineVariant,
          ),
          borderRadius: AppRadius.large,
          boxShadow: AppShadows.card,
        ),
        child: child,
      ),
    );
  }
}
