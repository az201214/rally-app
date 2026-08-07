import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rally/app/rally_app.dart';
import 'package:rally/demo/demo_profile_insights_repository.dart';
import 'package:rally/features/authentication/application/auth_providers.dart';
import 'package:rally/features/authentication/domain/auth_failure.dart';
import 'package:rally/features/authentication/domain/auth_user.dart';
import 'package:rally/features/authentication/presentation/screens/login_screen.dart';
import 'package:rally/routes/app_router.dart';
import 'package:rally/features/profile/application/profile_controller.dart';
import 'package:rally/theme/app_theme.dart';

import '../../helpers/fake_repositories.dart';

void main() {
  Finder field(Key key) => find.descendant(
    of: find.byKey(key),
    matching: find.byType(TextFormField),
  );

  Widget loginApp(FakeAuthRepository auth) => ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      playerProfileRepositoryProvider.overrideWithValue(
        FakePlayerProfileRepository(),
      ),
    ],
    child: MaterialApp(theme: AppTheme.darkTheme, home: const LoginScreen()),
  );

  testWidgets('login validates fields and prevents invalid submission', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    addTearDown(auth.dispose);
    await tester.pumpWidget(loginApp(auth));
    await tester.enterText(field(const Key('login-email-field')), 'invalid');
    await tester.enterText(field(const Key('login-password-field')), 'x');
    await tester.enterText(field(const Key('login-password-field')), '');
    await tester.pump();

    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
    expect(auth.loginCalls, 0);
  });

  testWidgets('login shows loading and translated authentication error', (
    tester,
  ) async {
    final auth = FakeAuthRepository(delay: const Duration(milliseconds: 400))
      ..nextFailure = const AuthFailure(AuthFailureCode.invalidCredentials);
    addTearDown(auth.dispose);
    await tester.pumpWidget(loginApp(auth));
    await tester.enterText(
      field(const Key('login-email-field')),
      'player@rally.pk',
    );
    await tester.enterText(
      field(const Key('login-password-field')),
      'incorrect',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('login-button')));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump();
    expect(find.text('Email or password is incorrect.'), findsOneWidget);
  });

  testWidgets(
    'unauthenticated users are redirected away from protected routes',
    (tester) async {
      final auth = FakeAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          playerProfileRepositoryProvider.overrideWithValue(
            FakePlayerProfileRepository(),
          ),
        ],
      );
      addTearDown(() {
        container.dispose();
        auth.dispose();
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const RallyApp(),
        ),
      );
      await tester.pump();
      container.read(appRouterProvider).go('/home');
      await tester.pumpAndSettle();
      expect(find.text('WELCOME BACK'), findsOneWidget);
    },
  );

  testWidgets('authenticated users can enter protected routes and log out', (
    tester,
  ) async {
    final auth = FakeAuthRepository(
      user: const AuthUser(uid: 'user-1', email: 'hamza@rally.pk'),
    );
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        playerProfileRepositoryProvider.overrideWithValue(
          FakePlayerProfileRepository(profile: testProfile()),
        ),
        profileInsightsRepositoryProvider.overrideWithValue(
          DemoProfileInsightsRepository(),
        ),
      ],
    );
    addTearDown(() {
      container.dispose();
      auth.dispose();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const RallyApp()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final GoRouter router = container.read(appRouterProvider);
    router.go('/player-profile');
    await tester.pumpAndSettle();
    expect(find.text('HAMZA KHAN'), findsOneWidget);

    await tester.tap(find.byKey(const Key('logout-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-logout-button')));
    await tester.pumpAndSettle();

    expect(auth.logoutCalls, 1);
    expect(find.text('WELCOME BACK'), findsOneWidget);
  });
}
