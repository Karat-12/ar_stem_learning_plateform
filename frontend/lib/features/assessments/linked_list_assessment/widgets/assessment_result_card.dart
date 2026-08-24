import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../shared/assessment_challenge_result.dart';

class AssessmentResultCard extends StatelessWidget {
  const AssessmentResultCard({
    super.key,
    required this.results,
    required this.totalScore,
  });

  final List<AssessmentChallengeResult> results;
  final int totalScore;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assessment Complete',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          ...results.asMap().entries.map((entry) {
            final index = entry.key;
            final result = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(
                    result.passed ? Icons.check_circle : Icons.cancel,
                    color: result.passed ? AppColors.lime : AppColors.pink,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Challenge ${index + 1}: ${result.passed ? 'Pass' : 'Fail'}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          Text(
            'Final Score: $totalScore / 100',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.cyan,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
