import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';

class HolographicExplanationPanel extends StatelessWidget {
  const HolographicExplanationPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final items = const [
      _ExplanationItem(
        title: 'What is a linked list?',
        body:
            'A linked list is a chain of nodes. Each node stores data and a link to the next node.',
      ),
      _ExplanationItem(
        title: 'How nodes connect',
        body:
            'A node points to the next node. That pointer creates the path through the list.',
      ),
      _ExplanationItem(
        title: 'Head pointer concept',
        body:
            'The head is the first node. Without it, the program does not know where the list starts.',
      ),
      _ExplanationItem(
        title: 'Traversal concept',
        body:
            'Traversal means visiting nodes one by one, starting from head and following each next link.',
      ),
    ];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Explanation Panel',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 14),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _AnimatedExplanationTile(item: item),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedExplanationTile extends StatelessWidget {
  const _AnimatedExplanationTile({required this.item});

  final _ExplanationItem item;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(18 * (1 - value), 0),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.055),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cyan.withValues(alpha: 0.16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.body,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExplanationItem {
  const _ExplanationItem({required this.title, required this.body});

  final String title;
  final String body;
}
