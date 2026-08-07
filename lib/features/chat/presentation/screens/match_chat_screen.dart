import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../demo/demo_mode.dart';
import '../../../../routes/app_routes.dart';
import '../../../../shared/widgets/rally_snackbar.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_spacing.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../matchmaking/application/matchmaking_controller.dart';
import '../../../matchmaking/domain/matchmaking_models.dart';
import '../../application/chat_providers.dart';
import '../../domain/chat_models.dart';

class MatchChatScreen extends ConsumerStatefulWidget {
  const MatchChatScreen({super.key, this.match});

  final RallyMatch? match;

  @override
  ConsumerState<MatchChatScreen> createState() => _MatchChatScreenState();
}

class _MatchChatScreenState extends ConsumerState<MatchChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _controller
      ..removeListener(_refresh)
      ..dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final match =
        widget.match ?? ref.watch(matchmakingControllerProvider).match;
    if (match == null) {
      return const _UnavailableChat(
        message: 'A confirmed match is required before chat can open.',
      );
    }
    final thread = ref.watch(activeChatThreadProvider(match));
    final mutation = ref.watch(chatControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.carbonBlack,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: <Widget>[
                _ChatHeader(
                  match: match,
                  currentUserId: ref.watch(authStateProvider).value?.uid ?? '',
                ),
                const _MatchContextStrip(),
                Expanded(child: _conversation(thread)),
                if (thread.value != null) ...<Widget>[
                  _QuickReplies(
                    onSelected: (text) => _send(thread.value!, text),
                  ),
                  if (mutation.failedMessage != null)
                    _RetryBar(
                      onRetry: () =>
                          ref.read(chatControllerProvider.notifier).retry(),
                    ),
                  _Composer(
                    controller: _controller,
                    focusNode: _focusNode,
                    canSend:
                        _controller.text.trim().isNotEmpty &&
                        mutation.connection != ChatConnectionState.sending,
                    sending: mutation.connection == ChatConnectionState.sending,
                    onSend: () => _send(thread.value!, _controller.text),
                    onAttachment: DemoMode.enabled
                        ? () => _showAttachmentSheet(context)
                        : null,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _conversation(AsyncValue<ChatThread> thread) => thread.when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (_, _) => const _ChatErrorState(),
    data: (value) {
      final messages = ref.watch(chatMessagesProvider(value.id));
      final userId = ref.watch(authStateProvider).value?.uid ?? '';
      return messages.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const _ChatErrorState(),
        data: (items) {
          if (items.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ref.read(chatControllerProvider.notifier).markRead(value.id);
              }
            });
          }
          return ListView(
            key: const Key('match-chat-messages'),
            reverse: true,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            children: <Widget>[
              if (items.isEmpty) const _FirstMessageState(),
              for (final message in items.reversed)
                _MessageBubble(
                  message: message.deletedAt == null
                      ? message.text
                      : 'Message deleted',
                  time: DateFormat.jm().format(message.createdAt.toLocal()),
                  isMine: message.senderId == userId,
                ),
              const _SystemMessage(),
            ],
          );
        },
      );
    },
  );

  Future<void> _send(ChatThread thread, String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    final cameFromComposer = _controller.text.trim() == clean;
    if (cameFromComposer) _controller.clear();
    HapticFeedback.lightImpact();
    final sent = await ref
        .read(chatControllerProvider.notifier)
        .send(
          thread: thread,
          profile: ref.read(currentPlayerProfileProvider).value,
          text: clean,
        );
    if (!mounted) return;
    if (sent) {
      _focusNode.requestFocus();
    } else {
      if (cameFromComposer && _controller.text.isEmpty) {
        _controller.text = clean;
      }
      RallySnackbar.show(
        context,
        message:
            ref.read(chatControllerProvider).message ??
            'Message could not be sent.',
        icon: Icons.cloud_off_rounded,
      );
    }
  }

  Future<void> _showAttachmentSheet(BuildContext context) =>
      showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        builder: (context) => Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'SHARE WITH THE MATCH',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              for (final item in const <(IconData, String)>[
                (Icons.photo_outlined, 'Photo'),
                (Icons.location_on_outlined, 'Location'),
                (Icons.sports_tennis_outlined, 'Match details'),
              ])
                ListTile(
                  leading: Icon(item.$1, color: AppColors.electricGreen),
                  title: Text(item.$2),
                  onTap: () => Navigator.pop(context),
                ),
            ],
          ),
        ),
      );
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.match, required this.currentUserId});

  final RallyMatch match;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final other = match.participants
        .where((participant) => participant.userId != currentUserId)
        .firstOrNull;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          IconButton.filledTonal(
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go(AppRoutes.matchDetails),
            tooltip: 'Back to match details',
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: AppSpacing.sm),
          const CircleAvatar(child: Icon(Icons.person_rounded)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  other?.displayName ?? 'Hamza Khan',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text(
                  'Match confirmed · Live',
                  style: TextStyle(
                    color: AppColors.electricGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: const Key('chat-profile-button'),
            onPressed: () => context.push(
              other == null
                  ? AppRoutes.playerProfile
                  : '${AppRoutes.playerProfile}?uid=${other.userId}',
            ),
            tooltip: 'View player profile',
            icon: const Icon(Icons.person_search_rounded),
          ),
        ],
      ),
    );
  }
}

class _MatchContextStrip extends StatelessWidget {
  const _MatchContextStrip();

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    padding: const EdgeInsets.all(AppSpacing.sm),
    decoration: BoxDecoration(
      color: AppColors.electricGreen.withValues(alpha: 0.07),
      borderRadius: AppRadius.medium,
      border: Border.all(color: AppColors.electricGreen.withValues(alpha: 0.2)),
    ),
    child: const Row(
      children: <Widget>[
        Icon(Icons.sports_tennis_rounded, color: AppColors.electricGreen),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'PADELVERSE CLIFTON · CONFIRMED',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.time,
    required this.isMine,
  });
  final String message;
  final String time;
  final bool isMine;

  @override
  Widget build(BuildContext context) => Align(
    alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      constraints: const BoxConstraints(maxWidth: 360),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isMine ? AppColors.electricGreen : AppColors.surfaceSecondary,
        borderRadius: AppRadius.large,
        border: isMine ? null : Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Text(
            message,
            style: TextStyle(
              color: isMine ? AppColors.textInverse : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            time,
            style: TextStyle(
              color: isMine
                  ? AppColors.textInverse.withValues(alpha: 0.62)
                  : AppColors.textTertiary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    ),
  );
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.canSend,
    required this.sending,
    required this.onSend,
    this.onAttachment,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool canSend;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback? onAttachment;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.sm,
      AppSpacing.lg,
      AppSpacing.md,
    ),
    decoration: const BoxDecoration(color: AppColors.surfacePrimary),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: TextField(
            key: const Key('match-chat-input'),
            controller: controller,
            focusNode: focusNode,
            maxLines: 4,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) {
              if (canSend) onSend();
            },
            decoration: InputDecoration(
              hintText: 'Message the match…',
              prefixIcon: onAttachment == null
                  ? null
                  : IconButton(
                      key: const Key('chat-attachment-button'),
                      onPressed: onAttachment,
                      tooltip: 'Add attachment',
                      icon: const Icon(Icons.add_circle_outline_rounded),
                    ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton.filled(
          key: const Key('match-chat-send'),
          onPressed: canSend ? onSend : null,
          tooltip: 'Send message',
          icon: sending
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.arrow_upward_rounded),
        ),
      ],
    ),
  );
}

class _QuickReplies extends StatelessWidget {
  const _QuickReplies({required this.onSelected});
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      children: <Widget>[
        for (final reply in const <String>[
          'On my way.',
          'I’ll arrive early.',
          'Ready to Rally.',
        ])
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: ActionChip(
              label: Text(reply),
              onPressed: () => onSelected(reply),
            ),
          ),
      ],
    ),
  );
}

class _SystemMessage extends StatelessWidget {
  const _SystemMessage();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(bottom: AppSpacing.lg),
    child: Column(
      children: <Widget>[
        Icon(Icons.check_circle_rounded, color: AppColors.electricGreen),
        SizedBox(height: AppSpacing.xs),
        Text('MATCH CONFIRMED'),
      ],
    ),
  );
}

class _FirstMessageState extends StatelessWidget {
  const _FirstMessageState();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
    child: Column(
      children: <Widget>[
        Icon(Icons.waving_hand_rounded, color: AppColors.electricGreen),
        SizedBox(height: AppSpacing.sm),
        Text('Start the rally'),
        SizedBox(height: AppSpacing.xxs),
        Text('Say hello and coordinate your arrival.'),
      ],
    ),
  );
}

class _ChatErrorState extends StatelessWidget {
  const _ChatErrorState();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Text(
        'Chat is temporarily disconnected. Check your connection and retry.',
        textAlign: TextAlign.center,
      ),
    ),
  );
}

class _RetryBar extends StatelessWidget {
  const _RetryBar({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    leading: const Icon(Icons.error_outline, color: AppColors.electricGreen),
    title: const Text('Message failed to send'),
    trailing: TextButton(onPressed: onRetry, child: const Text('RETRY')),
  );
}

class _UnavailableChat extends StatelessWidget {
  const _UnavailableChat({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.carbonBlack,
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.lock_clock_rounded, size: 44),
              const SizedBox(height: AppSpacing.md),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.matchDetails),
                child: const Text('BACK TO MATCH'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
