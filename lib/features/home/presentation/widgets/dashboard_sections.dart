import 'package:flutter/material.dart';

import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_radius.dart';
import '../../../../../theme/app_spacing.dart';

class DashboardStatistics extends StatelessWidget {
  const DashboardStatistics({super.key});

  static const _stats = <_Statistic>[
    _Statistic('4.9', 'RATING', Icons.star_rounded, 4.9),
    _Statistic('92%', 'RELIABILITY', Icons.verified_user_rounded, 92),
    _Statistic('128', 'ONLINE', Icons.sensors_rounded, 128),
    _Statistic('68', 'MATCHES', Icons.sports_tennis_rounded, 68),
  ];

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 4 : 2;
        final scale = MediaQuery.textScalerOf(context).scale(1);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _stats.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            mainAxisExtent: 154 + (scale - 1).clamp(0.0, 1.0) * 168,
          ),
          itemBuilder: (context, index) => _StatisticCard(
            statistic: _stats[index],
            reducedMotion: reducedMotion,
          ),
        );
      },
    );
  }
}

class _Statistic {
  const _Statistic(this.display, this.label, this.icon, this.value);
  final String display;
  final String label;
  final IconData icon;
  final double value;
}

class _StatisticCard extends StatelessWidget {
  const _StatisticCard({required this.statistic, required this.reducedMotion});

  final _Statistic statistic;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '${statistic.label}, ${statistic.display}',
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: AppRadius.large,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Icon(statistic.icon, color: AppColors.electricGreen, size: 22),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: statistic.value),
            duration: reducedMotion
                ? Duration.zero
                : const Duration(milliseconds: 480),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => Text(
              _animatedLabel(statistic, value),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ),
          Text(statistic.label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    ),
  );

  String _animatedLabel(_Statistic stat, double value) {
    if (stat.display.endsWith('%')) return '${value.round()}%';
    if (stat.display.contains('.')) return value.toStringAsFixed(1);
    return '${value.round()}';
  }
}

class AiRecommendationCard extends StatelessWidget {
  const AiRecommendationCard({required this.onFindMatch, super.key});

  final VoidCallback onFindMatch;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: AppColors.surfaceElevated,
      borderRadius: AppRadius.xLarge,
      border: Border.all(
        color: AppColors.electricGreen.withValues(alpha: 0.22),
      ),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final action = FilledButton.icon(
          onPressed: onFindMatch,
          icon: const Icon(Icons.arrow_forward_rounded),
          label: const Text('USE THIS MATCH'),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Row(
              children: <Widget>[
                Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.electricGreen,
                ),
                SizedBox(width: AppSpacing.xs),
                Expanded(child: Text('RALLY RECOMMENDATION')),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Play tonight at Padelverse Clifton',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Eight compatible players are active nearby, with your strongest availability window between 7–9 PM.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (constraints.maxWidth < 420)
              SizedBox(width: double.infinity, child: action)
            else
              Align(alignment: Alignment.centerRight, child: action),
          ],
        );
      },
    ),
  );
}

class NearbyClubsCarousel extends StatelessWidget {
  const NearbyClubsCarousel({required this.onClubSelected, super.key});

  final VoidCallback onClubSelected;

  static const clubs = <_Club>[
    _Club('PADELVERSE', 'Clifton · 1.8 km', '4 courts', 18),
    _Club('THE PADEL CLUB', 'DHA · 3.2 km', '6 courts', 11),
    _Club('SMASH ARENA', 'Khayaban · 4.6 km', '3 courts', 9),
  ];

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return _CarouselSection(
      title: 'NEARBY CLUBS',
      trailing: '3 NEAR YOU',
      height: 312 + (scale - 1).clamp(0.0, 1.0) * 128,
      itemCount: clubs.length,
      itemBuilder: (context, index) =>
          _ClubCard(club: clubs[index], onPressed: onClubSelected),
    );
  }
}

class _Club {
  const _Club(this.name, this.location, this.courts, this.online);
  final String name;
  final String location;
  final String courts;
  final int online;
}

class _ClubCard extends StatelessWidget {
  const _ClubCard({required this.club, required this.onPressed});
  final _Club club;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 250,
    child: Material(
      color: AppColors.surfaceSecondary,
      borderRadius: AppRadius.large,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.large,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadius.large,
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                height: 72,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[
                      AppColors.accentTertiary,
                      AppColors.surfaceElevated,
                    ],
                  ),
                  borderRadius: AppRadius.medium,
                ),
                child: const RepaintBoundary(
                  child: CustomPaint(painter: _MiniCourtPainter()),
                ),
              ),
              const Spacer(),
              Text(club.name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xxs),
              Text(club.location),
              const SizedBox(height: AppSpacing.xs),
              Text('${club.courts} · ${club.online} players online'),
            ],
          ),
        ),
      ),
    ),
  );
}

class TrendingPlayersCarousel extends StatelessWidget {
  const TrendingPlayersCarousel({required this.onPlayerSelected, super.key});

  final VoidCallback onPlayerSelected;

  static const players = <_Player>[
    _Player('AR', 'Ahmed R.', '4.8', '98%'),
    _Player('SM', 'Sara M.', '4.9', '99%'),
    _Player('HK', 'Hassan K.', '4.7', '96%'),
  ];

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return _CarouselSection(
      title: 'TRENDING PLAYERS',
      trailing: 'THIS WEEK',
      height: 248 + (scale - 1).clamp(0.0, 1.0) * 112,
      itemCount: players.length,
      itemBuilder: (context, index) =>
          _PlayerCard(player: players[index], onPressed: onPlayerSelected),
    );
  }
}

class _Player {
  const _Player(this.initials, this.name, this.rating, this.reliability);
  final String initials;
  final String name;
  final String rating;
  final String reliability;
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({required this.player, required this.onPressed});
  final _Player player;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 180,
    child: Material(
      color: AppColors.surfaceSecondary,
      borderRadius: AppRadius.large,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.large,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadius.large,
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.accentTertiary,
                child: Text(player.initials),
              ),
              const Spacer(),
              Text(player.name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.star_rounded,
                    size: 17,
                    color: AppColors.electricGreen,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Expanded(
                    child: Text(
                      '${player.rating} · ${player.reliability} reliable',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _CarouselSection extends StatelessWidget {
  const _CarouselSection({
    required this.title,
    required this.trailing,
    required this.height,
    required this.itemCount,
    required this.itemBuilder,
  });
  final String title;
  final String trailing;
  final double height;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Row(
        children: <Widget>[
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          Text(
            trailing,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.electricGreen),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      SizedBox(
        height: height,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.hardEdge,
          padding: const EdgeInsets.only(right: AppSpacing.lg),
          itemCount: itemCount,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
          itemBuilder: itemBuilder,
        ),
      ),
    ],
  );
}

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({
    required this.onPlay,
    required this.onClubs,
    required this.onProfile,
    super.key,
  });
  final VoidCallback onPlay;
  final VoidCallback onClubs;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text('QUICK ACTIONS', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: AppSpacing.md),
      Row(
        children: <Widget>[
          Expanded(
            child: _QuickAction(
              key: const Key('quick-play'),
              icon: Icons.sports_tennis_rounded,
              label: 'Play',
              onPressed: onPlay,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _QuickAction(
              key: const Key('quick-clubs'),
              icon: Icons.stadium_outlined,
              label: 'Clubs',
              onPressed: onClubs,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _QuickAction(
              key: const Key('quick-profile'),
              icon: Icons.person_outline_rounded,
              label: 'Profile',
              onPressed: onProfile,
            ),
          ),
        ],
      ),
    ],
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(58),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 21),
        const SizedBox(height: AppSpacing.xxs),
        Text(label, maxLines: 1),
      ],
    ),
  );
}

class _MiniCourtPainter extends CustomPainter {
  const _MiniCourtPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textPrimary.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final rect = Rect.fromLTWH(12, 10, size.width - 24, size.height - 20);
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(AppRadius.sm)),
        paint,
      )
      ..drawLine(rect.centerLeft, rect.centerRight, paint)
      ..drawLine(
        Offset(rect.center.dx, rect.top),
        Offset(rect.center.dx, rect.bottom),
        paint,
      );
  }

  @override
  bool shouldRepaint(_MiniCourtPainter oldDelegate) => false;
}
