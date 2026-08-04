import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/app_routes.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/rally_components.dart';
import '../../../../theme/app_spacing.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _pages = [
    (
      Icons.radar_rounded,
      'FIND YOUR RALLY',
      'Discover compatible players nearby, right when you want to play.',
    ),
    (
      Icons.verified_user_outlined,
      'TRUST THE MATCH',
      'Skill balance, reliability, and verification built into every pairing.',
    ),
    (
      Icons.sports_tennis_rounded,
      'GET ON COURT',
      'Confirm the venue, meet your team, and start playing in minutes.',
    ),
  ];

  void _next() {
    if (_index == _pages.length - 1) {
      context.go(AppRoutes.login);
    } else if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpToPage(_index + 1);
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: () => context.go(AppRoutes.login),
            child: const Text('Skip'),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: RallyContent(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (value) => setState(() => _index = value),
                itemCount: _pages.length,
                itemBuilder: (_, index) {
                  final page = _pages[index];
                  return Semantics(
                    label: 'Onboarding page ${index + 1} of ${_pages.length}',
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          page.$1,
                          size: 96,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          page.$2,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          page.$3,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.all(AppSpacing.xxs),
                  width: index == _index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: index == _index
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              key: const Key('onboarding-continue'),
              label: _index == _pages.length - 1 ? 'START RALLY' : 'CONTINUE',
              onPressed: _next,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
