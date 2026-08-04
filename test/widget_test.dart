import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rally/features/authentication/presentation/screens/login_screen.dart';
import 'package:rally/features/home/presentation/screens/home_screen.dart';
import 'package:rally/features/journey/presentation/screens/journey_screens.dart';
import 'package:rally/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:rally/features/searching/presentation/screens/searching_screen.dart';
import 'package:rally/features/splash/presentation/screens/splash_screen.dart';
import 'package:rally/routes/app_routes.dart';
import 'package:rally/theme/app_theme.dart';

void main() {
  testWidgets('complete primary demo journey reaches chat', (tester) async {
    final router = GoRouter(
      initialLocation: AppRoutes.splash,
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          builder: (_, _) => const SplashScreen(),
        ),
        GoRoute(
          path: AppRoutes.onboarding,
          builder: (_, _) => const OnboardingScreen(),
        ),
        GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
        GoRoute(path: AppRoutes.home, builder: (_, _) => const HomeScreen()),
        GoRoute(
          path: AppRoutes.searching,
          builder: (_, _) => const SearchingScreen(),
        ),
        GoRoute(
          path: AppRoutes.matchFound,
          builder: (_, _) => const MatchFoundScreen(),
        ),
        GoRoute(
          path: AppRoutes.matchDetails,
          builder: (_, _) => const MatchDetailsScreen(),
        ),
        GoRoute(
          path: AppRoutes.chat,
          builder: (_, _) => const MatchChatScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.darkTheme,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('FIND YOUR RALLY'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const Key('onboarding-continue')));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const Key('login-button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('login-button')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('find-match-button')), findsOneWidget);

    router.go(AppRoutes.matchFound);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('YOUR COURT IS READY'), findsOneWidget);

    await tester.tap(find.byKey(const Key('accept-match-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('THURSDAY NIGHT PADEL'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('open-chat-button')));
    await tester.tap(find.byKey(const Key('open-chat-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('chat-input')), findsOneWidget);
  });
}
