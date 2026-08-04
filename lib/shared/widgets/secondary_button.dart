import 'package:flutter/material.dart';

import 'loading_indicator.dart';

/// Rally's secondary outlined action button.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final callback = isLoading ? null : onPressed;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: callback,
        child: isLoading
            ? LoadingIndicator.small(
                color: Theme.of(context).colorScheme.onSurface,
              )
            : Text(label),
      ),
    );
  }
}
