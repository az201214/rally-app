import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rally/features/home/presentation/screens/home_screen.dart';
import 'package:rally/features/searching/presentation/screens/searching_screen.dart';
import 'package:rally/theme/app_theme.dart';

import '../../helpers/matchmaking_test_scope.dart';

void main() {
  Widget buildHome({TextScaler textScaler = TextScaler.noScaling}) {
    return matchmakingTestScope(
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: true, textScaler: textScaler),
          child: child!,
        ),
        home: const HomeScreen(),
      ),
    );
  }

  Widget buildRoutedHome() {
    final router = GoRouter(
      initialLocation: '/home',
      routes: <RouteBase>[
        GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
        GoRoute(
          path: '/searching',
          builder: (_, _) => const Scaffold(body: Text('Searching route')),
        ),
        GoRoute(
          path: '/club-details',
          builder: (_, _) => const Scaffold(body: Text('Club route')),
        ),
        GoRoute(
          path: '/player-profile',
          builder: (_, _) => const Scaffold(body: Text('Profile route')),
        ),
        GoRoute(
          path: '/match-details',
          builder: (_, _) => const Scaffold(body: Text('Matches route')),
        ),
      ],
    );
    addTearDown(router.dispose);
    return matchmakingTestScope(
      child: MaterialApp.router(
        theme: AppTheme.darkTheme,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
      ),
    );
  }

  Material availabilityMaterial(WidgetTester tester, String option) {
    return tester.widget<Material>(
      find
          .ancestor(
            of: find.byKey(Key('availability-$option')),
            matching: find.byType(Material),
          )
          .first,
    );
  }

  testWidgets('renders the primary Home promise and action', (tester) async {
    await tester.pumpWidget(buildHome());
    await tester.pump();

    expect(find.text('READY TO PLAY?'), findsOneWidget);
    expect(find.text('FIND A MATCH'), findsOneWidget);
    expect(find.text('RALLY RECOMMENDATION'), findsOneWidget);
    expect(find.text('NEARBY CLUBS'), findsOneWidget);
    expect(find.text('TRENDING PLAYERS'), findsOneWidget);
    expect(find.text('RATING'), findsOneWidget);
    expect(find.text('RELIABILITY'), findsOneWidget);
    expect(find.text('ONLINE'), findsOneWidget);
    expect(find.text('MATCHES'), findsOneWidget);
  });

  testWidgets('availability defaults to NOW', (tester) async {
    await tester.pumpWidget(buildHome());
    await tester.pump();

    final theme = AppTheme.darkTheme;
    expect(
      availabilityMaterial(tester, 'now').color,
      theme.colorScheme.primary,
    );
    expect(
      availabilityMaterial(tester, 'tonight').color,
      theme.colorScheme.surfaceContainerHighest,
    );
  });

  testWidgets('selecting TONIGHT updates availability', (tester) async {
    await tester.pumpWidget(buildHome());
    await tester.tap(find.byKey(const Key('availability-tonight')));
    await tester.pump();

    final theme = AppTheme.darkTheme;
    expect(
      availabilityMaterial(tester, 'tonight').color,
      theme.colorScheme.primary,
    );
    expect(
      availabilityMaterial(tester, 'now').color,
      theme.colorScheme.surfaceContainerHighest,
    );
  });

  testWidgets('FIND A MATCH opens searching and Cancel returns Home', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: <RouteBase>[
        GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
        GoRoute(path: '/searching', builder: (_, _) => const SearchingScreen()),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      matchmakingTestScope(
        child: MaterialApp.router(
          theme: AppTheme.darkTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('find-match-button')));
    await tester.pumpAndSettle();

    expect(find.text('SEARCHING FOR MATCH'), findsOneWidget);
    expect(find.text('Finding nearby players...'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('cancel-search-button')));
    await tester.tap(find.byKey(const Key('cancel-search-button')));
    await tester.pumpAndSettle();

    expect(find.text('SEARCHING FOR MATCH'), findsNothing);
    expect(find.text('READY TO PLAY?'), findsOneWidget);
  });

  testWidgets('central Play confirmation starts the real search route', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: <RouteBase>[
        GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
        GoRoute(path: '/searching', builder: (_, _) => const SearchingScreen()),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      matchmakingTestScope(
        child: MaterialApp.router(
          theme: AppTheme.darkTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('central-play-button')));
    await tester.pumpAndSettle();
    expect(find.text('READY TO SEARCH?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('start-searching-button')));
    await tester.pumpAndSettle();
    expect(find.text('SEARCHING FOR MATCH'), findsOneWidget);
  });

  testWidgets('renders without overflow at 360x800 and 1.3 text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildHome(textScaler: const TextScaler.linear(1.3)),
    );
    await tester.pump();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pump();

    final exception = tester.takeException();
    expect(
      exception,
      isNull,
      reason: exception is FlutterError ? exception.toStringDeep() : null,
    );
    expect(find.text('TRENDING PLAYERS'), findsOneWidget);
  });

  testWidgets('quick actions stay in the scroll flow with no floating rail', (
    tester,
  ) async {
    await tester.pumpWidget(buildHome());
    await tester.scrollUntilVisible(
      find.byKey(const Key('quick-play')),
      500,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.byKey(const Key('quick-play')), findsOneWidget);
    expect(find.byKey(const Key('quick-clubs')), findsOneWidget);
    expect(find.byKey(const Key('quick-profile')), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home supports 1.5 text scale on a 320px phone', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildHome(textScaler: const TextScaler.linear(1.5)),
    );
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -2400));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('notifications provide a complete local inbox', (tester) async {
    await tester.pumpWidget(buildRoutedHome());
    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();
    expect(find.text('NOTIFICATIONS'), findsOneWidget);
    expect(find.text('Match confirmed'), findsOneWidget);
    await tester.tap(find.text('DONE'));
    await tester.pumpAndSettle();
  });

  testWidgets('club, player and secondary Home actions navigate', (
    tester,
  ) async {
    await tester.pumpWidget(buildRoutedHome());
    await tester.ensureVisible(find.text('PADELVERSE'));
    await tester.pump();
    await tester.tap(find.text('PADELVERSE'));
    await tester.pumpAndSettle();
    expect(find.text('Club route'), findsOneWidget);

    await tester.pumpWidget(buildRoutedHome());
    await tester.ensureVisible(find.text('Ahmed R.'));
    await tester.pump();
    await tester.tap(find.text('Ahmed R.'));
    await tester.pumpAndSettle();
    expect(find.text('Profile route'), findsOneWidget);

    await tester.pumpWidget(buildRoutedHome());
    await tester.ensureVisible(find.byKey(const Key('quick-play')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('quick-play')));
    await tester.pumpAndSettle();
    expect(find.text('READY TO SEARCH?'), findsOneWidget);
  });
}
