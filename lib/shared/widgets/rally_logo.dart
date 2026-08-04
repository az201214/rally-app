import 'package:flutter/material.dart';

/// Temporary text-based Rally logo used until brand assets are available.
class RallyLogo extends StatelessWidget {
  const RallyLogo({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      'RALLY',
      style: theme.textTheme.headlineMedium?.copyWith(
        color: theme.colorScheme.primary,
      ),
    );
  }
}
