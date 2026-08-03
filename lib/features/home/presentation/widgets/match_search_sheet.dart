import 'package:flutter/material.dart';

import '../../../../../shared/widgets/primary_button.dart';
import '../../../../../theme/app_radius.dart';
import '../../../../../theme/app_spacing.dart';
import 'availability_selector.dart';

class MatchSearchSheet extends StatelessWidget {
  const MatchSearchSheet({
    required this.availability,
    required this.onStart,
    super.key,
  });

  final AvailabilityOption availability;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const _SheetHandle(),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'READY TO SEARCH?',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            _SearchDetail(label: 'AVAILABILITY', value: availability.label),
            const Divider(),
            const _SearchDetail(label: 'SKILL', value: 'Intermediate'),
            const Divider(),
            const _SearchDetail(label: 'RADIUS', value: '10 km'),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              key: const Key('start-searching-button'),
              label: 'START SEARCHING',
              icon: Icons.radar_rounded,
              onPressed: onStart,
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('ADJUST'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchDetail extends StatelessWidget {
  const _SearchDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outline,
          borderRadius: AppRadius.pillRadius,
        ),
        child: const SizedBox(width: AppSpacing.xxl, height: AppSpacing.xxs),
      ),
    );
  }
}
