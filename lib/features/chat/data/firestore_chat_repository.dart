import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../matchmaking/domain/matchmaking_models.dart';
import '../domain/chat_models.dart';
import '../domain/chat_repository.dart';

class FirestoreChatRepository implements ChatRepository {
  FirestoreChatRepository(this._firestore);

  final FirebaseFirestore _firestore;
  final Set<String> _pendingMessageIds = <String>{};

  CollectionReference<Map<String, dynamic>> get _threads =>
      _firestore.collection('chatThreads');

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
    final threadId = chatThreadIdForMatch(match.id);
    final reference = _threads.doc(threadId);
    _log('thread_transaction', threadId: threadId, matchId: match.id);
    return _firestore
        .runTransaction((transaction) async {
          final snapshot = await transaction.get(reference);
          if (snapshot.exists) {
            return ChatThread.fromMap(snapshot.data()!, id: snapshot.id);
          }
          final now = DateTime.now().toUtc();
          final thread = ChatThread(
            id: threadId,
            matchId: match.id,
            participantIds: List<String>.unmodifiable(match.participantIds),
            createdAt: now,
            updatedAt: now,
            lastMessageText: '',
            lastMessageSenderId: '',
          );
          transaction.set(reference, thread.toMap());
          return thread;
        })
        .onError((error, stackTrace) {
          _log('thread_transaction_failed', threadId: threadId, error: error);
          throw error!;
        });
  }

  @override
  Stream<ChatThread?> watchThread(String threadId) {
    _log('thread_listener_attach', threadId: threadId);
    return _threads
        .doc(threadId)
        .snapshots()
        .map((snapshot) {
          return snapshot.exists
              ? ChatThread.fromMap(snapshot.data()!, id: snapshot.id)
              : null;
        })
        .transform(
          StreamTransformer.fromHandlers(
            handleError: (error, stackTrace, sink) {
              _log('thread_listener_error', threadId: threadId, error: error);
              sink.addError(error, stackTrace);
            },
          ),
        );
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String threadId) {
    _log('message_listener_attach', threadId: threadId);
    return _threads
        .doc(threadId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
          final messages = snapshot.docs
              .map((doc) => ChatMessage.fromMap(doc.data(), id: doc.id))
              .toList(growable: false);
          _log('messages_received', threadId: threadId, count: messages.length);
          return messages;
        })
        .transform(
          StreamTransformer.fromHandlers(
            handleError: (error, stackTrace, sink) {
              _log('message_listener_error', threadId: threadId, error: error);
              sink.addError(error, stackTrace);
            },
          ),
        );
  }

  @override
  Future<ChatMessage> sendMessage(ChatMessage message) async {
    final clean = message.text.trim();
    if (clean.isEmpty) throw ArgumentError('Message cannot be empty.');
    if (!_pendingMessageIds.add(message.id)) {
      throw StateError('This message is already sending.');
    }
    try {
      final sent = ChatMessage(
        id: message.id,
        threadId: message.threadId,
        matchId: message.matchId,
        senderId: message.senderId,
        senderName: message.senderName,
        senderPhotoUrl: message.senderPhotoUrl,
        text: clean,
        type: message.type,
        createdAt: message.createdAt,
        editedAt: message.editedAt,
        deletedAt: message.deletedAt,
        readBy: <String>[message.senderId],
        status: ChatMessageStatus.sent,
      );
      final thread = _threads.doc(message.threadId);
      final messageRef = thread.collection('messages').doc(message.id);
      final batch = _firestore.batch()
        ..set(messageRef, sent.toMap())
        ..update(thread, <String, Object?>{
          'lastMessageText': clean,
          'lastMessageAt': sent.createdAt,
          'lastMessageSenderId': sent.senderId,
          'updatedAt': sent.createdAt,
        });
      await batch.commit();
      _log('message_sent', threadId: message.threadId, messageId: message.id);
      return sent;
    } catch (error) {
      _log('message_send_failed', threadId: message.threadId, error: error);
      rethrow;
    } finally {
      _pendingMessageIds.remove(message.id);
    }
  }

  @override
  Future<ChatMessage> retryMessage(ChatMessage message) => sendMessage(message);

  @override
  Future<void> markMessagesRead(String threadId, String userId) async {
    final snapshot = await _threads
        .doc(threadId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();
    final unread = snapshot.docs.where((doc) {
      final readBy = doc.data()['readBy'];
      return readBy is! Iterable || !readBy.contains(userId);
    });
    final batch = _firestore.batch();
    var changed = false;
    for (final doc in unread) {
      changed = true;
      batch.update(doc.reference, <String, Object?>{
        'readBy': FieldValue.arrayUnion(<String>[userId]),
      });
    }
    if (changed) await batch.commit();
  }

  @override
  Future<void> deleteMessage(ChatMessage message, String userId) async {
    if (message.senderId != userId) {
      throw const ChatAccessException('Only your own message can be deleted.');
    }
    await _threads
        .doc(message.threadId)
        .collection('messages')
        .doc(message.id)
        .update(<String, Object?>{
          'text': '',
          'deletedAt': DateTime.now().toUtc(),
        });
  }

  @override
  Future<void> leaveThreadCleanup(String threadId) async {
    _log('listeners_disposed', threadId: threadId);
  }

  void _log(
    String event, {
    String? threadId,
    String? matchId,
    String? messageId,
    int? count,
    Object? error,
  }) {
    if (!kDebugMode) return;
    debugPrint(
      <String, Object?>{
        'scope': 'rally_chat',
        'event': event,
        'threadId': ?threadId,
        'matchId': ?matchId,
        'messageId': ?messageId,
        'count': ?count,
        if (error != null) 'error': error.runtimeType.toString(),
      }.toString(),
    );
  }
}
