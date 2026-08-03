import 'package:flutter/material.dart';

import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_radius.dart';
import '../../../../../theme/app_shadows.dart';
import '../../../../../theme/app_spacing.dart';
import 'availability_selector.dart';

class DashboardHero extends StatefulWidget {
  const DashboardHero({
    required this.availability,
    required this.onAvailabilityChanged,
    required this.onFindMatch,
    super.key,
  });

  final AvailabilityOption availability;
  final ValueChanged<AvailabilityOption> onAvailabilityChanged;
  final VoidCallback onFindMatch;

  @override
  State<DashboardHero> createState() => _DashboardHeroState();
}

class _DashboardHeroState extends State<DashboardHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
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
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.035),
          end: Offset.zero,
        ).animate(animation),
        child: _HeroSurface(
          availability: widget.availability,
          onAvailabilityChanged: widget.onAvailabilityChanged,
          onFindMatch: widget.onFindMatch,
        ),
      ),
    );
  }
}

class _HeroSurface extends StatelessWidget {
  const _HeroSurface({
    required this.availability,
    required this.onAvailabilityChanged,
    required this.onFindMatch,
  });

  final AvailabilityOption availability;
  final ValueChanged<AvailabilityOption> onAvailabilityChanged;
  final VoidCallback onFindMatch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: 'Match dashboard. Available ${availability.label}.',
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              AppColors.surfaceElevated,
              AppColors.surfaceSecondary,
            ],
          ),
          borderRadius: AppRadius.xLarge,
          border: Border.all(color: AppColors.borderStrong),
          boxShadow: AppShadows.card,
        ),
        child: ClipRRect(
          borderRadius: AppRadius.xLarge,
          child: Stack(
            children: <Widget>[
              const Positioned.fill(
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: CustomPaint(painter: _CourtGlow()),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 620;
                    final headline = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: <Widget>[
                            Text(
                              'GOOD EVENING, HAMZA',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: AppColors.electricGreen,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const _WeatherBadge(),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'READY TO PLAY?',
                          style: wide
                              ? theme.textTheme.displayMedium
                              : theme.textTheme.headlineLarge,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Your next great match is closer than you think.',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    );
                    final match = _NextMatch(onFindMatch: onFindMatch);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        if (wide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(flex: 5, child: headline),
                              const SizedBox(width: AppSpacing.lg),
                              Expanded(flex: 4, child: match),
                            ],
                          )
                        else ...<Widget>[
                          headline,
                          const SizedBox(height: AppSpacing.lg),
                          match,
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'AVAILABLE TO PLAY',
                          style: theme.textTheme.labelMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AvailabilitySelector(
                          selected: availability,
                          onSelected: onAvailabilityChanged,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeatherBadge extends StatelessWidget {
  const _WeatherBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: AppColors.carbonBlack.withValues(alpha: 0.48),
      borderRadius: AppRadius.pillRadius,
      border: Border.all(color: AppColors.borderStrong),
    ),
    child: const Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Icon(Icons.wb_sunny_outlined, size: 18),
        SizedBox(width: AppSpacing.xs),
        Text('24° · CLEAR'),
      ],
    ),
  );
}

class _NextMatch extends StatelessWidget {
  const _NextMatch({required this.onFindMatch});

  final VoidCallback onFindMatch;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.carbonBlack.withValues(alpha: 0.62),
      borderRadius: AppRadius.large,
      border: Border.all(
        color: AppColors.electricGreen.withValues(alpha: 0.24),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Row(
          children: <Widget>[
            Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: AppColors.electricGreen,
            ),
            SizedBox(width: AppSpacing.xs),
            Expanded(child: Text('NEXT MATCH · TODAY 7:30 PM')),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Padelverse Clifton',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            key: const Key('find-match-button'),
            onPressed: onFindMatch,
            child: const Text('FIND A MATCH'),
          ),
        ),
      ],
    ),
  );
}

class _CourtGlow extends CustomPainter {
  const _CourtGlow();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.electricGreen.withValues(alpha: 0.055)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final court = Rect.fromLTWH(
      size.width * 0.46,
      -size.height * 0.08,
      size.width * 0.64,
      size.height * 0.82,
    );
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(court, const Radius.circular(AppSpacing.lg)),
        paint,
      )
      ..drawLine(court.centerLeft, court.centerRight, paint)
      ..drawLine(
        Offset(court.center.dx, court.top),
        Offset(court.center.dx, court.bottom),
        paint,
      );
  }

  @override
  bool shouldRepaint(_CourtGlow oldDelegate) => false;
}
