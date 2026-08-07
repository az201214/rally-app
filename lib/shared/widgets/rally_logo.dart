import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Rally wordmark with a court-line signature that remains crisp at any scale.
class RallyLogo extends StatelessWidget {
  const RallyLogo({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      image: true,
      label: 'Rally',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CustomPaint(
              size: Size(compact ? 24 : 32, compact ? 24 : 32),
              painter: const _RallyMarkPainter(),
            ),
            SizedBox(width: compact ? AppSpacing.xs : AppSpacing.sm),
            Text(
              'RALLY',
              style:
                  (compact
                          ? theme.textTheme.titleLarge
                          : theme.textTheme.headlineMedium)
                      ?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.2,
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RallyMarkPainter extends CustomPainter {
  const _RallyMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = AppColors.accentPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.075
      ..strokeCap = StrokeCap.round;
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.width * 0.2),
    );
    canvas.drawRRect(rect.deflate(line.strokeWidth / 2), line);
    canvas.drawLine(
      Offset(size.width * 0.5, line.strokeWidth),
      Offset(size.width * 0.5, size.height - line.strokeWidth),
      line,
    );
    canvas.drawLine(
      Offset(line.strokeWidth, size.height * 0.56),
      Offset(size.width - line.strokeWidth, size.height * 0.56),
      line,
    );
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.32),
      size.width * 0.075,
      Paint()..color = AppColors.textPrimary,
    );
  }

  @override
  bool shouldRepaint(_RallyMarkPainter oldDelegate) => false;
}
