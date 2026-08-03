import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/app_routes.dart';
import '../../../../demo/demo_mode.dart';
import '../../../../shared/widgets/rally_snackbar.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../matchmaking/application/matchmaking_controller.dart';
import '../../../matchmaking/domain/matchmaking_models.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_shadows.dart';
import '../../../../theme/app_spacing.dart';

class MatchFoundScreen extends ConsumerStatefulWidget {
  const MatchFoundScreen({this.allowPreviewData = false, super.key});

  final bool allowPreviewData;

  @override
  ConsumerState<MatchFoundScreen> createState() => _MatchFoundScreenState();
}

class _MatchFoundScreenState extends ConsumerState<MatchFoundScreen>
    with TickerProviderStateMixin {
  late final AnimationController _sequenceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2100),
  );
  late final AnimationController _ctaController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );

  late final Animation<double> _pulse = CurvedAnimation(
    parent: _sequenceController,
    curve: const Interval(0.12, 0.46, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _contentFade = CurvedAnimation(
    parent: _sequenceController,
    curve: const Interval(0.28, 0.58, curve: Curves.easeOut),
  );
  late final Animation<Offset> _cardRise =
      Tween<Offset>(begin: const Offset(0, 0.16), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _sequenceController,
          curve: const Interval(0.28, 0.68, curve: Curves.easeOutCubic),
        ),
      );
  late final Animation<double> _ring = Tween<double>(begin: 0, end: 0.96)
      .animate(
        CurvedAnimation(
          parent: _sequenceController,
          curve: const Interval(0.46, 0.86, curve: Curves.easeInOutCubic),
        ),
      );
  late final Animation<double> _detailsFade = CurvedAnimation(
    parent: _sequenceController,
    curve: const Interval(0.64, 0.92, curve: Curves.easeOut),
  );
  late final Animation<double> _ctaFade = CurvedAnimation(
    parent: _sequenceController,
    curve: const Interval(0.8, 1, curve: Curves.easeOut),
  );

  bool _sequenceStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (_sequenceStarted) {
      if (reducedMotion) {
        _sequenceController.value = 1;
        _ctaController
          ..stop()
          ..value = 0.5;
      } else if (_sequenceController.isCompleted &&
          !_ctaController.isCompleted) {
        _ctaController.forward();
      }
      return;
    }
    _sequenceStarted = true;

    if (reducedMotion) {
      _sequenceController.value = 1;
      _ctaController.value = 0.5;
      return;
    }

    _sequenceController.forward();
    Future<void>.delayed(const Duration(milliseconds: 620), () {
      if (mounted) HapticFeedback.lightImpact();
    });
    Future<void>.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) _ctaController.forward();
    });
  }

  @override
  void dispose() {
    _sequenceController.dispose();
    _ctaController.dispose();
    super.dispose();
  }

  Future<void> _acceptMatch() async {
    HapticFeedback.mediumImpact();
    if (ref.read(matchmakingControllerProvider).match == null) {
      context.push(AppRoutes.matchDetails);
      return;
    }
    final accepted = await ref
        .read(matchmakingControllerProvider.notifier)
        .accept();
    if (!mounted) return;
    if (accepted) {
      context.push(AppRoutes.matchDetails);
    } else {
      RallySnackbar.show(
        context,
        message:
            ref.read(matchmakingControllerProvider).message ??
            'This match could not be accepted.',
        icon: Icons.error_outline_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final matchmaking = ref.watch(matchmakingControllerProvider);
    final match = matchmaking.match;
    final userId = ref.watch(authStateProvider).value?.uid;
    final opponent = match?.participants
        .where((item) => item.userId != userId)
        .firstOrNull;
    final targetScore = (match?.compatibilityScore ?? 96) / 100;
    if (match == null && !DemoMode.enabled && !widget.allowPreviewData) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.home);
      });
      return const Scaffold(
        backgroundColor: AppColors.carbonBlack,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.carbonBlack,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _sequenceController,
                builder: (context, child) => CustomPaint(
                  painter: _RallyPulsePainter(
                    sequence: _sequenceController.value,
                    pulse: _pulse.value,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - AppSpacing.xl,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          _TopBar(onClose: () => context.go(AppRoutes.home)),
                          const SizedBox(height: AppSpacing.md),
                          FadeTransition(
                            opacity: _contentFade,
                            child: const _MatchFoundHeading(),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          FadeTransition(
                            opacity: _contentFade,
                            child: SlideTransition(
                              position: _cardRise,
                              child: RepaintBoundary(
                                child: AnimatedBuilder(
                                  animation: _ring,
                                  child: _PlayerCardContent(
                                    participant: opponent,
                                    clubName: match?.clubName,
                                  ),
                                  builder: (context, child) => _PlayerCard(
                                    compatibility:
                                        _ring.value * targetScore / .96,
                                    child: child!,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          FadeTransition(
                            opacity: _detailsFade,
                            child: _AiInsightCard(
                              reasons: match?.compatibilityReasons,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          FadeTransition(
                            opacity: _ctaFade,
                            child: _AcceptButton(
                              glow: _ctaController,
                              onPressed: _acceptMatch,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          FadeTransition(
                            opacity: _ctaFade,
                            child: TextButton(
                              onPressed: () async {
                                final declined = await ref
                                    .read(
                                      matchmakingControllerProvider.notifier,
                                    )
                                    .decline();
                                if (context.mounted && declined) {
                                  context.go(AppRoutes.home);
                                }
                              },
                              child: const Text('DECLINE MATCH'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.electricGreen,
            boxShadow: AppShadows.glow,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          'RALLY PULSE',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
          ),
        ),
        const Spacer(),
        IconButton.filledTonal(
          onPressed: onClose,
          tooltip: 'Close match',
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }
}

class _MatchFoundHeading extends StatelessWidget {
  const _MatchFoundHeading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.electricGreen.withValues(alpha: 0.09),
            borderRadius: AppRadius.pillRadius,
            border: Border.all(
              color: AppColors.electricGreen.withValues(alpha: 0.28),
            ),
          ),
          child: const Text(
            'FOUND IN 7 SECONDS',
            style: TextStyle(
              color: AppColors.electricGreen,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'YOUR RALLY\nIS READY',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w900,
            height: 0.94,
            letterSpacing: -2,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'A high-confidence partner is ready to play nearby.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({required this.compatibility, required this.child});

  final double compatibility;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: AppRadius.xLarge,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.09),
            AppColors.surfaceElevated.withValues(alpha: 0.96),
            AppColors.surfaceSecondary,
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: <BoxShadow>[
          ...AppShadows.card,
          BoxShadow(
            color: AppColors.electricGreen.withValues(alpha: 0.1),
            blurRadius: 56,
            spreadRadius: -16,
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Stack(
            alignment: Alignment.center,
            children: <Widget>[
              SizedBox.square(
                dimension: 204,
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _CompatibilityRingPainter(progress: compatibility),
                  ),
                ),
              ),
              const _PlayerAvatar(),
              Positioned(bottom: 4, child: _ScorePill(progress: compatibility)),
              const Positioned(right: 19, bottom: 33, child: _VerifiedBadge()),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _PlayerAvatar extends StatelessWidget {
  const _PlayerAvatar();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Hamza Khan profile',
      child: Container(
        width: 150,
        height: 150,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF364942), Color(0xFF131C20)],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.16),
            width: 2,
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 30,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: Text(
          'HK',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: -2,
          ),
        ),
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.carbonBlack,
        borderRadius: AppRadius.pillRadius,
        border: Border.all(
          color: AppColors.electricGreen.withValues(alpha: 0.6),
        ),
      ),
      child: Text(
        '${(progress * 100).round()}% MATCH',
        key: const Key('compatibility-score'),
        style: const TextStyle(
          color: AppColors.electricGreen,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Verified player',
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.electricGreen,
          border: Border.all(color: AppColors.carbonBlack, width: 4),
        ),
        child: const Icon(
          Icons.check_rounded,
          color: AppColors.textInverse,
          size: 19,
        ),
      ),
    );
  }
}

class _PlayerCardContent extends StatelessWidget {
  const _PlayerCardContent({this.participant, this.clubName});

  final MatchParticipant? participant;
  final String? clubName;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          (participant?.displayName ?? 'HAMZA KHAN').toUpperCase(),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          '${participant?.skillLevel ?? 'Advanced'} · ${participant?.preferredSide ?? 'Right'}-side player',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            const _StatChip(
              icon: Icons.star_rounded,
              value: '4.9',
              label: 'RATING',
            ),
            _StatChip(
              icon: Icons.shield_rounded,
              value: '${(participant?.reliabilityScore ?? 92).round()}%',
              label: 'RELIABLE',
            ),
            const _StatChip(
              icon: Icons.near_me_rounded,
              value: '2.4 KM',
              label: 'AWAY',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) => Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: AppRadius.medium,
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.stadium_rounded,
                  size: 18,
                  color: AppColors.electricGreen,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    clubName ?? 'Padelverse Clifton',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (constraints.maxWidth > 250)
                  const Text(
                    'HOME CLUB',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
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
        borderRadius: AppRadius.medium,
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: AppColors.electricGreen),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _AiInsightCard extends StatelessWidget {
  const _AiInsightCard({this.reasons});

  final List<String>? reasons;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.electricGreen.withValues(alpha: 0.06),
        borderRadius: AppRadius.large,
        border: Border.all(
          color: AppColors.electricGreen.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.electricGreen.withValues(alpha: 0.12),
              borderRadius: AppRadius.medium,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.electricGreen,
              size: 19,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'WHY THIS MATCH WORKS',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.electricGreen,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  reasons == null || reasons!.isEmpty
                      ? 'Complementary court sides, similar skill, and matching availability.'
                      : reasons!.join(' · '),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary.withValues(alpha: 0.86),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AcceptButton extends StatelessWidget {
  const _AcceptButton({required this.glow, required this.onPressed});

  final Animation<double> glow;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glow,
      child: SizedBox(
        height: 60,
        child: FilledButton(
          key: const Key('accept-match-button'),
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.electricGreen,
            foregroundColor: AppColors.textInverse,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Flexible(
                child: Text(
                  'ACCEPT MATCH',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: AppSpacing.xs),
              Icon(Icons.arrow_forward_rounded),
            ],
          ),
        ),
      ),
      builder: (context, child) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.large,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.electricGreen.withValues(
                alpha: 0.12 + glow.value * 0.12,
              ),
              blurRadius: 18 + glow.value * 12,
              spreadRadius: -4,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _CompatibilityRingPainter extends CustomPainter {
  const _CompatibilityRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 9;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.07)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..shader = const SweepGradient(
          colors: <Color>[
            AppColors.electricGreen,
            Color(0xFFD8FF9F),
            AppColors.electricGreen,
          ],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_CompatibilityRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _RallyPulsePainter extends CustomPainter {
  const _RallyPulsePainter({required this.sequence, required this.pulse});

  final double sequence;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF07120D),
            AppColors.carbonBlack,
            Color(0xFF060816),
          ],
        ).createShader(Offset.zero & size),
    );

    final center = Offset(size.width / 2, size.height * 0.34);
    final maxRadius = math.max(size.width, size.height) * 0.62;
    final pulseOpacity = math.sin(pulse * math.pi) * 0.2;
    if (pulseOpacity > 0) {
      canvas.drawCircle(
        center,
        maxRadius * pulse,
        Paint()
          ..color = AppColors.electricGreen.withValues(alpha: pulseOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    final radarOpacity = (1 - sequence * 1.35).clamp(0.0, 0.13);
    final radarPaint = Paint()
      ..color = AppColors.electricGreen.withValues(alpha: radarOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      canvas.drawCircle(center, size.width * 0.15 * i, radarPaint);
    }

    final slowedRotation = (1 - math.pow(1 - sequence, 3)) * math.pi * 1.3;
    final sweepEnd =
        center +
        Offset.fromDirection(slowedRotation - math.pi / 2, size.width * 0.46);
    canvas.drawLine(center, sweepEnd, radarPaint);
  }

  @override
  bool shouldRepaint(_RallyPulsePainter oldDelegate) =>
      oldDelegate.sequence != sequence || oldDelegate.pulse != pulse;
}
