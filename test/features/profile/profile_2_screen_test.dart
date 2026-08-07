import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rally/features/clubs/data/demo_club_repository.dart';
import 'package:rally/features/authentication/application/auth_providers.dart';
import 'package:rally/features/authentication/domain/auth_user.dart';
import 'package:rally/features/clubs/application/club_providers.dart';
import 'package:rally/features/profile/application/profile_controller.dart';
import 'package:rally/features/profile/domain/player_profile.dart';
import 'package:rally/features/profile/domain/player_profile_repository.dart';
import 'package:rally/features/profile/domain/profile_insights.dart';
import 'package:rally/features/profile/presentation/screens/player_profile_screen.dart';
import 'package:rally/demo/demo_profile_insights_repository.dart';
import 'package:rally/theme/app_theme.dart';

import '../../helpers/fake_repositories.dart';

void main() {
  Widget app({
    required PlayerProfile profile,
    String? playerId,
    PlayerProfileRepository? repository,
    ProfileInsightsRepository? insights,
    Size size = const Size(390, 844),
    double scale = 1,
  }) {
    final auth = FakeAuthRepository(
      user: const AuthUser(uid: 'owner', email: 'owner@example.com'),
    );
    addTearDown(auth.dispose);
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        playerProfileRepositoryProvider.overrideWithValue(
          repository ?? FakePlayerProfileRepository(profile: profile),
        ),
        profileInsightsRepositoryProvider.overrideWithValue(
          insights ?? _Insights(),
        ),
        clubRepositoryProvider.overrideWithValue(DemoClubRepository()),
        clubLocationServiceProvider.overrideWithValue(
          DemoClubLocationService(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(scale),
          ),
          child: PlayerProfileScreen(playerId: playerId),
        ),
      ),
    );
  }

  testWidgets(
    'owner controls render and public profile hides private controls',
    (tester) async {
      final owner = _profile('owner');
      await tester.pumpWidget(app(profile: owner));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('edit-profile-button')), findsOneWidget);
      expect(find.byKey(const Key('logout-button')), findsOneWidget);

      await tester.pumpWidget(
        app(profile: _profile('other'), playerId: 'other'),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('edit-profile-button')), findsNothing);
      expect(find.byKey(const Key('logout-button')), findsNothing);
      expect(find.textContaining('owner@example.com'), findsNothing);
    },
  );

  testWidgets('empty and populated match history states render', (
    tester,
  ) async {
    await tester.pumpWidget(app(profile: _profile('owner')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('MATCH HISTORY'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Padelverse Clifton'), findsWidgets);

    await tester.pumpWidget(
      app(profile: _profile('owner'), insights: _EmptyInsights()),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('No matches yet'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('No matches yet'), findsOneWidget);
  });

  testWidgets('favorite clubs and deleted club handling render safely', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(profile: _profile('owner', favorites: const ['padelverse-clifton'])),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('FAVORITE CLUBS'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Padelverse Clifton'), findsWidgets);

    await tester.pumpWidget(
      app(profile: _profile('owner', favorites: const ['deleted-club'])),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('no longer active'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('no longer active'), findsOneWidget);
  });

  testWidgets('edit validates required fields and saves once', (tester) async {
    final repository = FakePlayerProfileRepository(profile: _profile('owner'));
    await tester.pumpWidget(
      app(profile: repository.profile!, repository: repository),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('edit-profile-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Display name *'),
      '',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('save-profile-button')),
      400,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('save-profile-button')));
    await tester.pump();
    expect(find.text('Enter at least two characters.'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Display name *'),
      'Updated Player',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('save-profile-button')),
      400,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('save-profile-button')));
    await tester.pumpAndSettle();
    expect(repository.updateCalls, 1);
    expect(find.text('Player profile updated.'), findsOneWidget);
  });

  testWidgets(
    'compact layout, text scaling and reduced motion do not overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        app(profile: _profile('owner'), size: const Size(320, 640), scale: 1.3),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  test('duplicate save is rejected while mutation is running', () async {
    final repository = _SlowRepository(_profile('owner'));
    final container = ProviderContainer(
      overrides: [
        playerProfileRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(profileUpdateControllerProvider.notifier);
    final first = controller.saveProfile(repository.profile);
    await Future<void>.delayed(Duration.zero);
    expect(await controller.saveProfile(repository.profile), isFalse);
    expect(await first, isTrue);
    expect(repository.updates, 1);
  });
}

class _Insights extends DemoProfileInsightsRepository {}

class _EmptyInsights implements ProfileInsightsRepository {
  @override
  Stream<List<ProfileMatchHistoryItem>> watchMatchHistory(
    String uid, {
    int limit = 25,
  }) => Stream.value(<ProfileMatchHistoryItem>[]);
}

PlayerProfile _profile(String uid, {List<String> favorites = const []}) =>
    PlayerProfile.fromMap(<String, Object?>{
      'uid': uid,
      'fullName': uid == 'owner' ? 'Owner Player' : 'Public Player',
      'email': 'owner@example.com',
      'bio': 'Reliable padel player',
      'city': 'Karachi',
      'skillLevel': 'Advanced',
      'preferredSide': 'Right',
      'playingHand': 'Right',
      'playingStyle': 'Balanced',
      'preferredDays': <String>['Saturday'],
      'preferredTimeRanges': <String>['Evening'],
      'preferredClubIds': <String>['padelverse-clifton'],
      'favoriteClubIds': favorites,
      'createdAt': '2026-01-01T00:00:00Z',
    });

class _SlowRepository implements PlayerProfileRepository {
  _SlowRepository(this.profile);
  final PlayerProfile profile;
  int updates = 0;
  @override
  Stream<PlayerProfile?> watchProfile(String uid) => Stream.value(profile);
  @override
  Stream<PlayerProfile?> watchPublicProfile(String uid) =>
      Stream.value(profile);
  @override
  Future<PlayerProfile?> loadProfile(String uid) async => profile;
  @override
  Future<void> createProfile(PlayerProfile profile) async {}
  @override
  Future<void> updateProfile(PlayerProfile profile) async {
    updates++;
    await Future<void>.delayed(const Duration(milliseconds: 40));
  }
}
