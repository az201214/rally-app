import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import 'loading_indicator.dart';

/// Rally's primary filled action button.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final callback = isLoading ? null : onPressed;

    return Semantics(
      button: true,
      label: label,
      enabled: callback != null,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: callback,
          child: isLoading
              ? LoadingIndicator.small(color: colorScheme.onPrimary)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (icon != null) ...<Widget>[
                      Icon(icon),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    Text(label),
                  ],
                ),
        ),
      ),
    );
  }
}
