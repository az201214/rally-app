import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/app_routes.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/rally_components.dart';
import '../../../../shared/widgets/secondary_button.dart';
import '../../../../theme/app_spacing.dart';

class MatchFoundScreen extends StatelessWidget {
  const MatchFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _JourneyPage(
      eyebrow: 'RALLY PULSE / MATCH FOUND',
      title: 'YOUR COURT IS READY',
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.lg),
          RallyGlassPanel(
            child: Row(
              children: [
                const RallyAvatar(initials: 'AR', size: 72),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ahmed Raza',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      const Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          RallyStatusChip(label: 'Intermediate'),
                          RallyStatusChip(
                            label: '98% reliable',
                            icon: Icons.shield_outlined,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const CompatibilityRing(size: 76),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const RallyGlassPanel(
            child: Column(
              children: [
                RallyInfoRow(
                  icon: Icons.schedule_rounded,
                  label: 'When',
                  value: 'Tonight · 8:30 PM',
                ),
                RallyInfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Court',
                  value: 'Rally Padel Club · 2.4 km',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            key: Key('accept-match-button'),
            label: 'ACCEPT MATCH',
            icon: Icons.bolt_rounded,
            onPressed: () => context.go(AppRoutes.matchDetails),
          ),
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(
            label: 'Keep searching',
            onPressed: () => context.go(AppRoutes.searching),
          ),
        ],
      ),
    );
  }
}

class MatchDetailsScreen extends StatelessWidget {
  const MatchDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _JourneyPage(
      eyebrow: 'MATCH / CONFIRMED',
      title: 'THURSDAY NIGHT PADEL',
      showBack: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.lg),
          const RallySectionHeader(title: 'Lineup'),
          const SizedBox(height: AppSpacing.md),
          const RallyGlassPanel(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Player(initials: 'YA', name: 'You', level: '3.4'),
                _Player(initials: 'AR', name: 'Ahmed', level: '3.5'),
                _Player(initials: 'HK', name: 'Hassan', level: '3.3'),
                _Player(initials: 'SM', name: 'Sara', level: '3.6'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const RallyGlassPanel(
            child: Column(
              children: [
                RallyInfoRow(
                  icon: Icons.schedule,
                  label: 'Time',
                  value: 'Thu · 8:30 PM',
                ),
                RallyInfoRow(
                  icon: Icons.sports_tennis,
                  label: 'Format',
                  value: '90 min · Competitive doubles',
                ),
                RallyInfoRow(
                  icon: Icons.payments_outlined,
                  label: 'Price split',
                  value: 'PKR 2,250 per player',
                ),
                RallyInfoRow(
                  icon: Icons.check_circle_outline,
                  label: 'Court status',
                  value: 'Court 03 reserved',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          RallyGlassPanel(
            onTap: () => context.push(AppRoutes.club),
            child: const RallyInfoRow(
              icon: Icons.location_on_outlined,
              label: 'Venue · tap for details',
              value: 'Rally Padel Club · DHA Phase 6',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const RallyGlassPanel(
            child: Text(
              'Rally AI · Balanced levels, complementary playing sides, and '
              'a 94% schedule fit make this a high-confidence match.',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            key: const Key('open-chat-button'),
            label: 'OPEN MATCH CHAT',
            icon: Icons.chat_bubble_outline,
            onPressed: () => context.push(AppRoutes.chat),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: () => _notice(context, 'Directions opened (demo)'),
                icon: const Icon(Icons.directions_outlined),
                label: const Text('Directions'),
              ),
              OutlinedButton.icon(
                onPressed: () => _notice(context, 'Added to calendar (demo)'),
                icon: const Icon(Icons.event_available_outlined),
                label: const Text('Add to calendar'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Free cancellation until 6:30 PM. Late cancellations may affect reliability.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class MatchChatScreen extends StatefulWidget {
  const MatchChatScreen({super.key});

  @override
  State<MatchChatScreen> createState() => _MatchChatScreenState();
}

class _MatchChatScreenState extends State<MatchChatScreen> {
  final _controller = TextEditingController();
  final List<String> _messages = [
    'Court 03 is booked. See you at 8:20!',
    'Perfect — I’ll bring balls.',
  ];

  void _send([String? quick]) {
    final text = (quick ?? _controller.text).trim();
    if (text.isEmpty) return;
    setState(() => _messages.add(text));
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Thursday Night Padel'),
            Text('4 players · 8:30 PM', style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Match details',
            onPressed: () => context.push(AppRoutes.matchDetails),
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: RallyContent(
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                key: const Key('chat-message-list'),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                itemCount: _messages.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) => Align(
                  alignment: index < 2
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: RallyGlassPanel(
                    child: Text(
                      '${_messages[index]}\n${index < 2 ? '8:04' : 'Now'}',
                    ),
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ActionChip(
                    label: const Text('I’m on my way'),
                    onPressed: () => _send('I’m on my way'),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  ActionChip(
                    label: const Text('Running 5 min late'),
                    onPressed: () => _send('Running 5 min late'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                IconButton(
                  tooltip: 'Attach (demo)',
                  onPressed: () =>
                      _notice(context, 'Attachments are demo-only'),
                  icon: const Icon(Icons.attach_file),
                ),
                Expanded(
                  child: TextField(
                    key: const Key('chat-input'),
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                      labelText: 'Message team',
                    ),
                  ),
                ),
                IconButton.filled(
                  key: const Key('send-message-button'),
                  tooltip: 'Send message',
                  onPressed: _send,
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PlayerProfileScreen extends StatelessWidget {
  const PlayerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _JourneyPage(
      eyebrow: 'PLAYER / VERIFIED',
      title: 'AHMED RAZA',
      showBack: true,
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.lg),
          const RallyAvatar(initials: 'AR', size: 112),
          const SizedBox(height: AppSpacing.md),
          const Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.xs,
            children: [
              RallyStatusChip(label: 'Level 3.5'),
              RallyStatusChip(label: 'Left side'),
              RallyStatusChip(label: '4.8 rating'),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const RallyGlassPanel(
            child: Column(
              children: [
                RallyInfoRow(
                  icon: Icons.shield,
                  label: 'Reliability',
                  value: '98% · Excellent',
                ),
                RallyInfoRow(
                  icon: Icons.sports_score,
                  label: 'Matches played',
                  value: '126',
                ),
                RallyInfoRow(
                  icon: Icons.emoji_events_outlined,
                  label: 'Achievements',
                  value: '20-match streak · Club finalist',
                ),
                RallyInfoRow(
                  icon: Icons.history,
                  label: 'Recent form',
                  value: 'W · W · L · W · W',
                ),
                RallyInfoRow(
                  icon: Icons.location_city,
                  label: 'Preferred clubs',
                  value: 'Rally Padel · Smash Arena',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextButton(
            onPressed: () => _notice(context, 'Safety actions opened'),
            child: const Text('Report or block player'),
          ),
        ],
      ),
    );
  }
}

class ClubDetailsScreen extends StatelessWidget {
  const ClubDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _JourneyPage(
      eyebrow: 'VENUE / 2.4 KM',
      title: 'RALLY PADEL CLUB',
      showBack: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFF17223C), Color(0xFF060816)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.sports_tennis,
                size: 72,
                semanticLabel: 'Padel court',
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const RallyGlassPanel(
            child: Column(
              children: [
                RallyInfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Location',
                  value: 'DHA Phase 6 · 2.4 km',
                ),
                RallyInfoRow(
                  icon: Icons.grid_view,
                  label: 'Courts',
                  value: '6 panoramic · 2 covered',
                ),
                RallyInfoRow(
                  icon: Icons.schedule,
                  label: 'Hours',
                  value: '6:00 AM – 12:00 AM',
                ),
                RallyInfoRow(
                  icon: Icons.payments_outlined,
                  label: 'Pricing',
                  value: 'From PKR 8,000 / 90 min',
                ),
                RallyInfoRow(
                  icon: Icons.local_cafe_outlined,
                  label: 'Amenities',
                  value: 'Parking · showers · café · pro shop',
                ),
                RallyInfoRow(
                  icon: Icons.groups_outlined,
                  label: 'Live',
                  value: '18 active players · 5 upcoming matches',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'FIND A MATCH HERE',
            onPressed: () => context.go(AppRoutes.searching),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () => _notice(context, 'Club contact opened (demo)'),
            icon: const Icon(Icons.call_outlined),
            label: const Text('Directions & contact'),
          ),
        ],
      ),
    );
  }
}

class _JourneyPage extends StatelessWidget {
  const _JourneyPage({
    required this.eyebrow,
    required this.title,
    required this.child,
    this.showBack = false,
  });

  final String eyebrow;
  final String title;
  final Widget child;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showBack ? AppBar() : null,
      body: SafeArea(
        child: SingleChildScrollView(
          child: RallyContent(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  eyebrow,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Player extends StatelessWidget {
  const _Player({
    required this.initials,
    required this.name,
    required this.level,
  });
  final String initials;
  final String name;
  final String level;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      RallyAvatar(initials: initials, size: 46),
      const SizedBox(height: AppSpacing.xs),
      Text(name, style: Theme.of(context).textTheme.labelLarge),
      Text(level, style: Theme.of(context).textTheme.labelSmall),
    ],
  );
}

void _notice(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}
