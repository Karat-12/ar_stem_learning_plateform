import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Animated circular ring that shows the mastery score 0–100 with a
/// colour-coded arc and a central label for the mastery level string.
class MasteryScoreRing extends StatefulWidget {
  const MasteryScoreRing({
    super.key,
    required this.score,
    required this.masteryLevel,
    this.size = 140,
  });

  final int score;

  /// BEGINNER | INTERMEDIATE | ADVANCED
  final String masteryLevel;
  final double size;

  @override
  State<MasteryScoreRing> createState() => _MasteryScoreRingState();
}

class _MasteryScoreRingState extends State<MasteryScoreRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progress = Tween<double>(begin: 0, end: widget.score / 100)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _ringColor {
    final level = widget.masteryLevel.trim().toUpperCase();
    if (level == 'MASTERED' || level == 'ADVANCED' || widget.score >= 80) {
      return AppColors.lime;
    }
    if (level == 'PROFICIENT' || level == 'INTERMEDIATE' || widget.score >= 60) {
      return AppColors.cyan;
    }
    if (level == 'DEVELOPING' || widget.score >= 40) {
      return AppColors.orange;
    }
    return AppColors.pink; // BEGINNER
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, _) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _RingPainter(
              progress: _progress.value,
              ringColor: _ringColor,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(_progress.value * 100).round()}',
                    style: TextStyle(
                      color: _ringColor,
                      fontSize: widget.size * 0.24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    widget.masteryLevel,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress, required this.ringColor});

  final double progress;
  final Color ringColor;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (size.width - 14) / 2;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    // Track ring
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi,
      false,
      Paint()
        ..color = AppColors.glass
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );

    // Progress arc
    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = ringColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.ringColor != ringColor;
}
