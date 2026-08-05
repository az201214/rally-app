import 'package:flutter_test/flutter_test.dart';
import 'package:rally/demo/demo_chat_repository.dart';
import 'package:rally/features/chat/domain/chat_models.dart';
import 'package:rally/features/chat/domain/chat_repository.dart';
import 'package:rally/features/matchmaking/domain/matchmaking_models.dart';

void main() {
  group('chat domain', () {
    test('serializes thread and message safely', () {
      final time = DateTime.utc(2026, 8, 5, 10);
      final thread = ChatThread(
        id: 'thread_match-1',
        matchId: 'match-1',
        participantIds: const <String>['a', 'b'],
        createdAt: time,
        updatedAt: time,
        lastMessageText: 'Ready',
        lastMessageAt: time,
        lastMessageSenderId: 'a',
      );
      final message = _message('message-1', time);

      expect(ChatThread.fromMap(thread.toMap()).toMap(), thread.toMap());
      expect(ChatMessage.fromMap(message.toMap()).toMap(), message.toMap());
    });

    test('thread ID is deterministic', () {
      expect(chatThreadIdForMatch('match-1'), 'thread_match-1');
      expect(chatThreadIdForMatch('match-1'), 'thread_match-1');
    });

    test('thread creation is idempotent and requires confirmation', () async {
      final repository = DemoChatRepository();
      final confirmed = _match(RallyMatchStatus.confirmed);
      final first = await repository.getOrCreateThread(
        match: confirmed,
        userId: 'a',
      );
      final second = await repository.getOrCreateThread(
        match: confirmed,
        userId: 'a',
      );
      expect(identical(first, second), isTrue);
      expect(
        () => repository.getOrCreateThread(
          match: _match(RallyMatchStatus.awaitingAcceptance),
          userId: 'a',
        ),
        throwsA(isA<ChatAccessException>()),
      );
      expect(
        () => repository.getOrCreateThread(match: confirmed, userId: 'x'),
        throwsA(isA<ChatAccessException>()),
      );
    });

    test('messages remain ordered and persist for new listeners', () async {
      final repository = DemoChatRepository();
      final thread = await repository.getOrCreateThread(
        match: _match(RallyMatchStatus.confirmed),
        userId: 'a',
      );
      await repository.sendMessage(
        _message('later', DateTime.utc(2026, 8, 5, 11), thread.id),
      );
      await repository.sendMessage(
        _message('earlier', DateTime.utc(2026, 8, 5, 10), thread.id),
      );

      final reloaded = await repository.watchMessages(thread.id).first;
      expect(reloaded.map((item) => item.id), <String>['earlier', 'later']);
      expect(
        reloaded.every((item) => item.status == ChatMessageStatus.sent),
        isTrue,
      );
    });
  });
}

ChatMessage _message(
  String id,
  DateTime time, [
  String threadId = 'thread_match-1',
]) {
  return ChatMessage(
    id: id,
    threadId: threadId,
    matchId: 'match-1',
    senderId: 'a',
    senderName: 'A',
    senderPhotoUrl: '',
    text: id,
    type: ChatMessageType.text,
    createdAt: time,
    readBy: const <String>['a'],
    status: ChatMessageStatus.sending,
  );
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
