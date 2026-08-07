import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../routes/app_routes.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/rally_snackbar.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_spacing.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../clubs/application/club_providers.dart';
import '../../../clubs/domain/club.dart';
import '../../../matchmaking/domain/matchmaking_models.dart';
import '../../application/profile_controller.dart';
import '../../domain/player_profile.dart';
import '../../domain/profile_failure.dart';
import '../../domain/profile_insights.dart';

class PlayerProfileScreen extends ConsumerWidget {
  const PlayerProfileScreen({this.playerId, super.key});
  final String? playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUid = ref.watch(authStateProvider).value?.uid;
    final targetUid = playerId?.trim().isNotEmpty == true ? playerId! : authUid;
    final isOwner = targetUid != null && targetUid == authUid;
    final profile = targetUid == null
        ? const AsyncData<PlayerProfile?>(null)
        : isOwner
        ? ref.watch(currentPlayerProfileProvider)
        : ref.watch(publicPlayerProfileProvider(targetUid));
    return Scaffold(
      backgroundColor: AppColors.carbonBlack,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: profile.when(
              loading: () => const _Status(
                key: Key('profile-loading'),
                child: LoadingIndicator.large(),
              ),
              error: (error, _) => _Status(
                key: const Key('profile-error'),
                child: _ErrorState(
                  message: error is ProfileFailure
                      ? error.message
                      : 'This player profile could not be loaded.',
                  onRetry: () => isOwner
                      ? ref.invalidate(currentPlayerProfileProvider)
                      : ref.invalidate(publicPlayerProfileProvider(targetUid!)),
                ),
              ),
              data: (value) => value == null
                  ? const _Status(
                      key: Key('profile-empty'),
                      child: _MissingProfile(),
                    )
                  : _ProfileContent(profile: value, isOwner: isOwner),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({required this.profile, required this.isOwner});
  final PlayerProfile profile;
  final bool isOwner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(profileMatchHistoryProvider(profile.uid));
    final statistics = ref.watch(profileStatisticsProvider(profile.uid));
    final clubs = ref.watch(favoriteClubsProvider(profile));
    return RefreshIndicator(
      onRefresh: () async {
        isOwner
            ? ref.invalidate(currentPlayerProfileProvider)
            : ref.invalidate(publicPlayerProfileProvider(profile.uid));
        ref.invalidate(profileMatchHistoryProvider(profile.uid));
        ref.invalidate(favoriteClubsProvider(profile));
      },
      child: CustomScrollView(
        key: const Key('profile-scroll'),
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
                _Header(
                  isOwner: isOwner,
                  onLogout: () => _logout(context, ref),
                ),
                const SizedBox(height: AppSpacing.lg),
                _Hero(
                  profile: profile,
                  isOwner: isOwner,
                  reliability:
                      statistics.value?.reliabilityScore ??
                      profile.reliabilityScore,
                  onEdit: () => _edit(context, ref, profile),
                ),
                if (isOwner && !profile.isComplete) ...[
                  const SizedBox(height: AppSpacing.md),
                  _CompletionCard(
                    profile: profile,
                    onComplete: () => _edit(context, ref, profile),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                statistics.when(
                  loading: () => const _Section(
                    title: 'PERFORMANCE OVERVIEW',
                    child: LinearProgressIndicator(),
                  ),
                  error: (_, _) => _RetrySection(
                    title: 'PERFORMANCE OVERVIEW',
                    onRetry: () => ref.invalidate(
                      profileMatchHistoryProvider(profile.uid),
                    ),
                  ),
                  data: (stats) => Column(
                    children: [
                      _Performance(stats: stats),
                      const SizedBox(height: AppSpacing.md),
                      _Reliability(stats: stats),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _PlayingProfile(profile: profile),
                const SizedBox(height: AppSpacing.md),
                _MatchHistory(history: history),
                const SizedBox(height: AppSpacing.md),
                _FavoriteClubs(profile: profile, clubs: clubs),
                const SizedBox(height: AppSpacing.md),
                statistics.maybeWhen(
                  data: (stats) =>
                      _Achievements(profile: profile, statistics: stats),
                  orElse: () => const SizedBox.shrink(),
                ),
                if (isOwner) ...[
                  const SizedBox(height: AppSpacing.md),
                  _OwnerActions(
                    onEdit: () => _edit(context, ref, profile),
                    onFindMatch: () => context.push(AppRoutes.searching),
                    onViewClub: profile.homeClubId.isEmpty
                        ? null
                        : () => context.push(
                            '${AppRoutes.clubDetails}?id=${profile.homeClubId}',
                          ),
                    onLogout: () => _logout(context, ref),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    PlayerProfile profile,
  ) async {
    final availableClubs = await ref
        .read(clubRepositoryProvider)
        .watchClubs()
        .first;
    if (!context.mounted) return;
    final updated = await showModalBottomSheet<PlayerProfile>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surfaceElevated,
      builder: (_) =>
          _EditProfileSheet(profile: profile, clubs: availableClubs),
    );
    if (updated == null || !context.mounted) return;
    final success = await ref
        .read(profileUpdateControllerProvider.notifier)
        .saveProfile(updated);
    if (!context.mounted) return;
    RallySnackbar.show(
      context,
      message: success
          ? 'Player profile updated.'
          : _profileError(ref.read(profileUpdateControllerProvider).error),
      icon: success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out of Rally?'),
        content: const Text(
          'You will need to sign in again to access your player profile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            key: const Key('confirm-logout-button'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('LOG OUT'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authActionControllerProvider.notifier).logout();
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isOwner, required this.onLogout});
  final bool isOwner;
  final VoidCallback onLogout;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton.filledTonal(
        onPressed: () =>
            context.canPop() ? context.pop() : context.go(AppRoutes.home),
        tooltip: 'Back',
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      Expanded(
        child: Text(
          isOwner ? 'YOUR PLAYER PROFILE' : 'PLAYER PROFILE',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            letterSpacing: 1.2,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      if (isOwner)
        IconButton.filledTonal(
          key: const Key('logout-button'),
          onPressed: onLogout,
          tooltip: 'Log out',
          icon: const Icon(Icons.logout_rounded),
        )
      else
        const SizedBox(width: 48),
    ],
  );
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.profile,
    required this.isOwner,
    required this.reliability,
    required this.onEdit,
  });
  final PlayerProfile profile;
  final bool isOwner;
  final double reliability;
  final VoidCallback onEdit;
  @override
  Widget build(BuildContext context) {
    final initials = profile.fullName
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .take(2)
        .map((e) => e[0].toUpperCase())
        .join();
    return _Section(
      title: 'PLAYER IDENTITY',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          final avatar = Semantics(
            image: true,
            label: '${profile.fullName} profile photo',
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 54,
                  backgroundColor: AppColors.accentTertiary,
                  backgroundImage: profile.photoUrl.isEmpty
                      ? null
                      : NetworkImage(profile.photoUrl),
                  child: profile.photoUrl.isEmpty
                      ? Text(
                          initials.isEmpty ? '?' : initials,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        )
                      : null,
                ),
                if (profile.hasTrustedVerification)
                  const Positioned(
                    right: 0,
                    bottom: 0,
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: AppColors.electricGreen,
                      child: Icon(
                        Icons.verified_rounded,
                        size: 17,
                        color: AppColors.textInverse,
                      ),
                    ),
                  ),
              ],
            ),
          );
          final identity = Column(
            crossAxisAlignment: compact
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              Text(
                profile.fullName.isEmpty
                    ? 'RALLY PLAYER'
                    : profile.fullName.toUpperCase(),
                textAlign: compact ? TextAlign.center : TextAlign.start,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                profile.bio.isEmpty ? 'No player bio yet.' : profile.bio,
                textAlign: compact ? TextAlign.center : TextAlign.start,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                alignment: compact ? WrapAlignment.center : WrapAlignment.start,
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  _Pill(Icons.sports_tennis_rounded, profile.skillLevel),
                  _Pill(
                    Icons.verified_user_outlined,
                    '${reliability.round()}% reliable',
                  ),
                  _Pill(
                    Icons.place_outlined,
                    profile.city.isEmpty ? 'City not set' : profile.city,
                  ),
                  _Pill(
                    Icons.verified_user_outlined,
                    profile.hasTrustedVerification
                        ? 'Verified player'
                        : 'Not verified',
                  ),
                  _Pill(
                    Icons.calendar_month_outlined,
                    profile.createdAt.year <= 1970
                        ? 'Join date unavailable'
                        : 'Member since ${DateFormat.yMMM().format(profile.createdAt)}',
                  ),
                ],
              ),
              if (isOwner) ...[
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  key: const Key('edit-profile-button'),
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('EDIT PROFILE'),
                ),
              ],
            ],
          );
          return compact
              ? Column(
                  children: [
                    avatar,
                    const SizedBox(height: AppSpacing.md),
                    identity,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    avatar,
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(child: identity),
                  ],
                );
        },
      ),
    );
  }
}

class _CompletionCard extends StatelessWidget {
  const _CompletionCard({required this.profile, required this.onComplete});
  final PlayerProfile profile;
  final VoidCallback onComplete;
  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return _Section(
      title: 'PROFILE COMPLETION',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${profile.profileCompletion}% complete',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton(onPressed: onComplete, child: const Text('COMPLETE')),
            ],
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(
              begin: reduced ? profile.profileCompletion / 100 : 0,
              end: profile.profileCompletion / 100,
            ),
            duration: reduced
                ? Duration.zero
                : const Duration(milliseconds: 280),
            builder: (_, value, _) => LinearProgressIndicator(value: value),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Add ${profile.missingProfileFields.join(', ')}.'),
        ],
      ),
    );
  }
}

class _Performance extends StatelessWidget {
  const _Performance({required this.stats});
  final ProfileStatistics stats;
  @override
  Widget build(BuildContext context) => _Section(
    title: 'PERFORMANCE OVERVIEW',
    child: LayoutBuilder(
      builder: (_, constraints) {
        final columns = constraints.maxWidth >= 600 ? 3 : 2;
        final values = <(String, String)>[
          ('${stats.totalMatches}', 'TOTAL MATCHES'),
          ('${stats.completedMatches}', 'COMPLETED'),
          ('${stats.reliabilityScore.round()}%', 'RELIABILITY'),
          ('${stats.matchesThisMonth}', 'THIS MONTH'),
          (
            stats.averageMatchScore?.toStringAsFixed(0) ?? '—',
            'AVG MATCH SCORE',
          ),
          ('${stats.uniquePlayersMet}', 'PLAYERS MET'),
        ];
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: values.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: AppSpacing.xs,
            crossAxisSpacing: AppSpacing.xs,
            mainAxisExtent: 76,
          ),
          itemBuilder: (_, index) =>
              _Metric(values[index].$1, values[index].$2),
        );
      },
    ),
  );
}

class _Reliability extends StatelessWidget {
  const _Reliability({required this.stats});
  final ProfileStatistics stats;
  @override
  Widget build(BuildContext context) => _Section(
    title: 'RELIABILITY BREAKDOWN',
    child: Column(
      children: [
        _Attribute(
          Icons.check_circle_outline,
          'Completed',
          '${stats.completedMatches}',
        ),
        _Attribute(
          Icons.event_busy_outlined,
          'Cancelled',
          '${stats.cancelledMatches}',
        ),
        _Attribute(Icons.person_off_outlined, 'No-show', '${stats.noShows}'),
        _Attribute(
          Icons.how_to_reg_outlined,
          'Accepted',
          '${stats.acceptedMatches}',
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Reliability is based on completed matches compared with cancellations and recorded no-shows. New players begin at 100% until a match is decided.',
        ),
      ],
    ),
  );
}

class _PlayingProfile extends StatelessWidget {
  const _PlayingProfile({required this.profile});
  final PlayerProfile profile;
  @override
  Widget build(BuildContext context) => _Section(
    title: 'PLAYING PROFILE',
    child: Column(
      children: [
        _Attribute(Icons.speed_rounded, 'Skill level', profile.skillLevel),
        _Attribute(
          Icons.sports_handball_outlined,
          'Playing hand',
          profile.playingHand,
        ),
        _Attribute(
          Icons.swap_horiz_rounded,
          'Preferred side',
          profile.preferredSide,
        ),
        _Attribute(Icons.bolt_outlined, 'Playing style', profile.playingStyle),
        _Attribute(
          Icons.calendar_today_outlined,
          'Preferred days',
          profile.preferredDays.isEmpty
              ? 'Not set'
              : profile.preferredDays.join(', '),
        ),
        _Attribute(
          Icons.schedule_outlined,
          'Preferred times',
          profile.preferredTimeRanges.isEmpty
              ? 'Not set'
              : profile.preferredTimeRanges.join(', '),
        ),
      ],
    ),
  );
}

class _MatchHistory extends StatelessWidget {
  const _MatchHistory({required this.history});
  final AsyncValue<List<ProfileMatchHistoryItem>> history;
  @override
  Widget build(BuildContext context) => _Section(
    title: 'MATCH HISTORY',
    child: history.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, _) => const Text(
        'Match history is temporarily unavailable. Pull down to retry.',
      ),
      data: (items) => items.isEmpty
          ? const Text(
              'No matches yet. Completed and scheduled Rally matches will appear here.',
            )
          : Column(
              children: items
                  .map(
                    (item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        _statusIcon(item.match.status),
                        color: AppColors.electricGreen,
                      ),
                      title: Text(item.match.clubName),
                      subtitle: Text(
                        '${DateFormat.yMMMd().format(item.match.scheduledStart)} · ${item.otherPlayerName}',
                      ),
                      trailing: Text(
                        item.match.status.name.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      onTap: () => context.push(
                        AppRoutes.matchDetails,
                        extra: item.match,
                      ),
                    ),
                  )
                  .toList(),
            ),
    ),
  );
}

class _FavoriteClubs extends StatelessWidget {
  const _FavoriteClubs({required this.profile, required this.clubs});
  final PlayerProfile profile;
  final AsyncValue<List<Club>> clubs;
  @override
  Widget build(BuildContext context) => _Section(
    title: 'FAVORITE CLUBS',
    child: clubs.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, _) =>
          const Text('Favorite clubs are temporarily unavailable.'),
      data: (values) {
        if (profile.favoriteClubIds.isEmpty) {
          return const Text('No favorite clubs selected.');
        }
        if (values.isEmpty) {
          return const Text(
            'Your saved clubs are no longer active. Edit your profile to choose another club.',
          );
        }
        return Column(
          children: values
              .map(
                (club) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.stadium_outlined,
                    color: AppColors.electricGreen,
                  ),
                  title: Text(club.name),
                  subtitle: Text('${club.city} · ${club.courtCount} courts'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () =>
                      context.push('${AppRoutes.clubDetails}?id=${club.id}'),
                ),
              )
              .toList(),
        );
      },
    ),
  );
}

class _Achievements extends StatelessWidget {
  const _Achievements({required this.profile, required this.statistics});
  final PlayerProfile profile;
  final ProfileStatistics statistics;
  @override
  Widget build(BuildContext context) {
    final achievements = ProfileAchievement.evaluate(profile, statistics);
    return _Section(
      title: 'ACHIEVEMENTS',
      child: Column(
        children: achievements
            .map(
              (achievement) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  achievement.unlocked
                      ? Icons.workspace_premium_rounded
                      : Icons.lock_outline_rounded,
                  color: achievement.unlocked
                      ? AppColors.electricGreen
                      : AppColors.textTertiary,
                ),
                title: Text(achievement.title),
                subtitle: Text(achievement.description),
                trailing: Text(
                  achievement.unlocked ? 'UNLOCKED' : 'LOCKED',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _OwnerActions extends StatelessWidget {
  const _OwnerActions({
    required this.onEdit,
    required this.onFindMatch,
    required this.onViewClub,
    required this.onLogout,
  });
  final VoidCallback onEdit;
  final VoidCallback onFindMatch;
  final VoidCallback? onViewClub;
  final VoidCallback onLogout;
  @override
  Widget build(BuildContext context) => _Section(
    title: 'SETTINGS & ACCOUNT',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('EDIT PROFILE'),
        ),
        const SizedBox(height: AppSpacing.xs),
        OutlinedButton.icon(
          key: const Key('profile-find-match-button'),
          onPressed: onFindMatch,
          icon: const Icon(Icons.sports_tennis_rounded),
          label: const Text('FIND A MATCH'),
        ),
        if (onViewClub != null) ...[
          const SizedBox(height: AppSpacing.xs),
          OutlinedButton.icon(
            key: const Key('view-club-button'),
            onPressed: onViewClub,
            icon: const Icon(Icons.location_on_outlined),
            label: const Text('VIEW HOME CLUB'),
          ),
        ],
        const SizedBox(height: AppSpacing.xs),
        TextButton.icon(
          onPressed: onLogout,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('LOG OUT'),
        ),
      ],
    ),
  );
}

class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet({required this.profile, required this.clubs});
  final PlayerProfile profile;
  final List<Club> clubs;
  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _bio;
  late final TextEditingController _city;
  late String _skill, _hand, _side, _style;
  late Set<String> _days, _times, _favorites;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _name = TextEditingController(text: p.fullName);
    _bio = TextEditingController(text: p.bio);
    _city = TextEditingController(text: p.city);
    _skill = p.skillLevel;
    _hand = p.playingHand;
    _side = p.preferredSide;
    _style = p.playingStyle;
    _days = p.preferredDays.toSet();
    _times = p.preferredTimeRanges.toSet();
    _favorites = p.favoriteClubIds.toSet();
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    _city.dispose();
    super.dispose();
  }

  void _changed(VoidCallback change) => setState(() {
    change();
    _dirty = true;
  });

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(profileUpdateControllerProvider).isLoading;
    return PopScope(
      canPop: !_dirty || saving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || saving) return;
        final discard =
            await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Discard changes?'),
                content: const Text('Your profile edits have not been saved.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('KEEP EDITING'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('DISCARD'),
                  ),
                ],
              ),
            ) ??
            false;
        if (discard && context.mounted) Navigator.pop(context);
      },
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'EDIT PLAYER PROFILE',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Profile photos remain URL-based until Firebase Storage is configured.',
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _name,
                enabled: !saving,
                decoration: const InputDecoration(labelText: 'Display name *'),
                onChanged: (_) => _dirty = true,
                validator: (value) => value == null || value.trim().length < 2
                    ? 'Enter at least two characters.'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _bio,
                enabled: !saving,
                maxLength: 180,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Bio'),
                onChanged: (_) => _dirty = true,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _city,
                enabled: !saving,
                decoration: const InputDecoration(labelText: 'City *'),
                onChanged: (_) => _dirty = true,
                validator: (value) => value == null || value.trim().length < 2
                    ? 'Enter your city.'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              _Dropdown(
                'Skill level',
                _skill,
                const ['Beginner', 'Intermediate', 'Advanced'],
                saving,
                (v) => _changed(() => _skill = v),
              ),
              _Dropdown(
                'Playing hand',
                _hand,
                const ['Right', 'Left'],
                saving,
                (v) => _changed(() => _hand = v),
              ),
              _Dropdown(
                'Preferred side',
                _side,
                const ['No preference', 'Left', 'Right'],
                saving,
                (v) => _changed(() => _side = v),
              ),
              _Dropdown(
                'Playing style',
                _style,
                const ['Balanced', 'Attacking', 'Defensive'],
                saving,
                (v) => _changed(() => _style = v),
              ),
              const SizedBox(height: AppSpacing.sm),
              _ChoiceGroup(
                title: 'Preferred days',
                values: const [
                  'Monday',
                  'Tuesday',
                  'Wednesday',
                  'Thursday',
                  'Friday',
                  'Saturday',
                  'Sunday',
                ],
                selected: _days,
                enabled: !saving,
                onToggle: (value) => _changed(
                  () => _days.contains(value)
                      ? _days.remove(value)
                      : _days.add(value),
                ),
              ),
              _ChoiceGroup(
                title: 'Preferred times',
                values: const ['Morning', 'Afternoon', 'Evening', 'Late night'],
                selected: _times,
                enabled: !saving,
                onToggle: (value) => _changed(
                  () => _times.contains(value)
                      ? _times.remove(value)
                      : _times.add(value),
                ),
              ),
              _ChoiceGroup(
                title: 'Favorite clubs',
                values: widget.clubs.map((c) => c.id).toList(),
                labels: {for (final c in widget.clubs) c.id: c.name},
                selected: _favorites,
                enabled: !saving,
                onToggle: (value) => _changed(
                  () => _favorites.contains(value)
                      ? _favorites.remove(value)
                      : _favorites.add(value),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                key: const Key('save-profile-button'),
                onPressed: saving ? null : _save,
                icon: saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(saving ? 'SAVING' : 'SAVE PROFILE'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final homeClub = _favorites.firstOrNull ?? widget.profile.homeClubId;
    _dirty = false;
    Navigator.pop(
      context,
      widget.profile.copyWith(
        fullName: _name.text.trim(),
        bio: _bio.text.trim(),
        city: _city.text.trim(),
        skillLevel: _skill,
        playingHand: _hand,
        preferredSide: _side,
        playingStyle: _style,
        preferredDays: _days.toList(),
        preferredTimeRanges: _times.toList(),
        favoriteClubIds: _favorites.toList(),
        preferredClubIds: _favorites.toList(),
        homeClubId: homeClub,
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown(
    this.label,
    this.value,
    this.values,
    this.disabled,
    this.onChanged,
  );
  final String label, value;
  final List<String> values;
  final bool disabled;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: DropdownButtonFormField<String>(
      initialValue: values.contains(value) ? value : values.first,
      decoration: InputDecoration(labelText: label),
      items: values
          .map((v) => DropdownMenuItem(value: v, child: Text(v)))
          .toList(),
      onChanged: disabled
          ? null
          : (v) {
              if (v != null) onChanged(v);
            },
    ),
  );
}

class _ChoiceGroup extends StatelessWidget {
  const _ChoiceGroup({
    required this.title,
    required this.values,
    required this.selected,
    required this.enabled,
    required this.onToggle,
    this.labels = const {},
  });
  final String title;
  final List<String> values;
  final Set<String> selected;
  final bool enabled;
  final ValueChanged<String> onToggle;
  final Map<String, String> labels;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: values
              .map(
                (v) => FilterChip(
                  label: Text(labels[v] ?? v),
                  selected: selected.contains(v),
                  onSelected: enabled ? (_) => onToggle(v) : null,
                ),
              )
              .toList(),
        ),
      ],
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surfaceSecondary,
    shape: RoundedRectangleBorder(
      borderRadius: AppRadius.large,
      side: const BorderSide(color: AppColors.borderSubtle),
    ),
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric(this.value, this.label);
  final String value, label;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label, $value',
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadius.medium,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    ),
  );
}

class _Attribute extends StatelessWidget {
  const _Attribute(this.icon, this.label, this.value);
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: AppColors.surfaceElevated,
      borderRadius: AppRadius.pillRadius,
      border: Border.all(color: AppColors.borderSubtle),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.electricGreen),
        const SizedBox(width: AppSpacing.xxs),
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    ),
  );
}

class _RetrySection extends StatelessWidget {
  const _RetrySection({required this.title, required this.onRetry});
  final String title;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => _Section(
    title: title,
    child: Row(
      children: [
        const Expanded(
          child: Text('This information is temporarily unavailable.'),
        ),
        TextButton(onPressed: onRetry, child: const Text('RETRY')),
      ],
    ),
  );
}

class _Status extends StatelessWidget {
  const _Status({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) => Padding(
    padding: AppSpacing.screenPadding,
    child: Center(child: child),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(
        Icons.cloud_off_rounded,
        size: 48,
        color: AppColors.electricGreen,
      ),
      const SizedBox(height: AppSpacing.md),
      Text(message, textAlign: TextAlign.center),
      const SizedBox(height: AppSpacing.md),
      FilledButton.icon(
        key: const Key('profile-retry-button'),
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: const Text('RETRY'),
      ),
    ],
  );
}

class _MissingProfile extends StatelessWidget {
  const _MissingProfile();
  @override
  Widget build(BuildContext context) => const Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.person_off_outlined, size: 48, color: AppColors.electricGreen),
      SizedBox(height: AppSpacing.md),
      Text('Your player profile is missing.'),
    ],
  );
}

IconData _statusIcon(RallyMatchStatus status) => switch (status) {
  RallyMatchStatus.completed => Icons.check_circle_outline,
  RallyMatchStatus.cancelled ||
  RallyMatchStatus.declined ||
  RallyMatchStatus.expired => Icons.event_busy_outlined,
  _ => Icons.schedule_outlined,
};

String _profileError(Object? error) => error is ProfileFailure
    ? error.message
    : 'Your profile could not be updated. Please try again.';
