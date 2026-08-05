import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rally/demo/demo_chat_repository.dart';
import 'package:rally/features/authentication/application/auth_providers.dart';
import 'package:rally/features/authentication/domain/auth_user.dart';
import 'package:rally/features/chat/application/chat_providers.dart';
import 'package:rally/features/chat/presentation/screens/match_chat_screen.dart';
import 'package:rally/features/matchmaking/domain/matchmaking_models.dart';
import 'package:rally/theme/app_theme.dart';

import '../../helpers/fake_repositories.dart';

void main() {
  Widget buildScreen({RallyMatchStatus status = RallyMatchStatus.confirmed}) {
    final auth = FakeAuthRepository(
      user: const AuthUser(uid: 'a', email: 'a@rally.pk'),
    );
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        playerProfileRepositoryProvider.overrideWithValue(
          FakePlayerProfileRepository(profile: testProfile(uid: 'a')),
        ),
        chatRepositoryProvider.overrideWithValue(DemoChatRepository()),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: MatchChatScreen(match: _match(status)),
      ),
    );
  }

  testWidgets('confirmed match renders and sends a persisted message', (
    tester,
  ) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();
    expect(find.text('MATCH CONFIRMED'), findsOneWidget);
    expect(find.text('Start the rally'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('match-chat-input')),
      'See you there!',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('match-chat-send')));
    await tester.pumpAndSettle();

    expect(find.text('See you there!'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('match-chat-input')))
          .controller
          ?.text,
      isEmpty,
    );
  });

  testWidgets('unconfirmed match is denied', (tester) async {
    await tester.pumpWidget(
      buildScreen(status: RallyMatchStatus.awaitingAcceptance),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('temporarily disconnected'), findsOneWidget);
    expect(find.byKey(const Key('match-chat-input')), findsNothing);
  });

  testWidgets('production UI hides unsupported attachments', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-attachment-button')), findsNothing);
  });
}

RallyMatch _match(RallyMatchStatus status) {
  final now = DateTime.utc(2026, 8, 5, 10);
  return RallyMatch(
    id: 'match-1',
    participantIds: const <String>['a', 'b'],
    participants: const <MatchParticipant>[],
    city: 'Karachi',
    clubId: 'club-1',
    clubName: 'Padelverse',
    scheduledStart: now,
    scheduledEnd: now.add(const Duration(hours: 1)),
    status: status,
    compatibilityScore: 94,
    compatibilityReasons: const <String>['Same city'],
    createdBy: 'a',
    createdAt: now,
    updatedAt: now,
    expiresAt: now.add(const Duration(hours: 1)),
    confirmedAt: status == RallyMatchStatus.confirmed ? now : null,
    cancellationReason: '',
  );
}
