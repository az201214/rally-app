import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/app_routes.dart';
import '../../../../shared/widgets/rally_logo.dart';
import '../../../../theme/app_spacing.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timer ??= Timer(
      MediaQuery.disableAnimationsOf(context)
          ? const Duration(milliseconds: 80)
          : const Duration(milliseconds: 1500),
      () {
        if (mounted) context.go(AppRoutes.onboarding);
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      body: Semantics(
        label: 'Rally. Never play alone.',
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _CourtPainter(Theme.of(context).colorScheme.primary),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: reduceMotion ? 1 : .88, end: 1),
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (_, value, child) =>
                      Transform.scale(scale: value, child: child),
                  child: const RallyLogo(),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'NEVER PLAY ALONE.',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(letterSpacing: 2.4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CourtPainter extends CustomPainter {
  const _CourtPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: .13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final rect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: size.width * .72,
      height: size.height * .64,
    );
    canvas.drawRect(rect, paint);
    canvas.drawLine(
      Offset(rect.left, rect.center.dy),
      Offset(rect.right, rect.center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(rect.center.dx, rect.top),
      Offset(rect.center.dx, rect.bottom),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CourtPainter oldDelegate) =>
      oldDelegate.color != color;
}
