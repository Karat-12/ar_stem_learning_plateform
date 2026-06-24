import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class FloatingParticles extends StatefulWidget {
  const FloatingParticles({super.key});

  @override
  State<FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<FloatingParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlePainter(progress: _controller.value),
        );
      },
    );
  }
}

class _ParticlePainter extends CustomPainter {
  const _ParticlePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [AppColors.cyan, AppColors.pink, AppColors.lime];

    for (var i = 0; i < 28; i++) {
      final wave = (progress + i * 0.037) % 1;
      final x = (math.sin(i * 12.2) * 0.5 + 0.5) * size.width;
      final y = size.height - (wave * size.height);
      final paint = Paint()
        ..color = colors[i % colors.length].withValues(
          alpha: 0.08 + wave * 0.16,
        );

      canvas.drawCircle(Offset(x, y), 1.8 + (i % 4), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
