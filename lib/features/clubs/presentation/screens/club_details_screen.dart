import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/app_routes.dart';
import '../../../../shared/widgets/rally_snackbar.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_spacing.dart';
import '../../application/club_providers.dart';
import '../../domain/club.dart';

class ClubDetailsScreen extends ConsumerWidget {
  const ClubDetailsScreen({this.clubId = 'padelverse-clifton', super.key});
  final String clubId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubs = ref.watch(clubDiscoveryProvider);
    return Scaffold(
      backgroundColor: AppColors.carbonBlack,
      appBar: AppBar(title: const Text('CLUB DETAILS')),
      body: SafeArea(
        child: clubs.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) =>
              _Error(onRetry: () => ref.invalidate(clubDiscoveryProvider)),
          data: (data) {
            final nearby =
                data.clubs
                    .where((item) => item.club.id == clubId)
                    .firstOrNull ??
                data.clubs.firstOrNull;
            return nearby == null
                ? _Error(
                    onRetry: () => ref.invalidate(clubDiscoveryProvider),
                    message: 'This club is no longer available.',
                  )
                : _ClubContent(
                    nearby: nearby,
                    hasLocation: data.position != null,
                  );
          },
        ),
      ),
    );
  }
}

class _ClubContent extends ConsumerWidget {
  const _ClubContent({required this.nearby, required this.hasLocation});
  final NearbyClub nearby;
  final bool hasLocation;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final club = nearby.club;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              sliver: SliverList.list(
                children: [
                  _PhotoHero(club: club),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    club.name.split(' ').first.toUpperCase(),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.electricGreen,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    club.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(club.address),
                  const SizedBox(height: AppSpacing.md),
                  const _InfoCard(
                    icon: Icons.bolt_rounded,
                    title: 'CLUB PULSE',
                    detail: '18 players ready tonight',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _Fact(
                        icon: Icons.sports_tennis_rounded,
                        label: '${club.courtCount} courts',
                      ),
                      _Fact(
                        icon: Icons.star_rounded,
                        label: club.rating.toStringAsFixed(1),
                      ),
                      if (hasLocation)
                        _Fact(
                          icon: Icons.near_me_rounded,
                          label:
                              '${nearby.distanceKm.toStringAsFixed(1)} km · ~${nearby.estimatedTravelMinutes} min',
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _InfoCard(
                    icon: Icons.schedule_rounded,
                    title: 'OPENING HOURS',
                    detail: club.openingHours,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _InfoCard(
                    icon: Icons.call_outlined,
                    title: 'CONTACT',
                    detail: '${club.phone}\n${club.email}',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _InfoCard(
                    icon: Icons.check_circle_outline_rounded,
                    title: 'AMENITIES',
                    detail: club.amenities.join(' · '),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    key: const Key('club-directions-button'),
                    onPressed: () async {
                      final opened = await ref
                          .read(clubNavigationServiceProvider)
                          .openDirections(club);
                      if (!opened && context.mounted) {
                        RallySnackbar.show(
                          context,
                          message: 'Google Maps could not be opened.',
                          icon: Icons.map_outlined,
                        );
                      }
                    },
                    icon: const Icon(Icons.directions_rounded),
                    label: const Text('NAVIGATE WITH GOOGLE MAPS'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const Key('club-contact-button'),
                          onPressed: club.phone.isEmpty
                              ? null
                              : () => ref
                                    .read(clubNavigationServiceProvider)
                                    .call(club.phone),
                          icon: const Icon(Icons.call_outlined),
                          label: const Text('CALL'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: club.email.isEmpty
                              ? null
                              : () => ref
                                    .read(clubNavigationServiceProvider)
                                    .email(club.email),
                          icon: const Icon(Icons.email_outlined),
                          label: const Text('EMAIL'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FilledButton.icon(
                    key: const Key('club-book-button'),
                    onPressed: () => _showBookingConfirmation(context),
                    icon: const Icon(Icons.event_available_rounded),
                    label: const Text('BOOK COURT'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    key: const Key('club-find-match-button'),
                    onPressed: () => context.go(AppRoutes.searching),
                    icon: const Icon(Icons.sports_tennis_rounded),
                    label: const Text('FIND A MATCH HERE'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBookingConfirmation(
    BuildContext context,
  ) => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 52,
            color: AppColors.electricGreen,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('COURT RESERVED', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Your court request is ready. Confirm availability directly with the club.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('VIEW CLUB'),
          ),
        ],
      ),
    ),
  );
}

class _PhotoHero extends StatelessWidget {
  const _PhotoHero({required this.club});
  final Club club;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '${club.name} club photo',
    image: true,
    child: ClipRRect(
      borderRadius: AppRadius.xLarge,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: club.photoUrls.isEmpty
            ? Container(
                color: AppColors.surfaceElevated,
                child: const Icon(
                  Icons.stadium_rounded,
                  size: 72,
                  color: AppColors.electricGreen,
                ),
              )
            : CachedNetworkImage(
                imageUrl: club.photoUrls.first,
                fit: BoxFit.cover,
                placeholder: (_, _) =>
                    Container(color: AppColors.surfaceElevated),
                errorWidget: (_, _, _) => Container(
                  color: AppColors.surfaceElevated,
                  child: const Icon(Icons.broken_image_outlined),
                ),
              ),
      ),
    ),
  );
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: AppColors.surfaceSecondary,
      borderRadius: AppRadius.pillRadius,
      border: Border.all(color: AppColors.borderSubtle),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.electricGreen),
        const SizedBox(width: AppSpacing.xxs),
        Text(label),
      ],
    ),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.detail,
  });
  final IconData icon;
  final String title;
  final String detail;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surfaceSecondary,
      borderRadius: AppRadius.large,
      border: Border.all(color: AppColors.borderSubtle),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.electricGreen),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: AppSpacing.xxs),
              Text(detail, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Error extends StatelessWidget {
  const _Error({
    required this.onRetry,
    this.message = 'Club details could not be loaded.',
  });
  final VoidCallback onRetry;
  final String message;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.cloud_off_rounded,
          color: AppColors.electricGreen,
          size: 48,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(message),
        const SizedBox(height: AppSpacing.md),
        FilledButton(onPressed: onRetry, child: const Text('RETRY')),
      ],
    ),
  );
}
