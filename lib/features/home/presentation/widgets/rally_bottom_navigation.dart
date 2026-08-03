import 'package:flutter/material.dart';

import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_radius.dart';
import '../../../../../theme/app_shadows.dart';
import '../../../../../theme/app_spacing.dart';

enum HomeDestination { home, discover, play, matches, profile }

class RallyBottomNavigation extends StatelessWidget {
  const RallyBottomNavigation({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final HomeDestination selected;
  final ValueChanged<HomeDestination> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated.withValues(alpha: 0.98),
          borderRadius: AppRadius.xLarge,
          border: Border.all(color: colors.outlineVariant),
          boxShadow: AppShadows.card,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: Row(
            children: <Widget>[
              _NavigationItem(
                destination: HomeDestination.home,
                icon: Icons.home_rounded,
                label: 'Home',
                selected: selected == HomeDestination.home,
                duration: duration,
                onPressed: onSelected,
              ),
              _NavigationItem(
                destination: HomeDestination.discover,
                icon: Icons.explore_outlined,
                label: 'Discover',
                selected: selected == HomeDestination.discover,
                duration: duration,
                onPressed: onSelected,
              ),
              Expanded(
                child: Semantics(
                  label: 'Play, find a match',
                  button: true,
                  child: _PlayButton(
                    onPressed: () => onSelected(HomeDestination.play),
                    duration: duration,
                  ),
                ),
              ),
              _NavigationItem(
                destination: HomeDestination.matches,
                icon: Icons.calendar_month_outlined,
                label: 'Matches',
                selected: selected == HomeDestination.matches,
                duration: duration,
                onPressed: onSelected,
              ),
              _NavigationItem(
                destination: HomeDestination.profile,
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                selected: selected == HomeDestination.profile,
                duration: duration,
                onPressed: onSelected,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayButton extends StatefulWidget {
  const _PlayButton({required this.onPressed, required this.duration});

  final VoidCallback onPressed;
  final Duration duration;

  @override
  State<_PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<_PlayButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Listener(
      onPointerDown: (_) => setState(() => _isPressed = true),
      onPointerUp: (_) => setState(() => _isPressed = false),
      onPointerCancel: (_) => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1,
        duration: widget.duration,
        child: IconButton.filled(
          key: const Key('central-play-button'),
          onPressed: widget.onPressed,
          tooltip: 'Find a match',
          icon: const Icon(Icons.sports_tennis_rounded),
          style: IconButton.styleFrom(
            minimumSize: const Size.square(AppSpacing.xxxl),
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            shape: const CircleBorder(),
          ),
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.destination,
    required this.icon,
    required this.label,
    required this.selected,
    required this.duration,
    required this.onPressed,
  });

  final HomeDestination destination;
  final IconData icon;
  final String label;
  final bool selected;
  final Duration duration;
  final ValueChanged<HomeDestination> onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final color = selected ? colors.primary : colors.onSurfaceVariant;

    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          onTap: () => onPressed(destination),
          borderRadius: AppRadius.large,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSpacing.xxxl),
            child: AnimatedContainer(
              duration: duration,
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: selected
                    ? colors.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: AppRadius.large,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  AnimatedScale(
                    scale: selected ? 1.08 : 1,
                    duration: duration,
                    curve: Curves.easeOutBack,
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  AnimatedDefaultTextStyle(
                    duration: duration,
                    style:
                        theme.textTheme.labelSmall?.copyWith(color: color) ??
                        TextStyle(color: color),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
