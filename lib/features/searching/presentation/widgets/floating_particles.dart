import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';

class FloatingParticles extends StatefulWidget {
  const FloatingParticles({super.key});

  @override
  State<FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<FloatingParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 0.4;
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
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => CustomPaint(
            painter: _ParticlesPainter(_controller.value),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _ParticlesPainter extends CustomPainter {
  const _ParticlesPainter(this.progress);

  final double progress;

  static const _particles = <Offset>[
    Offset(0.08, 0.20),
    Offset(0.18, 0.64),
    Offset(0.29, 0.35),
    Offset(0.39, 0.82),
    Offset(0.56, 0.17),
    Offset(0.66, 0.69),
    Offset(0.78, 0.39),
    Offset(0.90, 0.74),
    Offset(0.95, 0.25),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (var index = 0; index < _particles.length; index++) {
      final particle = _particles[index];
      final phase = progress * math.pi * 2 + index * 0.9;
      final position = Offset(
        particle.dx * size.width + math.sin(phase) * AppSpacing.xs,
        particle.dy * size.height + math.cos(phase * 0.7) * AppSpacing.md,
      );
      canvas.drawCircle(
        position,
        index.isEven ? 1.2 : 0.8,
        Paint()
          ..color = AppColors.electricGreen.withValues(
            alpha: index.isEven ? 0.18 : 0.10,
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlesPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
