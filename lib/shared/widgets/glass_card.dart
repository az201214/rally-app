import 'package:flutter/material.dart';

import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';

/// Premium Rally surface for grouping related content.
class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    this.padding = AppSpacing.cardPadding,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: AppRadius.large,
        boxShadow: AppShadows.card,
      ),
      child: child,
    );
  }
}
