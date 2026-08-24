import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class AssessmentProgressHeader extends StatelessWidget {
  const AssessmentProgressHeader({
    super.key,
    required this.currentIndex,
    required this.totalSteps,
    required this.title,
  });

  final int currentIndex;
  final int totalSteps;
  final String title;

  @override
  Widget build(BuildContext context) {
    final progress = ((currentIndex + 1) / totalSteps).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Linked List Assessment',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.cyan,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: progress,
          minHeight: 8,
          backgroundColor: AppColors.glass,
          color: AppColors.lime,
        ),
        const SizedBox(height: 8),
        Text(
          'Challenge ${currentIndex + 1} of $totalSteps',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
