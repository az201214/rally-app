import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rally/features/match/presentation/screens/match_found_screen.dart';
import 'package:rally/theme/app_theme.dart';

import '../../helpers/matchmaking_test_scope.dart';

void main() {
  Widget buildScreen({
    bool disableAnimations = true,
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    final router = GoRouter(
      initialLocation: '/match-found',
      routes: <RouteBase>[
        GoRoute(
          path: '/match-found',
          builder: (_, _) => const MatchFoundScreen(allowPreviewData: true),
        ),
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: '/searching',
          builder: (_, _) => const Scaffold(body: Text('Searching')),
        ),
        GoRoute(
          path: '/match-details',
          builder: (_, _) => const Scaffold(body: Text('Details')),
        ),
      ],
    );
    addTearDown(router.dispose);

    return matchmakingTestScope(
      child: MaterialApp.router(
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: disableAnimations,
            textScaler: textScaler,
          ),
          child: child!,
        ),
      ),
    );
  }

  testWidgets('shows the complete premium match information', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pump();

    expect(find.text('YOUR RALLY\nIS READY'), findsOneWidget);
    expect(find.text('HAMZA KHAN'), findsOneWidget);
    expect(find.text('Advanced · Right-side player'), findsOneWidget);
    expect(find.text('4.9'), findsOneWidget);
    expect(find.text('92%'), findsOneWidget);
    expect(find.text('2.4 KM'), findsOneWidget);
    expect(find.text('Padelverse Clifton'), findsOneWidget);
    expect(find.text('96% MATCH'), findsOneWidget);
    expect(find.text('WHY THIS MATCH WORKS'), findsOneWidget);
    expect(find.byKey(const Key('accept-match-button')), findsOneWidget);
  });

  testWidgets('accepting the match opens details', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('accept-match-button')));
    await tester.tap(find.byKey(const Key('accept-match-button')));
    await tester.pumpAndSettle();

    expect(find.text('Details'), findsOneWidget);
  });

  testWidgets('supports a compact display with larger text', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildScreen(textScaler: const TextScaler.linear(1.25)),
    );
    await tester.pump();
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -700),
    );
    await tester.pump();

    expect(find.byKey(const Key('accept-match-button')), findsOneWidget);
  });
}
