import 'dart:async';

import 'package:flutter/material.dart';

class SearchStatus extends StatefulWidget {
  const SearchStatus({super.key});

  @override
  State<SearchStatus> createState() => _SearchStatusState();
}

class _SearchStatusState extends State<SearchStatus> {
  static const _messages = <String>[
    'Finding nearby players...',
    'Checking availability...',
    'Comparing skill levels...',
    'Looking for the best match...',
  ];

  Timer? _timer;
  int _index = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timer?.cancel();
    if (!MediaQuery.disableAnimationsOf(context)) {
      _timer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
        if (mounted) {
          setState(() => _index = (_index + 1) % _messages.length);
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      label: _messages[_index],
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 420),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: Text(
          _messages[_index],
          key: ValueKey<int>(_index),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
          ),
        ),
      ),
    );
  }
}
