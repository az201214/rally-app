import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/app_routes.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_spacing.dart';

class ClubDetailsScreen extends StatelessWidget {
  const ClubDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.carbonBlack,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: CustomScrollView(
              slivers: <Widget>[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  sliver: SliverList.list(
                    children: <Widget>[
                      _Header(
                        onBack: () => context.canPop()
                            ? context.pop()
                            : context.go(AppRoutes.playerProfile),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const _ClubHero(),
                      const SizedBox(height: AppSpacing.md),
                      const _QuickFacts(),
                      const SizedBox(height: AppSpacing.md),
                      const _ClubPulseCard(),
                      const SizedBox(height: AppSpacing.md),
                      const _AmenitiesCard(),
                      const SizedBox(height: AppSpacing.md),
                      const _OpeningHoursCard(),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton.icon(
                              key: const Key('club-directions-button'),
                              onPressed: () => _showClubSheet(
                                context,
                                title: 'DIRECTIONS',
                                icon: Icons.map_rounded,
                                detail:
                                    'Khayaban-e-Saadi, Clifton, Karachi\n2.4 km · approximately 12 minutes',
                              ),
                              icon: const Icon(Icons.directions_rounded),
                              label: const Text('MAP'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: OutlinedButton.icon(
                              key: const Key('club-contact-button'),
                              onPressed: () => _showClubSheet(
                                context,
                                title: 'CONTACT CLUB',
                                icon: Icons.call_rounded,
                                detail: '+92 21 3587 2400\nhello@padelverse.pk',
                              ),
                              icon: const Icon(Icons.call_outlined),
                              label: const Text('CALL'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        height: 58,
                        child: FilledButton.icon(
                          key: const Key('club-book-button'),
                          onPressed: () => _showBookingConfirmation(context),
                          icon: const Icon(Icons.event_available_rounded),
                          label: const Text('BOOK COURT'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        height: 58,
                        child: FilledButton.icon(
                          key: const Key('club-find-match-button'),
                          onPressed: () => context.go(AppRoutes.searching),
                          icon: const Icon(Icons.sports_tennis_rounded),
                          label: const Text('FIND A MATCH HERE'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton.icon(
                        onPressed: () => context.go(AppRoutes.home),
                        icon: const Icon(Icons.home_rounded),
                        label: const Text('BACK TO HOME'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showClubSheet(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String detail,
  }) => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 44, color: AppColors.electricGreen),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(detail, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('DONE'),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _showBookingConfirmation(
    BuildContext context,
  ) => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.check_circle_rounded,
            size: 52,
            color: AppColors.electricGreen,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('COURT RESERVED', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Court 03 is held for today at 7:30 PM.\nPayment will be handled at the club.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('VIEW CLUB'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        IconButton.filledTonal(
          onPressed: onBack,
          tooltip: 'Back to player profile',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'CLUB DETAILS',
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }
}

class _ClubHero extends StatelessWidget {
  const _ClubHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 260),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: AppRadius.xLarge,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF183026),
            Color(0xFF0D1720),
            AppColors.surfaceSecondary,
          ],
        ),
        border: Border.all(
          color: AppColors.electricGreen.withValues(alpha: 0.2),
        ),
      ),
      child: Stack(
        children: <Widget>[
          const Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: _CourtPainter())),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.electricGreen.withValues(alpha: 0.12),
                  borderRadius: AppRadius.large,
                ),
                child: const Icon(
                  Icons.stadium_rounded,
                  color: AppColors.electricGreen,
                  size: 28,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              Text(
                'PADELVERSE',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.8,
                ),
              ),
              Text(
                'CLIFTON',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.electricGreen,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Premium indoor padel in the heart of Karachi.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.78),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickFacts extends StatelessWidget {
  const _QuickFacts();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: <Widget>[
        Expanded(
          child: _Fact(
            icon: Icons.sports_tennis_rounded,
            value: '6',
            label: 'COURTS',
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _Fact(icon: Icons.star_rounded, value: '4.8', label: 'RATING'),
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _Fact(
            icon: Icons.near_me_rounded,
            value: '2.4 km',
            label: 'AWAY',
          ),
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: AppRadius.large,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, color: AppColors.electricGreen, size: 19),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            maxLines: 1,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClubPulseCard extends StatelessWidget {
  const _ClubPulseCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.electricGreen.withValues(alpha: 0.06),
        borderRadius: AppRadius.large,
        border: Border.all(
          color: AppColors.electricGreen.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.electricGreen.withValues(alpha: 0.12),
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: AppColors.electricGreen,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '18 players ready tonight',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Peak Rally window: 7:00–10:00 PM',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AmenitiesCard extends StatelessWidget {
  const _AmenitiesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: AppRadius.large,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'CLUB AMENITIES',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: <Widget>[
              _Amenity(icon: Icons.ac_unit_rounded, label: 'Indoor AC'),
              _Amenity(icon: Icons.local_parking_rounded, label: 'Parking'),
              _Amenity(icon: Icons.shower_rounded, label: 'Showers'),
              _Amenity(icon: Icons.local_cafe_rounded, label: 'Café'),
              _Amenity(icon: Icons.shopping_bag_rounded, label: 'Pro shop'),
            ],
          ),
        ],
      ),
    );
  }
}

class _OpeningHoursCard extends StatelessWidget {
  const _OpeningHoursCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surfaceSecondary,
      borderRadius: AppRadius.large,
      border: Border.all(color: AppColors.borderSubtle),
    ),
    child: const Row(
      children: <Widget>[
        Icon(Icons.schedule_rounded),
        SizedBox(width: AppSpacing.sm),
        Expanded(child: Text('OPENING HOURS')),
        Flexible(child: Text('Daily · 6 AM–12 AM', textAlign: TextAlign.end)),
      ],
    ),
  );
}

class _Amenity extends StatelessWidget {
  const _Amenity({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: AppRadius.pillRadius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: AppColors.electricGreen),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CourtPainter extends CustomPainter {
  const _CourtPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.electricGreen.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final rect = Rect.fromLTWH(
      size.width * 0.52,
      size.height * 0.06,
      size.width * 0.45,
      size.height * 0.62,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(AppRadius.md)),
      paint,
    );
    canvas.drawLine(
      Offset(rect.center.dx, rect.top),
      Offset(rect.center.dx, rect.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.center.dy),
      Offset(rect.right, rect.center.dy),
      paint,
    );
  }

  @override
  bool shouldRepaint(_CourtPainter oldDelegate) => false;
}
