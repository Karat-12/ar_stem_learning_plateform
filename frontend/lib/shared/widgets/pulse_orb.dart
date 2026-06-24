import 'package:flutter/material.dart';

class PulseOrb extends StatefulWidget {
  const PulseOrb({
    super.key,
    required this.color,
    required this.size,
    this.delay = 0,
  });

  final Color color;
  final double size;
  final int delay;

  @override
  State<PulseOrb> createState() => _PulseOrbState();
}

class _PulseOrbState extends State<PulseOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // Start each orb at a slightly different point so the pulses feel layered.
    _controller.value = (widget.delay % 2200) / 2200;
    _controller.repeat(reverse: true);
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
        final pulse = 0.9 + (_controller.value * 0.18);

        return Transform.scale(
          scale: pulse,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: widget.color.withValues(alpha: 0.42)),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.24),
                  blurRadius: 34,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
