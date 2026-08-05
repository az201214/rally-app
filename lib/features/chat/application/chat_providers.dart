import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../authentication/application/auth_providers.dart';
import '../../matchmaking/domain/matchmaking_models.dart';
import '../../profile/domain/player_profile.dart';
import '../data/firestore_chat_repository.dart';
import '../domain/chat_models.dart';
import '../domain/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => FirestoreChatRepository(FirebaseFirestore.instance),
);

final activeChatThreadProvider = FutureProvider.autoDispose
    .family<ChatThread, RallyMatch>((ref, match) async {
      final user =
          ref.watch(authStateProvider).value ??
          ref.read(authRepositoryProvider).currentUser;
      if (user == null) {
        throw const ChatAccessException('Sign in to open chat.');
      }
      if (kDebugMode) {
        debugPrint(
          <String, Object>{
            'scope': 'rally_chat',
            'event': 'open_chat',
            'authUid': user.uid,
            'activeMatchId': match.id,
          }.toString(),
        );
      }
      final repository = ref.watch(chatRepositoryProvider);
      final thread = await repository.getOrCreateThread(
        match: match,
        userId: user.uid,
      );
      ref.onDispose(() => unawaited(repository.leaveThreadCleanup(thread.id)));
      return thread;
    });

final chatMessagesProvider = StreamProvider.autoDispose
    .family<List<ChatMessage>, String>((ref, threadId) {
      return ref.watch(chatRepositoryProvider).watchMessages(threadId);
    });

enum ChatConnectionState { empty, ready, sending, error, disconnected }

class ChatMutationState {
  const ChatMutationState({
    this.connection = ChatConnectionState.ready,
    this.failedMessage,
    this.message,
  });
  final ChatConnectionState connection;
  final ChatMessage? failedMessage;
  final String? message;
}

final chatControllerProvider =
    NotifierProvider<ChatController, ChatMutationState>(ChatController.new);

class ChatController extends Notifier<ChatMutationState> {
  bool _sending = false;

  @override
  ChatMutationState build() {
    ref.listen(authStateProvider, (_, next) {
      if (!next.isLoading && next.value == null) {
        _sending = false;
        state = const ChatMutationState(
          connection: ChatConnectionState.disconnected,
        );
      }
    });
    return const ChatMutationState();
  }

  Future<bool> send({
    required ChatThread thread,
    required PlayerProfile? profile,
    required String text,
  }) async {
    final user =
        ref.read(authStateProvider).value ??
        ref.read(authRepositoryProvider).currentUser;
    final clean = text.trim();
    if (_sending || user == null || clean.isEmpty) return false;
    _sending = true;
    final message = ChatMessage(
      id: const Uuid().v4(),
      threadId: thread.id,
      matchId: thread.matchId,
      senderId: user.uid,
      senderName: profile?.fullName ?? user.email.split('@').first,
      senderPhotoUrl: profile?.photoUrl ?? '',
      text: clean,
      type: ChatMessageType.text,
      createdAt: DateTime.now().toUtc(),
      readBy: <String>[user.uid],
      status: ChatMessageStatus.sending,
    );
    state = const ChatMutationState(connection: ChatConnectionState.sending);
    try {
      await ref.read(chatRepositoryProvider).sendMessage(message);
      state = const ChatMutationState(connection: ChatConnectionState.ready);
      return true;
    } catch (_) {
      state = ChatMutationState(
        connection: ChatConnectionState.error,
        failedMessage: message,
        message: 'Message could not be sent. Check your connection.',
      );
      return false;
    } finally {
      _sending = false;
    }
  }

  Future<bool> retry() async {
    if (_sending || state.failedMessage == null) return false;
    _sending = true;
    final failed = state.failedMessage!;
    state = const ChatMutationState(connection: ChatConnectionState.sending);
    try {
      await ref.read(chatRepositoryProvider).retryMessage(failed);
      state = const ChatMutationState(connection: ChatConnectionState.ready);
      return true;
    } catch (_) {
      state = ChatMutationState(
        connection: ChatConnectionState.error,
        failedMessage: failed,
        message: 'Message still could not be sent.',
      );
      return false;
    } finally {
      _sending = false;
    }
  }

  Future<void> markRead(String threadId) async {
    final user =
        ref.read(authStateProvider).value ??
        ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;
    try {
      await ref
          .read(chatRepositoryProvider)
          .markMessagesRead(threadId, user.uid);
    } catch (_) {
      // Read receipts are best-effort and never block conversation access.
    }
  }
}
