import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally/app/rally_app.dart';
import 'package:rally/features/authentication/application/auth_providers.dart';

import 'helpers/fake_repositories.dart';

void main() {
  testWidgets('real RallyApp routes Login to the complete Register form', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          playerProfileRepositoryProvider.overrideWithValue(
            FakePlayerProfileRepository(),
          ),
        ],
        child: const RallyApp(),
      ),
    );

    expect(find.text('NEVER PLAY ALONE'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.text('NEVER PLAY ALONE'), findsOneWidget);
    expect(find.text('YOUR NEXT MATCH\nSTARTS HERE'), findsNothing);
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    expect(find.text('YOUR NEXT MATCH\nSTARTS HERE'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const Key('onboarding-continue-button')),
    );
    await tester.tap(find.byKey(const Key('onboarding-continue-button')));
    await tester.pumpAndSettle();

    expect(find.text('WELCOME BACK'), findsOneWidget);
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('CREATE YOUR PLAYER PROFILE'), findsOneWidget);
    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);
    expect(find.byKey(const Key('create-account-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('register-back-button')));
    await tester.pumpAndSettle();

    expect(find.text('WELCOME BACK'), findsOneWidget);
    expect(find.text('WELCOME BACK'), findsOneWidget);
  });
}
