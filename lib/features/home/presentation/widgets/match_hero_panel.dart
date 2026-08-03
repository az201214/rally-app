import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../theme/app_radius.dart';
import '../../../../../theme/app_shadows.dart';
import '../../../../../theme/app_spacing.dart';
import 'trajectory_painter.dart';

class MatchHeroPanel extends StatefulWidget {
  const MatchHeroPanel({required this.onFindMatch, super.key});

  final VoidCallback onFindMatch;

  @override
  State<MatchHeroPanel> createState() => _MatchHeroPanelState();
}

class _MatchHeroPanelState extends State<MatchHeroPanel>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _ambientController;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );
    _opacity = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _offset = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutCubic,
          ),
        );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _entranceController.value = 1;
      _ambientController
        ..stop()
        ..value = 0.5;
      return;
    }

    if (_entranceController.value == 0) {
      _entranceController.forward();
    }
    if (!_ambientController.isAnimating) {
      _ambientController.repeat();
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: AnimatedBuilder(
          animation: _ambientController,
          builder: (context, child) {
            final phase = _ambientController.value * math.pi * 2;
            final floatOffset = math.sin(phase) * AppSpacing.xxs;
            final breath = (math.sin(phase) + 1) / 2;

            return Transform.translate(
              offset: Offset(0, floatOffset),
              child: _HeroSurface(
                trajectoryProgress: _ambientController.value,
                glowStrength: breath,
                onFindMatch: widget.onFindMatch,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HeroSurface extends StatelessWidget {
  const _HeroSurface({
    required this.trajectoryProgress,
    required this.glowStrength,
    required this.onFindMatch,
  });

  final double trajectoryProgress;
  final double glowStrength;
  final VoidCallback onFindMatch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isCompact = MediaQuery.sizeOf(context).width < AppSpacing.xxxl * 7.5;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSpacing.xxxl * 5.5),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          border: Border.all(color: colors.outlineVariant),
          borderRadius: AppRadius.xLarge,
          boxShadow: <BoxShadow>[
            ...AppShadows.card,
            BoxShadow(
              color: colors.primary.withValues(
                alpha: 0.04 + glowStrength * 0.05,
              ),
              blurRadius: AppSpacing.lg + glowStrength * AppSpacing.xs,
              offset: const Offset(0, AppSpacing.xs),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: AppRadius.xLarge,
          child: Stack(
            children: <Widget>[
              Positioned(
                top: AppSpacing.lg,
                right: -AppSpacing.xl,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: AppRadius.pillRadius,
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: const SizedBox.square(dimension: AppSpacing.xxxl * 2),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xxxl,
                      AppSpacing.xxxl,
                      AppSpacing.lg,
                      AppSpacing.xxl,
                    ),
                    child: Opacity(
                      opacity: 0.3,
                      child: CustomPaint(
                        painter: TrajectoryPainter(
                          color: colors.primary,
                          progress: trajectoryProgress,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final sweepWidth = AppSpacing.xxs;
                      final sweepOffset =
                          trajectoryProgress *
                              (constraints.maxWidth + sweepWidth) -
                          sweepWidth;

                      return Transform.translate(
                        offset: Offset(sweepOffset, 0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: ColoredBox(
                            color: colors.primary.withValues(alpha: 0.08),
                            child: SizedBox(
                              width: sweepWidth,
                              height: constraints.maxHeight,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'MATCHMAKING / LIVE',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'READY TO PLAY?',
                      style: isCompact
                          ? theme.textTheme.headlineMedium
                          : theme.textTheme.displayMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Find your next padel match in under 30 seconds.',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _HeroActionButton(
                      key: const Key('find-match-button'),
                      onPressed: onFindMatch,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const _MatchStatusRow(),
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

class _HeroActionButton extends StatefulWidget {
  const _HeroActionButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  State<_HeroActionButton> createState() => _HeroActionButtonState();
}

class _HeroActionButtonState extends State<_HeroActionButton> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) {
      return;
    }
    setState(() {
      _isPressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 120);

    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1,
        duration: duration,
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: duration,
          decoration: BoxDecoration(
            borderRadius: AppRadius.medium,
            boxShadow: _isPressed
                ? const <BoxShadow>[]
                : <BoxShadow>[
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.18),
                      blurRadius: AppSpacing.md,
                      offset: const Offset(0, AppSpacing.xxs),
                    ),
                  ],
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onPressed,
              child: const Text('FIND A MATCH'),
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchStatusRow extends StatelessWidget {
  const _MatchStatusRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.sm,
      children: const <Widget>[
        _StatusItem(icon: Icons.bolt_rounded, label: 'Average wait: 18 sec'),
        _StatusItem(
          icon: Icons.verified_rounded,
          label: 'Verified players nearby',
        ),
      ],
    );
  }
}

class _StatusItem extends StatelessWidget {
  const _StatusItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppSpacing.xxxl * 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: AppSpacing.md, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.xs),
          Flexible(child: Text(label, style: theme.textTheme.labelSmall)),
        ],
      ),
    );
  }
}
