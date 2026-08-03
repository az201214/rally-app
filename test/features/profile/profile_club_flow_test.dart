import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rally/features/clubs/presentation/screens/club_details_screen.dart';
import 'package:rally/features/profile/presentation/screens/player_profile_screen.dart';
import 'package:rally/features/authentication/application/auth_providers.dart';
import 'package:rally/features/authentication/domain/auth_user.dart';
import 'package:rally/theme/app_theme.dart';

import '../../helpers/fake_repositories.dart';

void main() {
  Widget buildFlow({FakePlayerProfileRepository? profileRepository}) {
    final auth = FakeAuthRepository(
      user: const AuthUser(uid: 'user-1', email: 'hamza@rally.pk'),
    );
    final profiles =
        profileRepository ??
        FakePlayerProfileRepository(profile: testProfile());
    addTearDown(auth.dispose);
    final router = GoRouter(
      initialLocation: '/player-profile',
      routes: <RouteBase>[
        GoRoute(
          path: '/player-profile',
          builder: (_, _) => const PlayerProfileScreen(),
        ),
        GoRoute(
          path: '/club-details',
          builder: (_, _) => const ClubDetailsScreen(),
        ),
        GoRoute(
          path: '/searching',
          builder: (_, _) => const Scaffold(body: Text('Searching')),
        ),
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: Text('Home')),
        ),
      ],
    );
    addTearDown(router.dispose);

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        playerProfileRepositoryProvider.overrideWithValue(profiles),
      ],
      child: MaterialApp.router(
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        routerConfig: router,
      ),
    );
  }

  testWidgets('profile presents player data and opens the home club', (
    tester,
  ) async {
    await tester.pumpWidget(buildFlow());
    await tester.pumpAndSettle();

    expect(find.text('HAMZA KHAN'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('92% reliable'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('92% reliable'), findsOneWidget);
    expect(find.text('Padelverse Clifton'), findsNothing);

    await tester.scrollUntilVisible(
      find.byKey(const Key('view-club-button')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('view-club-button')));
    await tester.pumpAndSettle();

    expect(find.text('PADELVERSE'), findsOneWidget);
    expect(find.text('18 players ready tonight'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('club-find-match-button')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('club-find-match-button')), findsOneWidget);
  });

  testWidgets('profile and club remain usable on a compact phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildFlow());
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('view-club-button')));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('club booking produces a complete confirmation', (tester) async {
    await tester.pumpWidget(buildFlow());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('view-club-button')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('view-club-button')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('club-book-button')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('club-book-button')));
    await tester.pumpAndSettle();
    expect(find.text('COURT RESERVED'), findsOneWidget);
    expect(find.text('VIEW CLUB'), findsOneWidget);
  });

  testWidgets('profile edit saves through the profile repository', (
    tester,
  ) async {
    final profiles = FakePlayerProfileRepository(profile: testProfile());
    await tester.pumpWidget(buildFlow(profileRepository: profiles));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('edit-profile-button')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('edit-profile-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-profile-button')));
    await tester.pumpAndSettle();
    expect(profiles.updateCalls, 1);
    expect(find.text('Player profile updated.'), findsOneWidget);
  });
}
