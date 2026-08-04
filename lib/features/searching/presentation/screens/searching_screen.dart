import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/app_routes.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../widgets/animated_padel_ball.dart';
import '../widgets/cancel_button.dart';
import '../widgets/court_background.dart';
import '../widgets/discovery_cards.dart';
import '../widgets/floating_particles.dart';
import '../widgets/search_status.dart';

class SearchingScreen extends StatelessWidget {
  const SearchingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.carbonBlack,
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: CourtBackground()),
          const Positioned.fill(child: FloatingParticles()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
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
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: AppSpacing.xs,
                              runSpacing: AppSpacing.xs,
                              children: const [
                                Chip(label: Text('Now')),
                                Chip(label: Text('5 km')),
                                Chip(label: Text('Level 3–4')),
                                Chip(label: Text('Any club')),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            PrimaryButton(
                              key: const Key('reveal-match-button'),
                              label: 'VIEW BEST MATCH',
                              icon: Icons.bolt_rounded,
                              onPressed: () => context.go(AppRoutes.matchFound),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            CancelButton(
                              onPressed: () => Navigator.of(context).maybePop(),
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
