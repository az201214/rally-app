import 'package:flutter/material.dart';

import '../../../../../theme/app_radius.dart';
import '../../../../../theme/app_spacing.dart';

class LiveActivityStrip extends StatefulWidget {
  const LiveActivityStrip({super.key});

  @override
  State<LiveActivityStrip> createState() => _LiveActivityStripState();
}

class _LiveActivityStripState extends State<LiveActivityStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulse = Tween<double>(
      begin: 0.82,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Semantics(
      liveRegion: true,
      label: 'Live now, 24 players looking for a match',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: AppRadius.large,
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: <Widget>[
              ScaleTransition(
                scale: _pulse,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.12),
                        borderRadius: AppRadius.pillRadius,
                      ),
                      child: const SizedBox.square(dimension: AppSpacing.xxl),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: AppRadius.pillRadius,
                      ),
                      child: const SizedBox.square(dimension: AppSpacing.sm),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Text(
                '24',
                style: theme.textTheme.displayMedium?.copyWith(
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'LIVE NOW',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Players Looking For A Match',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
