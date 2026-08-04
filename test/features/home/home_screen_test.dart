import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rally/features/home/presentation/screens/home_screen.dart';
import 'package:rally/features/searching/presentation/screens/searching_screen.dart';
import 'package:rally/theme/app_theme.dart';

void main() {
  Widget buildHome({TextScaler textScaler = TextScaler.noScaling}) {
    return MaterialApp(
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
      MaterialApp.router(
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
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
    expect(find.text('RECOMMENDED PLAYERS'), findsOneWidget);
  });
}
