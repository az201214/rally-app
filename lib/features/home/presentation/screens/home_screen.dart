import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/app_routes.dart';
import '../../../../../theme/app_spacing.dart';
import '../widgets/availability_selector.dart';
import '../widgets/live_activity_strip.dart';
import '../widgets/match_hero_panel.dart';
import '../widgets/match_search_sheet.dart';
import '../widgets/rally_bottom_navigation.dart';
import '../widgets/rally_home_header.dart';
import '../widgets/recommended_players_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AvailabilityOption _availability = AvailabilityOption.now;
  HomeDestination _destination = HomeDestination.home;

  Future<void> _openMatchSearchSheet() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => MatchSearchSheet(availability: _availability),
    );
  }

  void _startMatchSearch() => context.push(AppRoutes.searching);

  void _selectDestination(HomeDestination destination) {
    if (destination == HomeDestination.play) {
      _openMatchSearchSheet();
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
                        MatchHeroPanel(onFindMatch: _startMatchSearch),
                        const SizedBox(height: AppSpacing.lg),
                        AvailabilitySelector(
                          selected: _availability,
                          onSelected: (availability) {
                            setState(() {
                              _availability = availability;
                            });
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const LiveActivityStrip(),
                        const SizedBox(height: AppSpacing.xl),
                        const RecommendedPlayersSection(),
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
