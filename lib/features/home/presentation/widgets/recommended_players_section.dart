import 'package:flutter/material.dart';

import '../../../../../theme/app_radius.dart';
import '../../../../../theme/app_shadows.dart';
import '../../../../../theme/app_spacing.dart';

@immutable
class RecommendedPlayer {
  const RecommendedPlayer({
    required this.initials,
    required this.name,
    required this.skillLevel,
    required this.rating,
    required this.reliability,
    required this.distance,
  });

  final String initials;
  final String name;
  final String skillLevel;
  final String rating;
  final String reliability;
  final String distance;
}

const List<RecommendedPlayer> recommendedPlayers = <RecommendedPlayer>[
  RecommendedPlayer(
    initials: 'AR',
    name: 'Ahmed R.',
    skillLevel: 'Intermediate',
    rating: '4.8',
    reliability: '98%',
    distance: '2.4 km',
  ),
  RecommendedPlayer(
    initials: 'HK',
    name: 'Hassan K.',
    skillLevel: 'Intermediate',
    rating: '4.7',
    reliability: '96%',
    distance: '4.1 km',
  ),
  RecommendedPlayer(
    initials: 'SM',
    name: 'Sara M.',
    skillLevel: 'Advanced',
    rating: '4.9',
    reliability: '99%',
    distance: '5.8 km',
  ),
];

class RecommendedPlayersSection extends StatelessWidget {
  const RecommendedPlayersSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'RECOMMENDED PLAYERS',
                style: theme.textTheme.titleMedium,
              ),
            ),
            Text(
              'NEARBY',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: AppSpacing.xxxl * 5.25,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: recommendedPlayers.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              return RecommendedPlayerCard(player: recommendedPlayers[index]);
            },
          ),
        ),
      ],
    );
  }
}

class RecommendedPlayerCard extends StatefulWidget {
  const RecommendedPlayerCard({required this.player, super.key});

  final RecommendedPlayer player;

  @override
  State<RecommendedPlayerCard> createState() => _RecommendedPlayerCardState();
}

class _RecommendedPlayerCardState extends State<RecommendedPlayerCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  void _setHovered(bool value) {
    if (_isHovered != value) {
      setState(() {
        _isHovered = value;
      });
    }
  }

  void _setPressed(bool value) {
    if (_isPressed != value) {
      setState(() {
        _isPressed = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final player = widget.player;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 180);
    final scale = _isPressed
        ? 0.985
        : _isHovered
        ? 1.015
        : 1.0;

    return Semantics(
      label:
          '${player.name}, ${player.skillLevel}, rating ${player.rating}, '
          '${player.reliability} reliable, ${player.distance}, verified, online',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => _setHovered(true),
        onExit: (_) => _setHovered(false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          child: AnimatedScale(
            scale: scale,
            duration: duration,
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: duration,
              width: AppSpacing.xxxl * 3.5,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                border: Border.all(
                  color: _isHovered ? colors.outline : colors.outlineVariant,
                ),
                borderRadius: AppRadius.large,
                boxShadow: _isHovered ? AppShadows.card : const <BoxShadow>[],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      _PlayerAvatar(player: player),
                      const Spacer(),
                      Icon(
                        Icons.verified_rounded,
                        color: colors.primary,
                        size: AppSpacing.lg,
                        semanticLabel: 'Verified',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(player.name, style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.xs),
                  _SkillBadge(label: player.skillLevel),
                  const Spacer(),
                  _PlayerMetrics(player: player),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerAvatar extends StatelessWidget {
  const _PlayerAvatar({required this.player});

  final RecommendedPlayer player;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.tertiary,
            borderRadius: AppRadius.pillRadius,
            border: Border.all(color: colors.outline),
          ),
          child: SizedBox.square(
            dimension: AppSpacing.xxxl,
            child: Center(
              child: Text(
                player.initials,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colors.primary,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: AppRadius.pillRadius,
              border: Border.all(color: colors.surfaceContainerHighest),
            ),
            child: const SizedBox.square(dimension: AppSpacing.sm),
          ),
        ),
      ],
    );
  }
}

class _SkillBadge extends StatelessWidget {
  const _SkillBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.pillRadius,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        child: Text(label, style: theme.textTheme.labelMedium),
      ),
    );
  }
}

class _PlayerMetrics extends StatelessWidget {
  const _PlayerMetrics({required this.player});

  final RecommendedPlayer player;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        _PlayerMetric(icon: Icons.star_rounded, value: player.rating),
        _PlayerMetric(icon: Icons.shield_outlined, value: player.reliability),
        _PlayerMetric(icon: Icons.near_me_outlined, value: player.distance),
      ],
    );
  }
}

class _PlayerMetric extends StatelessWidget {
  const _PlayerMetric({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          icon,
          size: AppSpacing.md,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: AppSpacing.xxs),
        Text(value, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}
