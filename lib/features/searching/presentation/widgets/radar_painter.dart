import 'package:flutter/material.dart';

import '../../../../theme/app_spacing.dart';

/// Paints three staggered, expanding radar rings.
class RadarPainter extends CustomPainter {
  const RadarPainter({required this.color, required this.progress});

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = size.shortestSide / 2 - AppSpacing.xs;

    for (var index = 0; index < 3; index++) {
      final phase = (progress + index / 3) % 1;
      final radius = maxRadius * (0.30 + phase * 0.70);
      final alpha = (1 - phase) * 0.42;
      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppSpacing.xxs / 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, AppSpacing.xxs);
      canvas.drawCircle(center, radius, paint);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withValues(alpha: alpha * 0.65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(RadarPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.progress != progress;
}
