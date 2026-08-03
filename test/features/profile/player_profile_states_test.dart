import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rally/features/authentication/application/auth_providers.dart';
import 'package:rally/features/authentication/domain/auth_user.dart';
import 'package:rally/features/profile/domain/profile_failure.dart';
import 'package:rally/features/profile/presentation/screens/player_profile_screen.dart';
import 'package:rally/theme/app_theme.dart';

import '../../helpers/fake_repositories.dart';

void main() {
  Widget profileApp(FakePlayerProfileRepository profiles) {
    final auth = FakeAuthRepository(
      user: const AuthUser(uid: 'user-1', email: 'hamza@rally.pk'),
    );
    addTearDown(auth.dispose);
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        playerProfileRepositoryProvider.overrideWithValue(profiles),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: const PlayerProfileScreen(),
      ),
    );
  }

  testWidgets('profile exposes loading then successful Firestore data', (
    tester,
  ) async {
    await tester.pumpWidget(
      profileApp(FakePlayerProfileRepository(profile: testProfile())),
    );
    expect(find.byKey(const Key('profile-loading')), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('HAMZA KHAN'), findsOneWidget);
    expect(find.text('92% reliable'), findsOneWidget);
  });

  testWidgets('profile renders an error with a retry action', (tester) async {
    await tester.pumpWidget(
      profileApp(
        FakePlayerProfileRepository(
          error: const ProfileFailure('Profile is temporarily unavailable.'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile-error')), findsOneWidget);
    expect(find.text('Profile is temporarily unavailable.'), findsOneWidget);
    expect(find.byKey(const Key('profile-retry-button')), findsOneWidget);
  });

  testWidgets('missing profile has a bounded empty state', (tester) async {
    await tester.pumpWidget(profileApp(FakePlayerProfileRepository()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile-empty')), findsOneWidget);
    expect(find.text('Your player profile is missing.'), findsOneWidget);
  });
}
