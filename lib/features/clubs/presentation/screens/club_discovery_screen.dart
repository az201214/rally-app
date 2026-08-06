import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../routes/app_routes.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_spacing.dart';
import '../../application/club_providers.dart';
import '../../domain/club.dart';
import '../../domain/club_repository.dart';

class ClubDiscoveryScreen extends ConsumerWidget {
  const ClubDiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discovery = ref.watch(clubDiscoveryProvider);
    return Scaffold(
      backgroundColor: AppColors.carbonBlack,
      appBar: AppBar(title: const Text('NEARBY CLUBS')),
      body: SafeArea(
        child: discovery.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _StatePanel(
            icon: Icons.cloud_off_rounded,
            title: 'Clubs are offline',
            detail: 'Check your connection and try again.',
            action: 'RETRY',
            onPressed: () => ref.invalidate(clubDiscoveryProvider),
          ),
          data: (data) => _DiscoveryContent(data: data),
        ),
      ),
    );
  }
}

class _DiscoveryContent extends ConsumerWidget {
  const _DiscoveryContent({required this.data});
  final ClubDiscovery data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (data.clubs.isEmpty) {
      return _StatePanel(
        icon: Icons.stadium_outlined,
        title: 'No clubs nearby',
        detail: 'Rally has no active clubs in this area yet.',
        action: 'REFRESH',
        onPressed: () => ref.invalidate(clubDiscoveryProvider),
      );
    }
    final permissionNeeded = data.permission != LocationPermissionState.granted;
    final banner =
        permissionNeeded || data.locationServiceDisabled || data.message != null
        ? _LocationBanner(
            title: data.locationServiceDisabled
                ? 'GPS is switched off'
                : permissionNeeded
                ? 'Find clubs closest to you'
                : data.message!,
            action: data.permission == LocationPermissionState.deniedForever
                ? 'SETTINGS'
                : permissionNeeded
                ? 'ENABLE LOCATION'
                : 'RETRY',
            onPressed: () =>
                data.permission == LocationPermissionState.deniedForever
                ? ref
                      .read(clubDiscoveryProvider.notifier)
                      .openLocationSettings()
                : ref.read(clubDiscoveryProvider.notifier).requestLocation(),
          )
        : null;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 800;
        final map = _ClubMap(data: data);
        final list = _ClubList(data: data);
        return Column(
          children: [
            ?banner,
            Expanded(
              child: wide
                  ? Row(
                      children: [
                        Expanded(flex: 3, child: map),
                        SizedBox(width: 380, child: list),
                      ],
                    )
                  : Column(
                      children: [
                        Expanded(flex: 5, child: map),
                        Expanded(flex: 4, child: list),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _ClubMap extends StatelessWidget {
  const _ClubMap({required this.data});
  final ClubDiscovery data;
  @override
  Widget build(BuildContext context) {
    final fallback = data.clubs.first.club.position;
    final center = data.position ?? fallback;
    return Semantics(
      label: 'Map showing ${data.clubs.length} padel clubs. Club list follows.',
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(center.latitude, center.longitude),
          zoom: data.position == null ? 11 : 13,
        ),
        myLocationEnabled: data.position != null,
        myLocationButtonEnabled: data.position != null,
        mapToolbarEnabled: false,
        zoomControlsEnabled: false,
        markers: data.clubs
            .map(
              (nearby) => Marker(
                markerId: MarkerId(nearby.club.id),
                position: LatLng(
                  nearby.club.position.latitude,
                  nearby.club.position.longitude,
                ),
                infoWindow: InfoWindow(
                  title: nearby.club.name,
                  snippet: nearby.club.address,
                  onTap: () => context.push(
                    '${AppRoutes.clubDetails}?id=${nearby.club.id}',
                  ),
                ),
              ),
            )
            .toSet(),
      ),
    );
  }
}

class _ClubList extends StatelessWidget {
  const _ClubList({required this.data});
  final ClubDiscovery data;
  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.all(AppSpacing.md),
    itemCount: data.clubs.length,
    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
    itemBuilder: (context, index) {
      final nearby = data.clubs[index];
      return _ClubCard(nearby: nearby, hasLocation: data.position != null);
    },
  );
}

class _ClubCard extends StatelessWidget {
  const _ClubCard({required this.nearby, required this.hasLocation});
  final NearbyClub nearby;
  final bool hasLocation;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label:
        '${nearby.club.name}, ${nearby.club.courtCount} courts${hasLocation ? ', ${nearby.distanceKm.toStringAsFixed(1)} kilometres away' : ''}',
    child: Material(
      color: AppColors.surfaceSecondary,
      borderRadius: AppRadius.large,
      child: InkWell(
        onTap: () =>
            context.push('${AppRoutes.clubDetails}?id=${nearby.club.id}'),
        borderRadius: AppRadius.large,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.accentTertiary,
                  borderRadius: AppRadius.medium,
                ),
                child: const Icon(
                  Icons.stadium_rounded,
                  color: AppColors.electricGreen,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nearby.club.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${nearby.club.courtCount} courts · ${nearby.club.rating.toStringAsFixed(1)} rating',
                    ),
                    if (hasLocation)
                      Text(
                        '${nearby.distanceKm.toStringAsFixed(1)} km · ~${nearby.estimatedTravelMinutes} min drive',
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    ),
  );
}

class _LocationBanner extends StatelessWidget {
  const _LocationBanner({
    required this.title,
    required this.action,
    required this.onPressed,
  });
  final String title;
  final String action;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.sm,
      AppSpacing.md,
      0,
    ),
    padding: const EdgeInsets.all(AppSpacing.sm),
    decoration: BoxDecoration(
      color: AppColors.surfaceElevated,
      borderRadius: AppRadius.medium,
      border: Border.all(color: AppColors.borderSubtle),
    ),
    child: Row(
      children: [
        const Icon(Icons.location_on_outlined, color: AppColors.electricGreen),
        const SizedBox(width: AppSpacing.xs),
        Expanded(child: Text(title)),
        TextButton(onPressed: onPressed, child: Text(action)),
      ],
    ),
  );
}

class _StatePanel extends StatelessWidget {
  const _StatePanel({
    required this.icon,
    required this.title,
    required this.detail,
    required this.action,
    required this.onPressed,
  });
  final IconData icon;
  final String title;
  final String detail;
  final String action;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: AppColors.electricGreen),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(detail, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(onPressed: onPressed, child: Text(action)),
        ],
      ),
    ),
  );
}
