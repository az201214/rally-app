import 'package:flutter/material.dart';

import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_radius.dart';
import '../../../../../theme/app_spacing.dart';

class RallyHomeHeader extends StatelessWidget {
  const RallyHomeHeader({super.key});

  void _showNotificationMessage(BuildContext context) {
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
              'NOTIFICATIONS',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppColors.accentTertiary,
                child: Icon(
                  Icons.sports_tennis_rounded,
                  color: AppColors.textPrimary,
                ),
              ),
              title: Text('Match confirmed'),
              subtitle: Text('Today at 7:30 PM · Padelverse Clifton'),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppColors.surfaceSecondary,
                child: Icon(Icons.group_outlined),
              ),
              title: Text('Players are active nearby'),
              subtitle: Text('Eight compatible players are available tonight.'),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('DONE'),
              ),
            ),
          ],
        ),
      ),
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
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'YOUR PADEL COMMAND CENTER',
                style: theme.textTheme.labelSmall,
              ),
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
