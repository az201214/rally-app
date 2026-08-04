import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rally/features/journey/presentation/screens/journey_screens.dart';
import 'package:rally/theme/app_theme.dart';

void main() {
  Widget app(Widget child, {TextScaler scaler = TextScaler.noScaling}) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(360, 760),
          disableAnimations: true,
          textScaler: scaler,
        ),
        child: child,
      ),
    );
  }

  testWidgets('chat sends a local message', (tester) async {
    await tester.pumpWidget(app(const MatchChatScreen()));
    await tester.enterText(
      find.byKey(const Key('chat-input')),
      'See you courtside',
    );
    await tester.tap(find.byKey(const Key('send-message-button')));
    await tester.pump();

    expect(find.textContaining('See you courtside'), findsOneWidget);
  });

  testWidgets('profile handles compact screen and larger text', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      app(const PlayerProfileScreen(), scaler: const TextScaler.linear(1.3)),
    );
    await tester.pump();

    expect(find.text('AHMED RAZA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('match found exposes acceptance action', (tester) async {
    await tester.pumpWidget(app(const MatchFoundScreen()));
    expect(find.byKey(const Key('accept-match-button')), findsOneWidget);
    expect(find.text('94%'), findsOneWidget);
  });
}
