import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/linked_list_node_model.dart';
import 'neon_linked_list_node.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public drag-data type
// ─────────────────────────────────────────────────────────────────────────────

/// Data carried by a [Draggable] from the palette to the playground.
///
/// The playground's [DragTarget] receives this and calls [onNodeDropped]
/// with the [nodeId] and the local [Offset] where the user released the drag.
class PaletteNodeDragData {
  const PaletteNodeDragData({required this.nodeId, required this.label});

  final int nodeId;
  final String label;
}

// ─────────────────────────────────────────────────────────────────────────────
// NodePalette widget
// ─────────────────────────────────────────────────────────────────────────────

/// Displays the nodes that have not yet been placed on the canvas.
///
/// Each chip is a [Draggable<PaletteNodeDragData>].  When the user drags a
/// chip and drops it on the playground [DragTarget], the playground calls
/// [onNodeDropped] with the node's ID and the drop [Offset].
///
/// The palette is purely presentational — it holds no logical state.
/// The screen decides which IDs appear here by passing [paletteNodeIds] and
/// the label lookup map [nodeLabels].
class NodePalette extends StatelessWidget {
  const NodePalette({
    super.key,
    required this.paletteNodeIds,
    required this.nodeLabels,
  });

  /// Node IDs that are still in the palette (not yet on the canvas).
  final List<int> paletteNodeIds;

  /// id → display label, e.g. {1: '10', 2: '20', 3: '30'}.
  final Map<int, String> nodeLabels;

  @override
  Widget build(BuildContext context) {
    if (paletteNodeIds.isEmpty) {
      return _EmptyPalette();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xC4080B1D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.drag_indicator_rounded,
                  color: AppColors.cyan, size: 15),
              const SizedBox(width: 6),
              Text(
                'Node Palette',
                style: TextStyle(
                  color: AppColors.cyan.withValues(alpha: 0.85),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Text(
                '${paletteNodeIds.length} remaining',
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Drag nodes onto the workspace →',
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),
          // Chips
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: paletteNodeIds.map((id) {
              final label = nodeLabels[id] ?? '$id';
              return _PaletteDraggableChip(
                nodeId: id,
                label: label,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PaletteDraggableChip
// ─────────────────────────────────────────────────────────────────────────────

class _PaletteDraggableChip extends StatelessWidget {
  const _PaletteDraggableChip({required this.nodeId, required this.label});

  final int nodeId;
  final String label;

  @override
  Widget build(BuildContext context) {
    final dragData = PaletteNodeDragData(nodeId: nodeId, label: label);

    // Build a full NeonLinkedListNode for the drag feedback.
    // The Offset here is purely cosmetic — it is only used by the drag
    // overlay renderer and is never read by the logical graph.
    final feedbackNode = LinkedListNodeModel(
      id: nodeId,
      label: label,
      position: Offset.zero,
    );

    return Draggable<PaletteNodeDragData>(
      data: dragData,
      // Visual while dragging (follows the finger/cursor)
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.9,
          child: NeonLinkedListNode(
            node: feedbackNode,
            isHead: false,
            isActive: true,
          ),
        ),
      ),
      // Visual left in the palette while dragging
      childWhenDragging: Opacity(
        opacity: 0.25,
        child: _PaletteChip(label: label),
      ),
      child: _PaletteChip(label: label),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PaletteChip  — static chip shown inside the palette
// ─────────────────────────────────────────────────────────────────────────────

class _PaletteChip extends StatelessWidget {
  const _PaletteChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xF0121834),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cyan.withValues(alpha: 0.55),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: 0.18),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'drag',
            style: TextStyle(
              color: AppColors.cyan.withValues(alpha: 0.55),
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EmptyPalette — shown when all nodes have been placed
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyPalette extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.lime.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.lime.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: AppColors.lime, size: 18),
          const SizedBox(width: 8),
          Text(
            'All nodes placed',
            style: TextStyle(
              color: AppColors.lime.withValues(alpha: 0.85),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
