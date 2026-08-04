import 'package:flutter/material.dart';

import '../../../../../theme/app_spacing.dart';

class TrajectoryPainter extends CustomPainter {
  const TrajectoryPainter({required this.color, this.progress = 1});

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..cubicTo(
        size.width * 0.24,
        size.height * 0.18,
        size.width * 0.68,
        size.height * 0.82,
        size.width,
        0,
      );
    final metric = path.computeMetrics().first;
    final visiblePath = metric.extractPath(0, metric.length * progress);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppSpacing.xxs / 2
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(visiblePath, paint);

    final tangent = metric.getTangentForOffset(metric.length * progress);
    if (tangent != null) {
      canvas.drawCircle(
        tangent.position,
        AppSpacing.xxs,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(TrajectoryPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.progress != progress;
  }
}
