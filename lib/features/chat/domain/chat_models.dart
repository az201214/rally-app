enum ChatMessageType { text, system }

enum ChatMessageStatus { sending, sent, failed }

DateTime _chatDate(Object? value) {
  if (value is DateTime) return value.toUtc();
  try {
    final dynamic timestamp = value;
    final converted = timestamp?.toDate();
    if (converted is DateTime) return converted.toUtc();
  } catch (_) {}
  if (value is String) {
    return DateTime.tryParse(value)?.toUtc() ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
  return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}

String _chatString(Object? value) => value is String ? value : '';

List<String> _chatStrings(Object? value) => value is Iterable
    ? value.whereType<String>().toList(growable: false)
    : const <String>[];

T _chatEnum<T extends Enum>(Iterable<T> values, Object? value, T fallback) {
  return values.where((item) => item.name == value).firstOrNull ?? fallback;
}

class ChatThread {
  const ChatThread({
    required this.id,
    required this.matchId,
    required this.participantIds,
    required this.createdAt,
    required this.updatedAt,
    required this.lastMessageText,
    this.lastMessageAt,
    required this.lastMessageSenderId,
  });

  factory ChatThread.fromMap(Map<String, Object?> map, {String? id}) {
    return ChatThread(
      id: _chatString(map['id']).isEmpty ? id ?? '' : _chatString(map['id']),
      matchId: _chatString(map['matchId']),
      participantIds: _chatStrings(map['participantIds']),
      createdAt: _chatDate(map['createdAt']),
      updatedAt: _chatDate(map['updatedAt']),
      lastMessageText: _chatString(map['lastMessageText']),
      lastMessageAt: map['lastMessageAt'] == null
          ? null
          : _chatDate(map['lastMessageAt']),
      lastMessageSenderId: _chatString(map['lastMessageSenderId']),
    );
  }

  final String id;
  final String matchId;
  final List<String> participantIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String lastMessageText;
  final DateTime? lastMessageAt;
  final String lastMessageSenderId;

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'matchId': matchId,
    'participantIds': participantIds,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'lastMessageText': lastMessageText,
    'lastMessageAt': lastMessageAt,
    'lastMessageSenderId': lastMessageSenderId,
  };
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.threadId,
    required this.matchId,
    required this.senderId,
    required this.senderName,
    required this.senderPhotoUrl,
    required this.text,
    required this.type,
    required this.createdAt,
    this.editedAt,
    this.deletedAt,
    required this.readBy,
    required this.status,
  });

  factory ChatMessage.fromMap(Map<String, Object?> map, {String? id}) {
    return ChatMessage(
      id: _chatString(map['id']).isEmpty ? id ?? '' : _chatString(map['id']),
      threadId: _chatString(map['threadId']),
      matchId: _chatString(map['matchId']),
      senderId: _chatString(map['senderId']),
      senderName: _chatString(map['senderName']),
      senderPhotoUrl: _chatString(map['senderPhotoUrl']),
      text: _chatString(map['text']),
      type: _chatEnum(
        ChatMessageType.values,
        map['type'],
        ChatMessageType.text,
      ),
      createdAt: _chatDate(map['createdAt']),
      editedAt: map['editedAt'] == null ? null : _chatDate(map['editedAt']),
      deletedAt: map['deletedAt'] == null ? null : _chatDate(map['deletedAt']),
      readBy: _chatStrings(map['readBy']),
      status: _chatEnum(
        ChatMessageStatus.values,
        map['status'],
        ChatMessageStatus.sent,
      ),
    );
  }

  final String id;
  final String threadId;
  final String matchId;
  final String senderId;
  final String senderName;
  final String senderPhotoUrl;
  final String text;
  final ChatMessageType type;
  final DateTime createdAt;
  final DateTime? editedAt;
  final DateTime? deletedAt;
  final List<String> readBy;
  final ChatMessageStatus status;

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'threadId': threadId,
    'matchId': matchId,
    'senderId': senderId,
    'senderName': senderName,
    'senderPhotoUrl': senderPhotoUrl,
    'text': text,
    'type': type.name,
    'createdAt': createdAt,
    'editedAt': editedAt,
    'deletedAt': deletedAt,
    'readBy': readBy,
    'status': status.name,
  };
}

String chatThreadIdForMatch(String matchId) => 'thread_$matchId';
