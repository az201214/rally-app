import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/app_routes.dart';
import '../../../../shared/widgets/rally_snackbar.dart';
import '../../../matchmaking/application/matchmaking_controller.dart';
import '../../../../../theme/app_spacing.dart';
import '../widgets/availability_selector.dart';
import '../widgets/dashboard_hero.dart';
import '../widgets/dashboard_sections.dart';
import '../widgets/live_activity_strip.dart';
import '../widgets/match_search_sheet.dart';
import '../widgets/rally_bottom_navigation.dart';
import '../widgets/rally_home_header.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  AvailabilityOption _availability = AvailabilityOption.now;
  HomeDestination _destination = HomeDestination.home;

  Future<void> _openMatchSearchSheet() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => MatchSearchSheet(
        availability: _availability,
        onStart: () {
          Navigator.of(sheetContext).pop();
          _startMatchSearch();
        },
      ),
    );
  }

  Future<void> _startMatchSearch() async {
    final now = DateTime.now();
    final tonight = DateTime(now.year, now.month, now.day, 19);
    final start = _availability == AvailabilityOption.tonight
        ? (tonight.isAfter(now) ? tonight : now)
        : now;
    final end = _availability == AvailabilityOption.custom
        ? now.add(const Duration(hours: 3))
        : start.add(const Duration(hours: 2));
    final started = await ref
        .read(matchmakingControllerProvider.notifier)
        .startSearch(availableFrom: start, availableUntil: end);
    if (!mounted) return;
    if (started) {
      context.push(AppRoutes.searching);
    } else {
      final message =
          ref.read(matchmakingControllerProvider).message ??
          'Matchmaking could not be started.';
      RallySnackbar.show(
        context,
        message: message,
        icon: Icons.error_outline_rounded,
      );
    }
  }

  void _selectDestination(HomeDestination destination) {
    if (destination == HomeDestination.play) {
      _openMatchSearchSheet();
      return;
    }
    if (destination == HomeDestination.profile) {
      context.push(AppRoutes.playerProfile);
      return;
    }
    if (destination == HomeDestination.discover) {
      context.push(AppRoutes.clubs);
      return;
    }
    if (destination == HomeDestination.matches) {
      context.push(AppRoutes.matchDetails);
      return;
    }

    setState(() {
      _destination = destination;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSpacing.xxxl * 12),
            child: CustomScrollView(
              slivers: <Widget>[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const RallyHomeHeader(),
                        const SizedBox(height: AppSpacing.md),
                        DashboardHero(
                          availability: _availability,
                          onAvailabilityChanged: (availability) =>
                              setState(() => _availability = availability),
                          onFindMatch: _startMatchSearch,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        const LiveActivityStrip(),
                        const SizedBox(height: AppSpacing.xl),
                        AiRecommendationCard(onFindMatch: _startMatchSearch),
                        const SizedBox(height: AppSpacing.xl),
                        NearbyClubsCarousel(
                          onClubSelected: () =>
                              context.push(AppRoutes.clubDetails),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        TrendingPlayersCarousel(
                          onPlayerSelected: () =>
                              context.push(AppRoutes.playerProfile),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        const DashboardStatistics(),
                        const SizedBox(height: AppSpacing.xl),
                        QuickActionsSection(
                          onPlay: _openMatchSearchSheet,
                          onClubs: () => context.push(AppRoutes.clubs),
                          onProfile: () =>
                              context.push(AppRoutes.playerProfile),
                        ),
                        const SizedBox(height: AppSpacing.xxxl * 2),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: RallyBottomNavigation(
        selected: _destination,
        onSelected: _selectDestination,
      ),
    );
  }
}
