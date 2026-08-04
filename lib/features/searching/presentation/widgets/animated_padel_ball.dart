import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import 'radar_painter.dart';

class AnimatedPadelBall extends StatefulWidget {
  const AnimatedPadelBall({super.key});

  @override
  State<AnimatedPadelBall> createState() => _AnimatedPadelBallState();
}

class _AnimatedPadelBallState extends State<AnimatedPadelBall>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 0.35;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final phase = _controller.value * math.pi * 2;
          return Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: RadarPainter(
                      color: AppColors.electricGreen,
                      progress: _controller.value,
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(0, math.sin(phase) * AppSpacing.xs),
                child: Transform.rotate(
                  angle: math.sin(phase * 0.72) * 0.07,
                  child: child,
                ),
              ),
            ],
          );
        },
        child: const SizedBox.square(
          dimension: AppSpacing.xxxl * 1.36,
          child: CustomPaint(painter: _BallPainter()),
        ),
      ),
    );
  }
}

class _BallPainter extends CustomPainter {
  const _BallPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.34;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, size.height * 0.88),
        width: radius * 1.55,
        height: AppSpacing.sm,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.48)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, AppSpacing.sm),
    );

    final ballBounds = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.38, -0.46),
          radius: 0.92,
          colors: <Color>[
            Color(0xFFD9FF92),
            AppColors.electricGreen,
            Color(0xFF49A92A),
            Color(0xFF193713),
          ],
          stops: <double>[0, 0.28, 0.72, 1],
        ).createShader(ballBounds),
    );

    canvas.save();
    canvas.clipPath(Path()..addOval(ballBounds));
    final seamPaint = Paint()
      ..color = const Color(0xFFDFFFCF).withValues(alpha: 0.84)
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppSpacing.xxs
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawArc(
        Rect.fromCenter(
          center: Offset(center.dx - radius * 0.72, center.dy),
          width: radius * 1.3,
          height: radius * 2.5,
        ),
        -1.25,
        2.5,
        false,
        seamPaint,
      )
      ..drawArc(
        Rect.fromCenter(
          center: Offset(center.dx + radius * 0.72, center.dy),
          width: radius * 1.3,
          height: radius * 2.5,
        ),
        math.pi - 1.25,
        2.5,
        false,
        seamPaint,
      );
    canvas.restore();
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_BallPainter oldDelegate) => false;
}
