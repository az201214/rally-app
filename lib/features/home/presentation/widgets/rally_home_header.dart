import 'package:flutter/material.dart';

import '../../../../../theme/app_radius.dart';
import '../../../../../theme/app_spacing.dart';

class RallyHomeHeader extends StatelessWidget {
  const RallyHomeHeader({super.key});

  void _showNotificationMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You have new Rally updates.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'RALLY',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('GOOD EVENING', style: theme.textTheme.labelMedium),
            ],
          ),
        ),
        Semantics(
          label: 'Notifications, unread updates',
          button: true,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              IconButton(
                onPressed: () => _showNotificationMessage(context),
                tooltip: 'Notifications',
                icon: const Icon(Icons.notifications_none_rounded),
              ),
              Positioned(
                top: AppSpacing.xs,
                right: AppSpacing.xs,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: AppRadius.pillRadius,
                  ),
                  child: const SizedBox.square(dimension: AppSpacing.xs),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
