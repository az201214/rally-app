import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../demo/demo_mode.dart';
import '../../../../demo/rally_demo_service.dart';
import '../../../../routes/app_routes.dart';
import '../../../../shared/widgets/rally_snackbar.dart';
import '../../../matchmaking/application/matchmaking_controller.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../widgets/animated_padel_ball.dart';
import '../widgets/cancel_button.dart';
import '../widgets/court_background.dart';
import '../widgets/discovery_cards.dart';
import '../widgets/floating_particles.dart';
import '../widgets/search_status.dart';

class SearchingScreen extends ConsumerStatefulWidget {
  const SearchingScreen({this.matchDelay, super.key});

  final Duration? matchDelay;

  @override
  ConsumerState<SearchingScreen> createState() => _SearchingScreenState();
}

class _SearchingScreenState extends ConsumerState<SearchingScreen> {
  Timer? _matchTimer;
  bool _navigationScheduled = false;

  @override
  void initState() {
    super.initState();
    if (widget.matchDelay != null) {
      _matchTimer = Timer(widget.matchDelay!, () {
        if (mounted) context.go(AppRoutes.matchFound);
      });
    } else if (DemoMode.enabled) {
      _matchTimer = Timer(RallyDemoService.instance.matchmakingDelay, () {
        if (mounted && ref.read(matchmakingControllerProvider).match != null) {
          context.go(AppRoutes.matchFound);
        }
      });
    }
  }

  @override
  void dispose() {
    _matchTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(matchmakingControllerProvider);
    if (current.phase == MatchmakingPhase.matchFound && !_navigationScheduled) {
      _navigationScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.matchFound);
      });
    }
    ref.listen(matchmakingControllerProvider, (previous, next) {
      if (next.phase == MatchmakingPhase.matchFound &&
          previous?.phase != MatchmakingPhase.matchFound) {
        _navigationScheduled = true;
        context.go(AppRoutes.matchFound);
      } else if (next.phase == MatchmakingPhase.error &&
          next.message != null &&
          previous?.message != next.message) {
        RallySnackbar.show(
          context,
          message: next.message!,
          icon: Icons.error_outline_rounded,
        );
      }
    });
    return Scaffold(
      backgroundColor: AppColors.carbonBlack,
      body: Stack(
        children: <Widget>[
          const Positioned.fill(
            child: RepaintBoundary(child: CourtBackground()),
          ),
          const Positioned.fill(
            child: RepaintBoundary(child: FloatingParticles()),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - AppSpacing.xl,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppSpacing.xxxl * 7,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            _SearchHeader(),
                            const SizedBox(height: AppSpacing.md),
                            const _SearchHero(),
                            const SizedBox(height: AppSpacing.lg),
                            const DiscoveryCards(),
                            const SizedBox(height: AppSpacing.lg),
                            CancelButton(
                              onPressed: () async {
                                _matchTimer?.cancel();
                                final cancelled = await ref
                                    .read(
                                      matchmakingControllerProvider.notifier,
                                    )
                                    .cancelSearch();
                                if (context.mounted && cancelled) {
                                  context.go(AppRoutes.home);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: <Widget>[
        Text(
          'MATCHMAKING / LIVE',
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppColors.electricGreen,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'SEARCHING FOR MATCH',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

class _SearchHero extends StatelessWidget {
  const _SearchHero();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final heroSize = (width * 0.62).clamp(
      AppSpacing.xxxl * 3,
      AppSpacing.xxxl * 4.35,
    );
    return Column(
      children: <Widget>[
        SizedBox.square(
          dimension: heroSize,
          child: const Hero(
            tag: 'match-search-ball',
            child: AnimatedPadelBall(),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const SearchStatus(),
      ],
    );
  }
}
