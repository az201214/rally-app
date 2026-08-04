import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

enum LoadingIndicatorSize { small, large }

/// Theme-aware loading indicator with standard Rally sizes.
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator.small({this.color, super.key})
    : size = LoadingIndicatorSize.small;

  const LoadingIndicator.large({this.color, super.key})
    : size = LoadingIndicatorSize.large;

  final Color? color;
  final LoadingIndicatorSize size;

  @override
  Widget build(BuildContext context) {
    final dimension = switch (size) {
      LoadingIndicatorSize.small => AppSpacing.lg,
      LoadingIndicatorSize.large => AppSpacing.xl,
    };

    return SizedBox.square(
      dimension: dimension,
      child: CircularProgressIndicator(
        color: color ?? Theme.of(context).colorScheme.primary,
        strokeWidth: AppSpacing.xxs,
      ),
    );
  }
}
