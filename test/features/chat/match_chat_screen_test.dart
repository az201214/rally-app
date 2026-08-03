import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rally/features/chat/presentation/screens/match_chat_screen.dart';
import 'package:rally/theme/app_theme.dart';

void main() {
  Widget buildScreen() {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const MatchChatScreen(),
    );
  }

  testWidgets('renders match context and sends a message', (tester) async {
    await tester.pumpWidget(buildScreen());

    expect(find.text('Hamza Khan'), findsOneWidget);
    expect(find.text('Padelverse Clifton · Court 03'), findsOneWidget);
    expect(find.text('MATCH CONFIRMED'), findsOneWidget);

    final sendButton = tester.widget<IconButton>(
      find.byKey(const Key('match-chat-send')),
    );
    expect(sendButton.onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('match-chat-input')),
      'See you there!',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('match-chat-send')));
    await tester.pump();

    expect(find.text('See you there!'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('match-chat-input')))
          .controller
          ?.text,
      isEmpty,
    );
  });

  testWidgets('renders without overflow on a compact display', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildScreen());
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('opens attachment options and quick replies send', (
    tester,
  ) async {
    await tester.pumpWidget(buildScreen());
    await tester.tap(find.byKey(const Key('chat-attachment-button')));
    await tester.pumpAndSettle();

    expect(find.text('SHARE WITH THE MATCH'), findsOneWidget);
    expect(find.text('Photo'), findsOneWidget);
    expect(find.text('Location'), findsOneWidget);
    expect(find.text('Match details'), findsOneWidget);
    await tester.tap(find.text('Photo'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('On my way.'));
    await tester.pump();
    expect(find.text('On my way.'), findsNWidgets(2));
  });
}
