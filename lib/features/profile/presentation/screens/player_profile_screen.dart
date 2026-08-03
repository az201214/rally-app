import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/app_routes.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/rally_snackbar.dart';
import '../../../../shared/widgets/rally_text_field.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_spacing.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../application/profile_controller.dart';
import '../../domain/player_profile.dart';
import '../../domain/profile_failure.dart';

class PlayerProfileScreen extends ConsumerWidget {
  const PlayerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentPlayerProfileProvider);
    return Scaffold(
      backgroundColor: AppColors.carbonBlack,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: profile.when(
              loading: () => const _ProfileStatus(
                key: Key('profile-loading'),
                child: LoadingIndicator.large(),
              ),
              error: (error, _) => _ProfileStatus(
                key: const Key('profile-error'),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.cloud_off_rounded,
                      color: AppColors.electricGreen,
                      size: 44,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      error is ProfileFailure
                          ? error.message
                          : 'Your profile could not be loaded.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton.icon(
                      key: const Key('profile-retry-button'),
                      onPressed: () =>
                          ref.invalidate(currentPlayerProfileProvider),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('RETRY'),
                    ),
                  ],
                ),
              ),
              data: (value) => value == null
                  ? _ProfileStatus(
                      key: const Key('profile-empty'),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(
                            Icons.person_add_alt_1_rounded,
                            color: AppColors.electricGreen,
                            size: 44,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const Text(
                            'Your player profile is missing.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          FilledButton(
                            onPressed: () =>
                                ref.invalidate(currentPlayerProfileProvider),
                            child: const Text('TRY AGAIN'),
                          ),
                        ],
                      ),
                    )
                  : _ProfileContent(profile: value),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileStatus extends StatelessWidget {
  const _ProfileStatus({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: AppSpacing.screenPadding,
    child: Center(child: child),
  );
}

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({required this.profile});

  final PlayerProfile profile;

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      backgroundColor: AppColors.surfaceElevated,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'LOG OUT OF RALLY?',
              style: Theme.of(
                sheetContext,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'You’ll need to log in again to access your player profile.',
              style: Theme.of(sheetContext).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              key: const Key('confirm-logout-button'),
              label: 'Log out',
              onPressed: () => Navigator.of(sheetContext).pop(true),
            ),
            TextButton(
              onPressed: () => Navigator.of(sheetContext).pop(false),
              child: const Text('CANCEL'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final success = await ref
        .read(authActionControllerProvider.notifier)
        .logout();
    if (!context.mounted || success) return;
    RallySnackbar.show(
      context,
      message: userFacingAuthError(
        ref.read(authActionControllerProvider).error ?? const Object(),
      ),
      icon: Icons.error_outline_rounded,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
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
              Row(
                children: <Widget>[
                  IconButton.filledTonal(
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go(AppRoutes.home),
                    tooltip: 'Back',
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: Text(
                      'PLAYER PROFILE',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    key: const Key('logout-button'),
                    onPressed: () => _logout(context, ref),
                    tooltip: 'Log out',
                    icon: const Icon(Icons.logout_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _IdentityCard(profile: profile),
              if (!profile.isComplete) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                const _IncompleteProfileCard(),
              ],
              const SizedBox(height: AppSpacing.md),
              _SectionCard(
                title: 'RALLY PERFORMANCE',
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: _Metric(
                        value: '${profile.matchesPlayed}',
                        label: 'MATCHES',
                      ),
                    ),
                    const _Divider(),
                    Expanded(
                      child: _Metric(
                        value: profile.rating == 0
                            ? '—'
                            : profile.rating.toStringAsFixed(1),
                        label: 'RATING',
                      ),
                    ),
                    const _Divider(),
                    Expanded(
                      child: _Metric(
                        value: '${profile.reliabilityScore.round()}%',
                        label: 'RELIABLE',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _SectionCard(
                title: 'PLAY STYLE',
                child: Column(
                  children: <Widget>[
                    _Attribute(
                      icon: Icons.swap_horiz_rounded,
                      label: 'Preferred side',
                      value: profile.preferredSide,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _Attribute(
                      icon: Icons.speed_rounded,
                      label: 'Playing style',
                      value: profile.playingStyle,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _Attribute(
                      icon: Icons.location_city_rounded,
                      label: 'City',
                      value: profile.city.isEmpty ? 'Not set' : profile.city,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _Attribute(
                      icon: Icons.radar_rounded,
                      label: 'Search radius',
                      value: '${profile.searchRadiusKm} km',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 56,
                child: OutlinedButton.icon(
                  key: const Key('profile-find-match-button'),
                  onPressed: () => context.push(AppRoutes.searching),
                  icon: const Icon(Icons.sports_tennis_rounded),
                  label: const Text('FIND A MATCH'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              PrimaryButton(
                key: const Key('edit-profile-button'),
                label: 'Edit profile',
                icon: Icons.edit_rounded,
                onPressed: () => _showEditProfile(context, ref, profile),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 58,
                child: FilledButton.icon(
                  key: const Key('view-club-button'),
                  onPressed: profile.homeClubId.isEmpty
                      ? null
                      : () => context.push(AppRoutes.clubDetails),
                  icon: const Icon(Icons.stadium_rounded),
                  label: const Text('VIEW HOME CLUB'),
                ),
              ),
              TextButton.icon(
                key: const Key('profile-safety-button'),
                onPressed: () => _showSafetyActions(context),
                icon: const Icon(Icons.shield_outlined),
                label: const Text('REPORT OR BLOCK'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showSafetyActions(
    BuildContext context,
  ) => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('PLAYER SAFETY', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Reports are reviewed privately. Blocking prevents future match recommendations.',
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.flag_outlined),
            label: const Text('REPORT PLAYER'),
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.block_rounded),
            label: const Text('BLOCK PLAYER'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
        ],
      ),
    ),
  );
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.profile});

  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    final initials = profile.fullName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: AppRadius.xLarge,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF16251F), AppColors.surfaceSecondary],
        ),
        border: Border.all(
          color: AppColors.electricGreen.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: <Widget>[
          Semantics(
            image: true,
            label: '${profile.fullName} profile photo',
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                CircleAvatar(
                  radius: 72,
                  backgroundColor: const Color(0xFF3B5148),
                  backgroundImage: profile.photoUrl.isEmpty
                      ? null
                      : NetworkImage(profile.photoUrl),
                  child: profile.photoUrl.isEmpty
                      ? Text(
                          initials.isEmpty ? '?' : initials,
                          style: Theme.of(context).textTheme.displayMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        )
                      : null,
                ),
                if (profile.isVerified)
                  const Positioned(
                    right: 0,
                    bottom: 4,
                    child: CircleAvatar(
                      radius: 17,
                      backgroundColor: AppColors.electricGreen,
                      child: Icon(
                        Icons.check_rounded,
                        size: 17,
                        color: AppColors.textInverse,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            profile.fullName.isEmpty
                ? 'PLAYER PROFILE'
                : profile.fullName.toUpperCase(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '${profile.skillLevel} · ${profile.preferredSide}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: <Widget>[
              _Pill(
                icon: Icons.star_rounded,
                label: profile.rating == 0
                    ? 'Not rated'
                    : '${profile.rating.toStringAsFixed(1)} rating',
              ),
              _Pill(
                icon: Icons.verified_user_rounded,
                label: '${profile.reliabilityScore.round()}% reliable',
              ),
              _Pill(
                icon: Icons.place_rounded,
                label: profile.city.isEmpty ? 'City not set' : profile.city,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IncompleteProfileCard extends StatelessWidget {
  const _IncompleteProfileCard();

  @override
  Widget build(BuildContext context) => const _SectionCard(
    title: 'COMPLETE YOUR PROFILE',
    child: Text(
      'Add your city and home club so Rally can prepare better matches.',
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: AppRadius.pillRadius,
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 15, color: AppColors.electricGreen),
        const SizedBox(width: AppSpacing.xxs),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      Text(
        value,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w900,
        ),
      ),
      Text(label, style: Theme.of(context).textTheme.labelSmall),
    ],
  );
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 44,
    child: VerticalDivider(color: AppColors.borderSubtle),
  );
}

class _Attribute extends StatelessWidget {
  const _Attribute({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Icon(icon, color: AppColors.electricGreen, size: 20),
      const SizedBox(width: AppSpacing.sm),
      Expanded(child: Text(label)),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
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
          title,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    ),
  );
}

Future<void> _showEditProfile(
  BuildContext context,
  WidgetRef ref,
  PlayerProfile profile,
) async {
  final name = TextEditingController(text: profile.fullName);
  final club = TextEditingController(text: profile.homeClubId);
  final city = TextEditingController(text: profile.city);
  var skill = profile.skillLevel;
  var side = profile.preferredSide;
  var style = profile.playingStyle;
  var radius = profile.searchRadiusKm.toDouble().clamp(1.0, 50.0);
  final updated = await showModalBottomSheet<PlayerProfile>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surfaceElevated,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'EDIT PLAYER PROFILE',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: AppSpacing.lg),
            RallyTextField(controller: name, labelText: 'Full name'),
            const SizedBox(height: AppSpacing.md),
            _ProfileDropdown(
              label: 'Skill level',
              value: skill,
              values: const <String>['Beginner', 'Intermediate', 'Advanced'],
              onChanged: (value) => setSheetState(() => skill = value),
            ),
            const SizedBox(height: AppSpacing.md),
            _ProfileDropdown(
              label: 'Preferred side',
              value: side,
              values: const <String>['No preference', 'Left', 'Right'],
              onChanged: (value) => setSheetState(() => side = value),
            ),
            const SizedBox(height: AppSpacing.md),
            _ProfileDropdown(
              label: 'Playing style',
              value: style,
              values: const <String>['Balanced', 'Attacking', 'Defensive'],
              onChanged: (value) => setSheetState(() => style = value),
            ),
            const SizedBox(height: AppSpacing.md),
            RallyTextField(controller: club, labelText: 'Home club'),
            const SizedBox(height: AppSpacing.md),
            RallyTextField(controller: city, labelText: 'City'),
            const SizedBox(height: AppSpacing.md),
            Text('Search radius: ${radius.round()} km'),
            Slider(
              value: radius,
              min: 1,
              max: 50,
              divisions: 49,
              onChanged: (value) => setSheetState(() => radius = value),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              key: const Key('save-profile-button'),
              label: 'Save profile',
              onPressed: name.text.trim().isEmpty
                  ? null
                  : () => Navigator.of(sheetContext).pop(
                      profile.copyWith(
                        fullName: name.text.trim(),
                        skillLevel: skill,
                        preferredSide: side,
                        playingStyle: style,
                        homeClubId: club.text.trim(),
                        city: city.text.trim(),
                        searchRadiusKm: radius.round(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    ),
  );
  name.dispose();
  club.dispose();
  city.dispose();
  if (updated == null || !context.mounted) return;
  final success = await ref
      .read(profileUpdateControllerProvider.notifier)
      .saveProfile(updated);
  if (!context.mounted) return;
  RallySnackbar.show(
    context,
    message: success
        ? 'Player profile updated.'
        : ref.read(profileUpdateControllerProvider).error is ProfileFailure
        ? (ref.read(profileUpdateControllerProvider).error! as ProfileFailure)
              .message
        : 'Your profile could not be updated. Please try again.',
    icon: success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
  );
}

class _ProfileDropdown extends StatelessWidget {
  const _ProfileDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });
  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    initialValue: values.contains(value) ? value : values.first,
    decoration: InputDecoration(labelText: label),
    items: values
        .map((item) => DropdownMenuItem(value: item, child: Text(item)))
        .toList(),
    onChanged: (value) {
      if (value != null) onChanged(value);
    },
  );
}
