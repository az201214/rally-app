import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

/// Horizontal divider with a centered, theme-aware label.
class DividerWithText extends StatelessWidget {
  const DividerWithText({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
