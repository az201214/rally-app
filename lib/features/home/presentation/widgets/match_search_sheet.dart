import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../shared/widgets/primary_button.dart';
import '../../../../../theme/app_radius.dart';
import '../../../../../theme/app_spacing.dart';
import 'availability_selector.dart';
import 'trajectory_painter.dart';

class MatchSearchSheet extends StatefulWidget {
  const MatchSearchSheet({required this.availability, super.key});

  final AvailabilityOption availability;

  @override
  State<MatchSearchSheet> createState() => _MatchSearchSheetState();
}

class _MatchSearchSheetState extends State<MatchSearchSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _searchController;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  void _startSearching() {
    setState(() {
      _isSearching = true;
    });

    if (!MediaQuery.disableAnimationsOf(context)) {
      _searchController.repeat();
    }
  }

  void _cancel() {
    _searchController.stop();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
        child: _isSearching
            ? _SearchingContent(animation: _searchController, onCancel: _cancel)
            : _ConfirmationContent(
                availability: widget.availability,
                onStart: _startSearching,
                onAdjust: () => Navigator.of(context).pop(),
              ),
      ),
    );
  }
}

class _ConfirmationContent extends StatelessWidget {
  const _ConfirmationContent({
    required this.availability,
    required this.onStart,
    required this.onAdjust,
  });

  final AvailabilityOption availability;
  final VoidCallback onStart;
  final VoidCallback onAdjust;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SheetHandle(),
        const SizedBox(height: AppSpacing.lg),
        Text('READY TO SEARCH?', style: theme.textTheme.headlineMedium),
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
          child: TextButton(onPressed: onAdjust, child: const Text('ADJUST')),
        ),
      ],
    );
  }
}

class _SearchingContent extends StatelessWidget {
  const _SearchingContent({required this.animation, required this.onCancel});

  final Animation<double> animation;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      key: const Key('searching-state'),
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const _SheetHandle(),
        const SizedBox(height: AppSpacing.lg),
        SizedBox.square(
          dimension: AppSpacing.xxxl * 2,
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Transform.rotate(
                angle: animation.value * math.pi * 2,
                child: CustomPaint(
                  painter: _SearchRadarPainter(
                    color: theme.colorScheme.primary,
                    progress: animation.value,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'SEARCHING NEARBY',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Finding players who match your level…',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            key: const Key('cancel-search-button'),
            onPressed: onCancel,
            child: const Text('Cancel'),
          ),
        ),
      ],
    );
  }
}

class _SearchDetail extends StatelessWidget {
  const _SearchDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: theme.textTheme.labelMedium)),
          Text(value, style: theme.textTheme.titleMedium),
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

class _SearchRadarPainter extends CustomPainter {
  const _SearchRadarPainter({required this.color, required this.progress});

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - AppSpacing.xs;
    final ringPaint = Paint()
      ..color = color.withValues(alpha: 0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppSpacing.xxs / 2;

    canvas
      ..drawCircle(center, radius, ringPaint)
      ..drawCircle(center, radius * 0.66, ringPaint)
      ..drawCircle(center, radius * 0.32, ringPaint);

    canvas.drawLine(
      center,
      Offset(center.dx, center.dy - radius),
      Paint()
        ..color = color
        ..strokeWidth = AppSpacing.xxs / 2
        ..strokeCap = StrokeCap.round,
    );

    TrajectoryPainter(color: color, progress: progress).paint(canvas, size);
  }

  @override
  bool shouldRepaint(_SearchRadarPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.progress != progress;
  }
}
