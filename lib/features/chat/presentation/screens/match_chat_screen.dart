import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../demo/demo_mode.dart';
import '../../../../demo/rally_demo_service.dart';
import '../../../../routes/app_routes.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_spacing.dart';

class MatchChatScreen extends StatefulWidget {
  const MatchChatScreen({super.key});

  @override
  State<MatchChatScreen> createState() => _MatchChatScreenState();
}

class _MatchChatScreenState extends State<MatchChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocus = FocusNode();
  final List<String> _sentMessages = <String>[];

  List<String> get _sessionMessages => DemoMode.enabled
      ? RallyDemoService.instance.chatMessages
      : List<String>.unmodifiable(_sentMessages);

  bool get _canSend => _messageController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onMessageChanged);
    if (DemoMode.enabled) RallyDemoService.instance.addListener(_onDemoChanged);
  }

  void _onDemoChanged() {
    if (mounted) setState(() {});
  }

  void _onMessageChanged() => setState(() {});

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    HapticFeedback.lightImpact();
    if (DemoMode.enabled) {
      RallyDemoService.instance.sendChatMessage(message);
    } else {
      setState(() => _sentMessages.add(message));
    }
    _messageController.clear();
    _messageFocus.requestFocus();
  }

  @override
  void dispose() {
    _messageController
      ..removeListener(_onMessageChanged)
      ..dispose();
    _messageFocus.dispose();
    if (DemoMode.enabled) {
      RallyDemoService.instance.removeListener(_onDemoChanged);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.carbonBlack,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: <Widget>[
                const _ChatHeader(),
                const _MatchContextStrip(),
                Expanded(
                  child: ListView(
                    key: const Key('match-chat-messages'),
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    children: <Widget>[
                      for (final message in _sessionMessages.reversed)
                        _MessageBubble(
                          message: message,
                          time: 'Now',
                          isMine: true,
                        ),
                      const _MessageBubble(
                        message: 'Perfect. See you on court.',
                        time: '7:09 PM',
                        isMine: false,
                      ),
                      const _MessageBubble(
                        message: 'I’ll be there 10 minutes early.',
                        time: '7:08 PM',
                        isMine: true,
                      ),
                      const _MessageBubble(
                        message: 'Hey! Looking forward to a good match.',
                        time: '7:06 PM',
                        isMine: false,
                      ),
                      const _SystemMessage(),
                    ],
                  ),
                ),
                _QuickReplies(
                  onSelected: (message) {
                    _messageController.text = message;
                    _sendMessage();
                  },
                ),
                _Composer(
                  controller: _messageController,
                  focusNode: _messageFocus,
                  canSend: _canSend,
                  onSend: _sendMessage,
                  onAttachment: () => _showAttachmentSheet(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAttachmentSheet(BuildContext context) {
    return showModalBottomSheet<void>(
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
            const _AttachmentOption(
              icon: Icons.photo_outlined,
              title: 'Photo',
              subtitle: 'Share a court or equipment photo',
            ),
            const _AttachmentOption(
              icon: Icons.location_on_outlined,
              title: 'Location',
              subtitle: 'Share your arrival location',
            ),
            const _AttachmentOption(
              icon: Icons.sports_tennis_outlined,
              title: 'Match details',
              subtitle: 'Share the confirmed match card',
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentOption extends StatelessWidget {
  const _AttachmentOption({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: AppColors.electricGreen),
    title: Text(title),
    subtitle: Text(subtitle),
    onTap: () => Navigator.of(context).pop(),
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

class _ChatHeader extends StatelessWidget {
  const _ChatHeader();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? AppSpacing.xs : AppSpacing.md,
            AppSpacing.sm,
            compact ? AppSpacing.xs : AppSpacing.md,
            AppSpacing.sm,
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
              SizedBox(width: compact ? AppSpacing.xs : AppSpacing.sm),
              if (!compact) ...<Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceElevated,
                    border: Border.all(color: AppColors.borderStrong),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Hamza Khan',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    const Row(
                      children: <Widget>[
                        _OnlineDot(),
                        SizedBox(width: AppSpacing.xxs),
                        Text(
                          'Match confirmed',
                          style: TextStyle(
                            color: AppColors.electricGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => context.push(AppRoutes.playerProfile),
                tooltip: 'View Hamza’s profile',
                icon: const Icon(Icons.person_search_rounded),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OnlineDot extends StatelessWidget {
  const _OnlineDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.electricGreen,
      ),
    );
  }
}

class _MatchContextStrip extends StatelessWidget {
  const _MatchContextStrip();

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.lg,
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.electricGreen.withValues(alpha: 0.07),
        borderRadius: AppRadius.medium,
        border: Border.all(
          color: AppColors.electricGreen.withValues(alpha: 0.2),
        ),
      ),
      child: const Row(
        children: <Widget>[
          Icon(
            Icons.sports_tennis_rounded,
            color: AppColors.electricGreen,
            size: 20,
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'TODAY · 7:30 PM',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  'Padelverse Clifton · Court 03',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}

class _SystemMessage extends StatelessWidget {
  const _SystemMessage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        children: <Widget>[
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.electricGreen,
            size: 22,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'MATCH CONFIRMED',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.electricGreen,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Use this space to coordinate the match.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
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
  Widget build(BuildContext context) {
    return Align(
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
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadius.lg),
            topRight: const Radius.circular(AppRadius.lg),
            bottomLeft: Radius.circular(isMine ? AppRadius.lg : AppRadius.sm),
            bottomRight: Radius.circular(isMine ? AppRadius.sm : AppRadius.lg),
          ),
          border: isMine ? null : Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.canSend,
    required this.onSend,
    required this.onAttachment,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool canSend;
  final VoidCallback onSend;
  final VoidCallback onAttachment;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? AppSpacing.sm : AppSpacing.lg,
        AppSpacing.sm,
        compact ? AppSpacing.sm : AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle.withValues(alpha: 0.8)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: TextField(
              key: const Key('match-chat-input'),
              controller: controller,
              focusNode: focusNode,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submitIfPossible(),
              decoration: InputDecoration(
                hintText: 'Message Hamza…',
                prefixIcon: IconButton(
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
            icon: const Icon(Icons.arrow_upward_rounded),
          ),
        ],
      ),
    );
  }

  void _submitIfPossible() {
    if (canSend) onSend();
  }
}
