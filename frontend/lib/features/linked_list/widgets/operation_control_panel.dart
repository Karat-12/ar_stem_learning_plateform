import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';

class OperationControlPanel extends StatelessWidget {
  const OperationControlPanel({
    super.key,
    required this.connectionBroken,
    required this.headMissing,
    required this.reverseTraversal,
    required this.onInsert,
    required this.onDelete,
    required this.onTraverse,
    required this.onToggleBrokenConnection,
    required this.onToggleHead,
    required this.onToggleTraversalOrder,
  });

  final bool connectionBroken;
  final bool headMissing;
  final bool reverseTraversal;
  final VoidCallback onInsert;
  final VoidCallback onDelete;
  final VoidCallback onTraverse;
  final VoidCallback onToggleBrokenConnection;
  final VoidCallback onToggleHead;
  final VoidCallback onToggleTraversalOrder;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Operation Simulator',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _NeonOperationButton(
                label: 'Insert Node',
                icon: Icons.add_circle_outline_rounded,
                color: AppColors.lime,
                onPressed: onInsert,
              ),
              _NeonOperationButton(
                label: 'Delete Tail',
                icon: Icons.remove_circle_outline_rounded,
                color: AppColors.orange,
                onPressed: onDelete,
              ),
              _NeonOperationButton(
                label: 'Traverse',
                icon: Icons.play_arrow_rounded,
                color: AppColors.cyan,
                onPressed: onTraverse,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _ToggleRow(
            label: 'Break one connection',
            value: connectionBroken,
            color: AppColors.pink,
            onChanged: onToggleBrokenConnection,
          ),
          _ToggleRow(
            label: 'Hide head pointer',
            value: headMissing,
            color: AppColors.orange,
            onChanged: onToggleHead,
          ),
          _ToggleRow(
            label: 'Reverse traversal order',
            value: reverseTraversal,
            color: AppColors.violet,
            onChanged: onToggleTraversalOrder,
          ),
        ],
      ),
    );
  }
}

class _NeonOperationButton extends StatelessWidget {
  const _NeonOperationButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.16),
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.38)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final Color color;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      value: value,
      activeThumbColor: color,
      activeTrackColor: color.withValues(alpha: 0.25),
      onChanged: (_) => onChanged(),
    );
  }
}
