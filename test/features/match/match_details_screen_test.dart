import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rally/features/match/presentation/screens/match_details_screen.dart';
import 'package:rally/theme/app_theme.dart';

import '../../helpers/matchmaking_test_scope.dart';

void main() {
  Widget buildFlow({TextScaler textScaler = TextScaler.noScaling}) {
    final router = GoRouter(
      initialLocation: '/source',
      routes: <RouteBase>[
        GoRoute(
          path: '/source',
          builder: (context, state) => Scaffold(
            body: FilledButton(
              onPressed: () => context.push('/match-details'),
              child: const Text('Open match'),
            ),
          ),
        ),
        GoRoute(
          path: '/match-details',
          builder: (_, _) => const MatchDetailsScreen(),
        ),
        GoRoute(
          path: '/match-chat',
          builder: (_, _) => const Scaffold(body: Text('Chat')),
        ),
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: '/player-profile',
          builder: (_, _) => const Scaffold(body: Text('Profile')),
        ),
        GoRoute(
          path: '/club-details',
          builder: (_, _) => const Scaffold(body: Text('Club')),
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
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        ),
      ),
    );
  }

  testWidgets('scrolls all actions above the safe area on a compact phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildFlow(textScaler: const TextScaler.linear(1.3)),
    );
    await tester.tap(find.text('Open match'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('BACK TO HOME'),
      400,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('OPEN MATCH CHAT'), findsOneWidget);
    expect(find.text('BACK TO HOME'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('back navigation returns to the previous route', (tester) async {
    await tester.pumpWidget(buildFlow());
    await tester.tap(find.text('Open match'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Open match'), findsOneWidget);
  });

  testWidgets('calendar and directions actions provide complete feedback', (
    tester,
  ) async {
    await tester.pumpWidget(buildFlow());
    await tester.tap(find.text('Open match'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('match-directions-button')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('match-directions-button')));
    await tester.pumpAndSettle();
    expect(find.text('PADELVERSE CLIFTON'), findsOneWidget);
    await tester.tap(find.text('DONE'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('match-calendar-button')));
    await tester.pump();
    expect(
      find.text('Match added to your calendar for today at 7:30 PM.'),
      findsOneWidget,
    );
  });
}
