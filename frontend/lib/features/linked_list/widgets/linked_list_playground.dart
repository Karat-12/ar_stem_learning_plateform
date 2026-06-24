import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/linked_list_node_model.dart';
import 'neon_linked_list_node.dart';

class LinkedListPlayground extends StatelessWidget {
  const LinkedListPlayground({
    super.key,
    required this.nodes,
    required this.headNodeId,
    required this.connectionBroken,
    required this.activeTraversalId,
    required this.onMoveNode,
  });

  final List<LinkedListNodeModel> nodes;
  final int? headNodeId;
  final bool connectionBroken;
  final int? activeTraversalId;
  final void Function(int id, Offset position) onMoveNode;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = width < 620 ? 520.0 : 470.0;
        final ordered = [...nodes]
          ..sort((a, b) => a.position.dx.compareTo(b.position.dx));

        return ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: const Color(0xB3090D22),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppColors.cyan.withValues(alpha: 0.2)),
            ),
            child: Stack(
              children: [
                const Positioned.fill(child: _PlaygroundGrid()),
                Positioned.fill(
                  child: AnimatedArrowLayer(
                    nodes: ordered,
                    brokenConnection: connectionBroken,
                    activeTraversalId: activeTraversalId,
                  ),
                ),
                if (headNodeId != null)
                  _HeadPointer(
                    target: nodes.firstWhere(
                      (node) => node.id == headNodeId,
                      orElse: () => ordered.first,
                    ),
                  ),
                ...nodes.map(
                  (node) => Positioned(
                    left: node.position.dx.clamp(12, math.max(12, width - 118)),
                    top: node.position.dy.clamp(72, height - 108),
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        onMoveNode(node.id, node.position + details.delta);
                      },
                      child: NeonLinkedListNode(
                        node: node,
                        isHead: node.id == headNodeId,
                        isActive: node.id == activeTraversalId,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AnimatedArrowLayer extends StatefulWidget {
  const AnimatedArrowLayer({
    super.key,
    required this.nodes,
    required this.brokenConnection,
    required this.activeTraversalId,
  });

  final List<LinkedListNodeModel> nodes;
  final bool brokenConnection;
  final int? activeTraversalId;

  @override
  State<AnimatedArrowLayer> createState() => _AnimatedArrowLayerState();
}

class _AnimatedArrowLayerState extends State<AnimatedArrowLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
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
          painter: _ArrowPainter(
            nodes: widget.nodes,
            progress: _controller.value,
            brokenConnection: widget.brokenConnection,
            activeTraversalId: widget.activeTraversalId,
          ),
        );
      },
    );
  }
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter({
    required this.nodes,
    required this.progress,
    required this.brokenConnection,
    required this.activeTraversalId,
  });

  final List<LinkedListNodeModel> nodes;
  final double progress;
  final bool brokenConnection;
  final int? activeTraversalId;

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.length < 2) {
      return;
    }

    for (var i = 0; i < nodes.length - 1; i++) {
      if (brokenConnection && i == 1) {
        _drawBrokenLink(canvas, nodes[i], nodes[i + 1]);
        continue;
      }

      final start = nodes[i].position + const Offset(104, 38);
      final end = nodes[i + 1].position + const Offset(4, 38);
      final isActive = activeTraversalId == nodes[i].id;
      final paint = Paint()
        ..color = (isActive ? AppColors.lime : AppColors.cyan).withValues(
          alpha: 0.46,
        )
        ..strokeWidth = isActive ? 4 : 2.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(
          start.dx + 42,
          start.dy - 34,
          end.dx - 42,
          end.dy - 34,
          end.dx,
          end.dy,
        );
      canvas.drawPath(path, paint);

      final dot = Offset.lerp(start, end, progress)!;
      canvas.drawCircle(
        dot,
        4,
        Paint()..color = AppColors.lime.withValues(alpha: 0.82),
      );
      _drawArrowHead(canvas, start, end, paint.color);
    }
  }

  void _drawBrokenLink(
    Canvas canvas,
    LinkedListNodeModel from,
    LinkedListNodeModel to,
  ) {
    final start = from.position + const Offset(104, 38);
    final end = to.position + const Offset(4, 38);
    final paint = Paint()
      ..color = AppColors.pink.withValues(alpha: 0.65)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(start, Offset.lerp(start, end, 0.42)!, paint);
    canvas.drawLine(Offset.lerp(start, end, 0.58)!, end, paint);
    final center = Offset.lerp(start, end, 0.5)!;
    canvas.drawLine(
      center + const Offset(-10, -10),
      center + const Offset(10, 10),
      paint,
    );
    canvas.drawLine(
      center + const Offset(10, -10),
      center + const Offset(-10, 10),
      paint,
    );
  }

  void _drawArrowHead(Canvas canvas, Offset start, Offset end, Color color) {
    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    final p1 =
        end - Offset(math.cos(angle - 0.48) * 14, math.sin(angle - 0.48) * 14);
    final p2 =
        end - Offset(math.cos(angle + 0.48) * 14, math.sin(angle + 0.48) * 14);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(end, p1, paint);
    canvas.drawLine(end, p2, paint);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) {
    return oldDelegate.nodes != nodes ||
        oldDelegate.progress != progress ||
        oldDelegate.brokenConnection != brokenConnection ||
        oldDelegate.activeTraversalId != activeTraversalId;
  }
}

class _HeadPointer extends StatelessWidget {
  const _HeadPointer({required this.target});

  final LinkedListNodeModel target;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      left: target.position.dx + 10,
      top: target.position.dy - 58,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.lime.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.lime.withValues(alpha: 0.5)),
            ),
            child: const Text(
              'HEAD',
              style: TextStyle(
                color: AppColors.lime,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.lime),
        ],
      ),
    );
  }
}

class _PlaygroundGrid extends StatelessWidget {
  const _PlaygroundGrid();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _PlaygroundGridPainter());
  }
}

class _PlaygroundGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.cyan.withValues(alpha: 0.055)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 34) {
      canvas.drawLine(Offset(x, 0), Offset(x - 40, size.height), paint);
    }

    for (double y = 0; y < size.height; y += 34) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
