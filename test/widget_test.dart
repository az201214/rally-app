<<<<<<< HEAD
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
=======
// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rally/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
>>>>>>> b7b6785ab2bd6415cf5306e7b4d41033779ecffb
