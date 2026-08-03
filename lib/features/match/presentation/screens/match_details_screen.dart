import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../demo/demo_mode.dart';
import '../../../../routes/app_routes.dart';
import '../../../../shared/widgets/rally_snackbar.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_spacing.dart';
import '../../../matchmaking/application/matchmaking_controller.dart';
import '../../../matchmaking/domain/matchmaking_models.dart';

class MatchDetailsScreen extends ConsumerWidget {
  const MatchDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final match = ref.watch(matchmakingControllerProvider).match;
    final chatEnabled =
        DemoMode.enabled ||
        match == null ||
        match.status == RallyMatchStatus.confirmed;
    return Scaffold(
      backgroundColor: AppColors.carbonBlack,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: CustomScrollView(
              slivers: <Widget>[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xxxl,
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
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'MATCH DETAILS',
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _ConfirmedHero(match: match),
                      const SizedBox(height: AppSpacing.lg),
                      const _VenueCard(),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton.icon(
                              key: const Key('match-directions-button'),
                              onPressed: () => _showVenuePreview(context),
                              icon: const Icon(Icons.directions_rounded),
                              label: const Text('DIRECTIONS'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: OutlinedButton.icon(
                              key: const Key('match-calendar-button'),
                              onPressed: () => RallySnackbar.show(
                                context,
                                message:
                                    'Match added to your calendar for today at 7:30 PM.',
                              ),
                              icon: const Icon(Icons.event_available_rounded),
                              label: const Text('CALENDAR'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const _PlayersCard(),
                      const SizedBox(height: AppSpacing.md),
                      const _MatchPlanCard(),
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        height: 56,
                        child: FilledButton.icon(
                          onPressed: chatEnabled
                              ? () => context.push(AppRoutes.matchChat)
                              : () => RallySnackbar.show(
                                  context,
                                  message:
                                      'Match chat opens after every player accepts.',
                                  icon: Icons.schedule_rounded,
                                ),
                          icon: const Icon(Icons.chat_bubble_rounded),
                          label: const Text('OPEN MATCH CHAT'),
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

  Future<void> _showVenuePreview(
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
          const Icon(
            Icons.map_rounded,
            size: 48,
            color: AppColors.electricGreen,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'PADELVERSE CLIFTON',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Khayaban-e-Saadi, Clifton, Karachi\n12 minute drive · 2.4 km away',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('DONE'),
          ),
        ],
      ),
    ),
  );
}

class _ConfirmedHero extends StatelessWidget {
  const _ConfirmedHero({this.match});

  final RallyMatch? match;

  @override
  Widget build(BuildContext context) {
    final confirmed =
        match == null || match!.status == RallyMatchStatus.confirmed;
    final status = match?.status.name ?? 'confirmed';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: AppRadius.xLarge,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF102519), Color(0xFF0C1220)],
        ),
        border: Border.all(
          color: AppColors.electricGreen.withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.electricGreen.withValues(alpha: 0.14),
            ),
            child: Icon(
              confirmed ? Icons.check_rounded : Icons.schedule_rounded,
              color: AppColors.electricGreen,
              size: 30,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            confirmed ? 'YOU’RE IN' : 'AWAITING PLAYERS',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            match == null
                ? 'Today · 7:30 PM · Competitive'
                : '${match!.scheduledStart.toLocal().hour.toString().padLeft(2, '0')}:${match!.scheduledStart.toLocal().minute.toString().padLeft(2, '0')} · ${match!.city}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.electricGreen,
              borderRadius: AppRadius.pillRadius,
            ),
            child: Text(
              status
                  .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[1]}')
                  .trim()
                  .toUpperCase(),
              style: const TextStyle(
                color: AppColors.textInverse,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 0.9,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VenueCard extends StatelessWidget {
  const _VenueCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'VENUE',
      child: Row(
        children: <Widget>[
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: AppRadius.large,
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFF293A34), Color(0xFF101722)],
              ),
            ),
            child: const Icon(
              Icons.stadium_rounded,
              color: AppColors.electricGreen,
              size: 34,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Padelverse Clifton',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Court 03 · 2.4 km away',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                const Row(
                  children: <Widget>[
                    Icon(
                      Icons.navigation_rounded,
                      size: 16,
                      color: AppColors.electricGreen,
                    ),
                    SizedBox(width: AppSpacing.xxs),
                    Flexible(
                      child: Text(
                        '12 min drive',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.push(AppRoutes.clubDetails),
            tooltip: 'View Padelverse Clifton',
            icon: const Icon(Icons.arrow_outward_rounded),
          ),
        ],
      ),
    );
  }
}

class _PlayersCard extends StatelessWidget {
  const _PlayersCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'PLAYERS',
      child: Column(
        children: <Widget>[
          const _PlayerRow(
            name: 'You',
            detail: 'Advanced · Left side',
            isYou: true,
          ),
          const Divider(height: AppSpacing.lg),
          _PlayerRow(
            name: 'Hamza Khan',
            detail: 'Advanced · Right side',
            onTap: () => context.push(AppRoutes.playerProfile),
          ),
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.name,
    required this.detail,
    this.isYou = false,
    this.onTap,
  });

  final String name;
  final String detail;
  final bool isYou;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.medium,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        child: Row(
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isYou
                    ? AppColors.electricGreen.withValues(alpha: 0.16)
                    : Colors.white.withValues(alpha: 0.07),
              ),
              child: Icon(
                Icons.person_rounded,
                color: isYou
                    ? AppColors.electricGreen
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      if (!isYou) ...<Widget>[
                        const SizedBox(width: AppSpacing.xxs),
                        const Icon(
                          Icons.verified_rounded,
                          size: 17,
                          color: AppColors.electricGreen,
                        ),
                      ],
                    ],
                  ),
                  Text(detail, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
              ),
          ],
        ),
      ),
    );
  }
}

class _MatchPlanCard extends StatelessWidget {
  const _MatchPlanCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'MATCH PLAN',
      child: Column(
        children: const <Widget>[
          _DetailLine(
            icon: Icons.timer_outlined,
            label: 'Duration',
            value: '90 minutes',
          ),
          SizedBox(height: AppSpacing.md),
          _DetailLine(
            icon: Icons.payments_outlined,
            label: 'Court split',
            value: 'PKR 2,000 each',
          ),
          SizedBox(height: AppSpacing.md),
          _DetailLine(
            icon: Icons.shield_outlined,
            label: 'Reliability',
            value: 'Both players verified',
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, color: AppColors.electricGreen, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

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
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}
