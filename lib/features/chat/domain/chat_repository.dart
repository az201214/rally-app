import '../../matchmaking/domain/matchmaking_models.dart';
import 'chat_models.dart';

abstract interface class ChatRepository {
  Future<ChatThread> getOrCreateThread({
    required RallyMatch match,
    required String userId,
  });
  Stream<ChatThread?> watchThread(String threadId);
  Stream<List<ChatMessage>> watchMessages(String threadId);
  Future<ChatMessage> sendMessage(ChatMessage message);
  Future<void> markMessagesRead(String threadId, String userId);
  Future<ChatMessage> retryMessage(ChatMessage message);
  Future<void> deleteMessage(ChatMessage message, String userId);
  Future<void> leaveThreadCleanup(String threadId);
}

class ChatAccessException implements Exception {
  const ChatAccessException(this.message);
  final String message;
  @override
  String toString() => message;
}
