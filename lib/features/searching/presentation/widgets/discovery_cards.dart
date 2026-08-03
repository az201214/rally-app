import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_spacing.dart';

class DiscoveryCards extends StatefulWidget {
  const DiscoveryCards({super.key});

  @override
  State<DiscoveryCards> createState() => _DiscoveryCardsState();
}

class _DiscoveryCardsState extends State<DiscoveryCards>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 920),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (_controller.value == 0) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const items = <_DiscoveryData>[
      _DiscoveryData('Players Nearby', 12, Icons.groups_rounded),
      _DiscoveryData('Compatible', 5, Icons.tune_rounded),
      _DiscoveryData('Ready Now', 2, Icons.bolt_rounded),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 370;
        if (isNarrow) {
          return Column(
            children: List<Widget>.generate(items.length, (index) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == items.length - 1 ? 0 : AppSpacing.xs,
                ),
                child: _AnimatedCard(
                  data: items[index],
                  index: index,
                  animation: _controller,
                  horizontal: true,
                ),
              );
            }),
          );
        }
        return Row(
          children: List<Widget>.generate(items.length, (index) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index == items.length - 1 ? 0 : AppSpacing.xs,
                ),
                child: _AnimatedCard(
                  data: items[index],
                  index: index,
                  animation: _controller,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _AnimatedCard extends StatelessWidget {
  const _AnimatedCard({
    required this.data,
    required this.index,
    required this.animation,
    this.horizontal = false,
  });

  final _DiscoveryData data;
  final int index;
  final Animation<double> animation;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final start = index * 0.14;
    final curved = CurvedAnimation(
      parent: animation,
      curve: Interval(start, (start + 0.64).clamp(0, 1), curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.18),
          end: Offset.zero,
        ).animate(curved),
        child: _DiscoveryCard(
          data: data,
          progress: curved,
          horizontal: horizontal,
        ),
      ),
    );
  }
}

class _DiscoveryCard extends StatelessWidget {
  const _DiscoveryCard({
    required this.data,
    required this.progress,
    required this.horizontal,
  });

  final _DiscoveryData data;
  final Animation<double> progress;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: AppRadius.large,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.045),
            borderRadius: AppRadius.large,
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.10),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: horizontal
                ? Row(
                    children: <Widget>[
                      _IconBadge(icon: data.icon),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: _CardLabel(label: data.label)),
                      _AnimatedCount(value: data.value, progress: progress),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _IconBadge(icon: data.icon),
                      const SizedBox(height: AppSpacing.sm),
                      _AnimatedCount(value: data.value, progress: progress),
                      const SizedBox(height: AppSpacing.xxs),
                      _CardLabel(label: data.label),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.electricGreen.withValues(alpha: 0.10),
        borderRadius: AppRadius.small,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Icon(icon, color: AppColors.electricGreen, size: AppSpacing.md),
      ),
    );
  }
}

class _AnimatedCount extends StatelessWidget {
  const _AnimatedCount({required this.value, required this.progress});
  final int value;
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) => Text(
        '${(value * progress.value).round()}',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: AppColors.electricGreen,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CardLabel extends StatelessWidget {
  const _CardLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      color: AppColors.textSecondary,
      fontSize: 12,
      height: 1.25,
    ),
  );
}

class _DiscoveryData {
  const _DiscoveryData(this.label, this.value, this.icon);
  final String label;
  final int value;
  final IconData icon;
}
