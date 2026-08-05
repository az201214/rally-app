import 'dart:async';

import '../features/chat/domain/chat_models.dart';
import '../features/chat/domain/chat_repository.dart';
import '../features/matchmaking/domain/matchmaking_models.dart';

class DemoChatRepository implements ChatRepository {
  final Map<String, ChatThread> _threads = <String, ChatThread>{};
  final Map<String, List<ChatMessage>> _messages =
      <String, List<ChatMessage>>{};
  final Map<String, StreamController<ChatThread?>> _threadChanges = {};
  final Map<String, StreamController<List<ChatMessage>>> _messageChanges = {};
  final Set<String> _sending = <String>{};

  @override
  Future<ChatThread> getOrCreateThread({
    required RallyMatch match,
    required String userId,
  }) async {
    if (match.status != RallyMatchStatus.confirmed ||
        !match.participantIds.contains(userId)) {
      throw const ChatAccessException(
        'Match chat is available only to confirmed participants.',
      );
    }
    final id = chatThreadIdForMatch(match.id);
    return _threads.putIfAbsent(id, () {
      final now = DateTime.now().toUtc();
      final thread = ChatThread(
        id: id,
        matchId: match.id,
        participantIds: match.participantIds,
        createdAt: now,
        updatedAt: now,
        lastMessageText: '',
        lastMessageSenderId: '',
      );
      _messages[id] = <ChatMessage>[];
      return thread;
    });
  }

  @override
  Stream<ChatThread?> watchThread(String threadId) => Stream.multi((listener) {
    listener.add(_threads[threadId]);
    final controller = _threadChanges.putIfAbsent(
      threadId,
      StreamController<ChatThread?>.broadcast,
    );
    final subscription = controller.stream.listen(listener.add);
    listener.onCancel = subscription.cancel;
  });

  @override
  Stream<List<ChatMessage>> watchMessages(String threadId) =>
      Stream.multi((listener) {
        listener.add(List<ChatMessage>.unmodifiable(_messages[threadId] ?? []));
        final controller = _messageChanges.putIfAbsent(
          threadId,
          StreamController<List<ChatMessage>>.broadcast,
        );
        final subscription = controller.stream.listen(listener.add);
        listener.onCancel = subscription.cancel;
      });

  @override
  Future<ChatMessage> sendMessage(ChatMessage message) async {
    if (!_sending.add(message.id)) throw StateError('Duplicate message.');
    try {
      final sent = ChatMessage(
        id: message.id,
        threadId: message.threadId,
        matchId: message.matchId,
        senderId: message.senderId,
        senderName: message.senderName,
        senderPhotoUrl: message.senderPhotoUrl,
        text: message.text.trim(),
        type: message.type,
        createdAt: message.createdAt,
        editedAt: message.editedAt,
        deletedAt: message.deletedAt,
        readBy: <String>[message.senderId],
        status: ChatMessageStatus.sent,
      );
      final messages = _messages.putIfAbsent(message.threadId, () => []);
      if (!messages.any((item) => item.id == message.id)) messages.add(sent);
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      _messageChanges[message.threadId]?.add(List.unmodifiable(messages));
      return sent;
    } finally {
      _sending.remove(message.id);
    }
  }

  @override
  Future<ChatMessage> retryMessage(ChatMessage message) => sendMessage(message);

  @override
  Future<void> markMessagesRead(String threadId, String userId) async {}

  @override
  Future<void> deleteMessage(ChatMessage message, String userId) async {}

  @override
  Future<void> leaveThreadCleanup(String threadId) async {}

  void dispose() {
    for (final controller in _threadChanges.values) {
      controller.close();
    }
    for (final controller in _messageChanges.values) {
      controller.close();
    }
  }
}
