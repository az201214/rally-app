import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rally/features/authentication/presentation/screens/login_screen.dart';
import 'package:rally/features/authentication/presentation/screens/register_screen.dart';
import 'package:rally/features/authentication/application/auth_providers.dart';
import 'package:rally/theme/app_theme.dart';

import '../../helpers/fake_repositories.dart';

void main() {
  Widget buildRegister({String initialLocation = '/register'}) {
    final auth = FakeAuthRepository(delay: const Duration(milliseconds: 500));
    final profiles = FakePlayerProfileRepository();
    addTearDown(auth.dispose);
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: <RouteBase>[
        GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: Text('Home ready')),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (_, _) => const Scaffold(body: Text('Reset')),
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

  Finder fieldInside(Key key) => find.descendant(
    of: find.byKey(key),
    matching: find.byType(TextFormField),
  );

  testWidgets('renders the complete registration form', (tester) async {
    await tester.pumpWidget(buildRegister());

    expect(find.text('CREATE YOUR PLAYER PROFILE'), findsOneWidget);
    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);
    expect(find.byKey(const Key('create-account-button')), findsOneWidget);
    expect(find.byKey(const Key('register-back-button')), findsOneWidget);
    expect(find.byKey(const Key('register-login-link')), findsOneWidget);
  });

  testWidgets('shows validation messages for incomplete details', (
    tester,
  ) async {
    await tester.pumpWidget(buildRegister());
    await tester.enterText(fieldInside(const Key('register-name-field')), '');
    await tester.enterText(
      fieldInside(const Key('register-email-field')),
      'invalid',
    );
    await tester.enterText(
      fieldInside(const Key('register-password-field')),
      'short',
    );
    await tester.enterText(
      fieldInside(const Key('register-confirm-password-field')),
      'different',
    );
    await tester.pump();

    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.text('Use at least 8 characters.'), findsOneWidget);
    expect(find.text('Passwords do not match.'), findsOneWidget);
  });

  testWidgets('shows loading and creates an account with valid details', (
    tester,
  ) async {
    await tester.pumpWidget(buildRegister());
    await tester.enterText(
      fieldInside(const Key('register-name-field')),
      'Areeb Khan',
    );
    await tester.enterText(
      fieldInside(const Key('register-email-field')),
      'areeb@rally.pk',
    );
    await tester.enterText(
      fieldInside(const Key('register-password-field')),
      'rallypass',
    );
    await tester.enterText(
      fieldInside(const Key('register-confirm-password-field')),
      'rallypass',
    );
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('create-account-button')));
    await tester.tap(find.byKey(const Key('create-account-button')));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 550));
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('login link and back button return to Login', (tester) async {
    await tester.pumpWidget(buildRegister());
    await tester.ensureVisible(find.byKey(const Key('register-login-link')));
    await tester.tap(find.byKey(const Key('register-login-link')));
    await tester.pumpAndSettle();
    expect(find.text('WELCOME BACK'), findsOneWidget);

    final router = GoRouter.of(tester.element(find.text('WELCOME BACK')));
    router.push('/register');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('register-back-button')));
    await tester.pumpAndSettle();
    expect(find.text('WELCOME BACK'), findsOneWidget);
  });
}
