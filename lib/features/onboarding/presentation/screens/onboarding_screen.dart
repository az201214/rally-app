import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/app_routes.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_spacing.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.carbonBlack,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const _OnboardingVisual(),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'YOUR NEXT MATCH\nSTARTS HERE',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      height: 0.98,
                      letterSpacing: -1.8,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Rally finds compatible padel players nearby—matched by '
                    'level, availability, side, and reliability.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: <Widget>[
                      _Benefit(
                        icon: Icons.speed_rounded,
                        label: 'Under 30 sec',
                      ),
                      _Benefit(
                        icon: Icons.tune_rounded,
                        label: 'Smart matching',
                      ),
                      _Benefit(
                        icon: Icons.place_rounded,
                        label: 'Karachi clubs',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    height: 58,
                    child: FilledButton(
                      key: const Key('onboarding-continue-button'),
                      onPressed: () => context.go(AppRoutes.login),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text('LET’S RALLY'),
                          SizedBox(width: AppSpacing.xs),
                          Icon(Icons.arrow_forward_rounded),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingVisual extends StatelessWidget {
  const _OnboardingVisual();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.25,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.xLarge,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF163126), Color(0xFF0B1320)],
          ),
          border: Border.all(
            color: AppColors.electricGreen.withValues(alpha: 0.2),
          ),
        ),
        child: const Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Positioned.fill(child: CustomPaint(painter: _PadelCourtPainter())),
            _RadarMarker(alignment: Alignment(-0.55, -0.3), label: 'AK'),
            _RadarMarker(alignment: Alignment(0.5, -0.46), label: 'HK'),
            _RadarMarker(alignment: Alignment(0.25, 0.5), label: 'SM'),
            Icon(
              Icons.sports_tennis_rounded,
              size: 48,
              color: AppColors.electricGreen,
            ),
          ],
        ),
      ),
    );
  }
}

class _RadarMarker extends StatelessWidget {
  const _RadarMarker({required this.alignment, required this.label});

  final Alignment alignment;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surfaceElevated,
          border: Border.all(color: AppColors.electricGreen),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: AppRadius.pillRadius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: AppColors.electricGreen),
          const SizedBox(width: AppSpacing.xxs),
          Text(label),
        ],
      ),
    );
  }
}

class _PadelCourtPainter extends CustomPainter {
  const _PadelCourtPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.electricGreen.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final rect = Rect.fromLTWH(
      size.width * 0.16,
      size.height * 0.1,
      size.width * 0.68,
      size.height * 0.8,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(AppRadius.md)),
      paint,
    );
    canvas.drawLine(
      Offset(rect.center.dx, rect.top),
      Offset(rect.center.dx, rect.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.center.dy),
      Offset(rect.right, rect.center.dy),
      paint,
    );
    canvas.drawCircle(rect.center, size.shortestSide * 0.3, paint);
  }

  @override
  bool shouldRepaint(_PadelCourtPainter oldDelegate) => false;
}
