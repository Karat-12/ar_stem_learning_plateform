import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/linked_list_node_model.dart';

class NeonLinkedListNode extends StatelessWidget {
  const NeonLinkedListNode({
    super.key,
    required this.node,
    required this.isHead,
    required this.isActive,
  });

  final LinkedListNodeModel node;
  final bool isHead;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final accent = isActive ? AppColors.lime : AppColors.cyan;

    return AnimatedScale(
      duration: const Duration(milliseconds: 220),
      scale: isActive ? 1.1 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 106,
        height: 76,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xF0121834),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: (isHead ? AppColors.lime : accent).withValues(alpha: 0.72),
            width: isHead ? 2.2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: isActive ? 0.54 : 0.26),
              blurRadius: isActive ? 36 : 22,
              spreadRadius: isActive ? 2 : 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accent.withValues(alpha: 0.26)),
                ),
                child: Center(
                  child: Text(
                    node.label,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 7),
            Container(
              width: 28,
              decoration: BoxDecoration(
                color: AppColors.violet.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: AppColors.violet.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.violet,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
