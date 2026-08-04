import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

class RallyContent extends StatelessWidget {
  const RallyContent({required this.child, this.padding, super.key});

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding:
              padding ??
              const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
          child: child,
        ),
      ),
    );
  }
}

class RallyGlassPanel extends StatelessWidget {
  const RallyGlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final panel = ClipRRect(
      borderRadius: AppRadius.large,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: .82),
            border: Border.all(color: colors.outlineVariant),
            borderRadius: AppRadius.large,
          ),
          child: child,
        ),
      ),
    );
    if (onTap == null) return panel;
    return Semantics(
      button: true,
      child: InkWell(borderRadius: AppRadius.large, onTap: onTap, child: panel),
    );
  }
}

class RallyAvatar extends StatelessWidget {
  const RallyAvatar({
    required this.initials,
    this.verified = true,
    this.size = 56,
    super.key,
  });

  final String initials;
  final bool verified;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      image: true,
      label: '$initials player avatar${verified ? ', verified' : ''}',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.tertiary,
              border: Border.all(color: colors.outline),
            ),
            child: Text(
              initials,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (verified)
            Positioned(
              right: -2,
              bottom: -2,
              child: Icon(
                Icons.verified_rounded,
                size: size * .32,
                color: colors.primary,
              ),
            ),
        ],
      ),
    );
  }
}

class RallyStatusChip extends StatelessWidget {
  const RallyStatusChip({required this.label, this.icon, super.key});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: icon == null ? null : Icon(icon, size: 16),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}

class RallySectionHeader extends StatelessWidget {
  const RallySectionHeader({required this.title, this.trailing, super.key});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class RallyInfoRow extends StatelessWidget {
  const RallyInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelMedium),
                Text(value, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CompatibilityRing extends StatelessWidget {
  const CompatibilityRing({this.value = .94, this.size = 88, super.key});

  final double value;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: '${(value * 100).round()} percent compatibility',
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: value,
              strokeWidth: 5,
              backgroundColor: colors.outlineVariant,
              color: colors.primary,
            ),
            Center(
              child: Text(
                '${(value * 100).round()}%',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
