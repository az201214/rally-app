import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';

/// Carbon court atmosphere with restrained stadium light and vignette.
class CourtBackground extends StatelessWidget {
  const CourtBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: const _CourtPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _CourtPainter extends CustomPainter {
  const _CourtPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF141A17),
            AppColors.carbonBlack,
            Color(0xFF07080A),
          ],
          stops: <double>[0, 0.42, 1],
        ).createShader(bounds),
    );

    canvas.drawRect(
      bounds,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -1.15),
          radius: 1.05,
          colors: <Color>[
            AppColors.electricGreen.withValues(alpha: 0.10),
            Colors.transparent,
          ],
        ).createShader(bounds),
    );

    final court = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.54),
      width: size.width * 0.78,
      height: size.height * 0.72,
    );
    final linePaint = Paint()
      ..color = AppColors.electricGreen.withValues(alpha: 0.055)
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppSpacing.xxs / 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, AppSpacing.xxs);
    canvas
      ..drawRect(court, linePaint)
      ..drawLine(
        Offset(court.left, court.center.dy),
        Offset(court.right, court.center.dy),
        linePaint,
      )
      ..drawLine(
        Offset(court.center.dx, court.top),
        Offset(court.center.dx, court.bottom),
        linePaint,
      );

    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const RadialGradient(
          radius: 0.82,
          colors: <Color>[Colors.transparent, Color(0xB8000000)],
          stops: <double>[0.5, 1],
        ).createShader(bounds),
    );
  }

  @override
  bool shouldRepaint(_CourtPainter oldDelegate) => false;
}
