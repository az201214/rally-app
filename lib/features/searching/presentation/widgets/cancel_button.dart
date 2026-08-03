import 'package:flutter/material.dart';

import '../../../../theme/app_radius.dart';
import '../../../../theme/app_spacing.dart';

class CancelButton extends StatelessWidget {
  const CancelButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextButton(
      key: const Key('cancel-search-button'),
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.70),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.pillRadius,
          side: BorderSide(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
          ),
        ),
      ),
      child: const Text('Cancel Search'),
    );
  }
}
