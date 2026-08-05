import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rally/features/authentication/application/auth_providers.dart';
import 'package:rally/features/authentication/domain/auth_user.dart';
import 'package:rally/demo/demo_matchmaking_repositories.dart';
import 'package:rally/demo/demo_chat_repository.dart';
import 'package:rally/features/chat/application/chat_providers.dart';
import 'package:rally/features/chat/presentation/screens/match_chat_screen.dart';
import 'package:rally/features/clubs/presentation/screens/club_details_screen.dart';
import 'package:rally/features/match/presentation/screens/match_details_screen.dart';
import 'package:rally/features/match/presentation/screens/match_found_screen.dart';
import 'package:rally/features/matchmaking/application/matchmaking_controller.dart';
import 'package:rally/features/matchmaking/domain/matchmaking_models.dart';
import 'package:rally/features/profile/presentation/screens/player_profile_screen.dart';
import 'package:rally/features/searching/presentation/screens/searching_screen.dart';
import 'package:rally/theme/app_theme.dart';

import '../helpers/fake_repositories.dart';

void main() {
  testWidgets('client demo journey reaches every match destination', (
    tester,
  ) async {
    final auth = FakeAuthRepository(
      user: const AuthUser(uid: 'user-1', email: 'hamza@rally.pk'),
    );
    final router = GoRouter(
      initialLocation: '/searching',
      routes: <RouteBase>[
        GoRoute(
          path: '/searching',
          builder: (_, _) =>
              const SearchingScreen(matchDelay: Duration(milliseconds: 300)),
        ),
        GoRoute(
          path: '/match-found',
          builder: (_, _) => const MatchFoundScreen(allowPreviewData: true),
        ),
        GoRoute(
          path: '/match-details',
          builder: (_, _) => MatchDetailsScreen(match: _confirmedMatch()),
        ),
        GoRoute(
          path: '/match-chat',
          builder: (_, _) => MatchChatScreen(match: _confirmedMatch()),
        ),
        GoRoute(
          path: '/player-profile',
          builder: (_, _) => const PlayerProfileScreen(),
        ),
        GoRoute(
          path: '/club-details',
          builder: (_, _) => const ClubDetailsScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: Text('Home')),
        ),
      ],
    );
    addTearDown(() {
      router.dispose();
      auth.dispose();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          playerProfileRepositoryProvider.overrideWithValue(
            FakePlayerProfileRepository(profile: testProfile()),
          ),
          availabilityRepositoryProvider.overrideWithValue(
            DemoAvailabilityRepository(),
          ),
          matchmakingRepositoryProvider.overrideWithValue(
            DemoMatchmakingRepository(),
          ),
          chatRepositoryProvider.overrideWithValue(DemoChatRepository()),
        ],
        child: MaterialApp.router(
          theme: AppTheme.darkTheme,
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(find.text('YOUR RALLY\nIS READY'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('accept-match-button')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('accept-match-button')));
    await tester.pumpAndSettle();
    expect(find.text('MATCH DETAILS'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('OPEN MATCH CHAT'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -120));
    await tester.pump();
    await tester.tap(find.text('OPEN MATCH CHAT'));
    await tester.pumpAndSettle();
    expect(find.text('Hamza Khan'), findsOneWidget);

    await tester.tap(find.byKey(const Key('chat-profile-button')));
    await tester.pumpAndSettle();
    expect(find.text('HAMZA KHAN'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('view-club-button')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('view-club-button')));
    await tester.pumpAndSettle();
    expect(find.text('PADELVERSE'), findsOneWidget);
  });
}

RallyMatch _confirmedMatch() {
  final now = DateTime.utc(2026, 8, 5, 10);
  return RallyMatch(
    id: 'demo-match',
    participantIds: const <String>['user-1', 'user-2'],
    participants: const <MatchParticipant>[],
    city: 'Karachi',
    clubId: 'padelverse-clifton',
    clubName: 'Padelverse Clifton',
    scheduledStart: now,
    scheduledEnd: now.add(const Duration(minutes: 90)),
    status: RallyMatchStatus.confirmed,
    compatibilityScore: 94,
    compatibilityReasons: const <String>['Overlapping availability'],
    createdBy: 'user-1',
    createdAt: now,
    updatedAt: now,
    expiresAt: now.add(const Duration(hours: 1)),
    confirmedAt: now,
    cancellationReason: '',
  );
}
