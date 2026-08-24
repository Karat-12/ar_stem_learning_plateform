import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/cyber_background.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../shared/assessment_challenge_result.dart';
import '../widgets/assessment_result_card.dart';

class LinkedListAssessmentResultScreen extends StatelessWidget {
  const LinkedListAssessmentResultScreen({super.key, required this.results});

  final List<AssessmentChallengeResult> results;

  @override
  Widget build(BuildContext context) {
    final totalScore = results.fold<int>(
      0,
      (sum, result) => sum + result.score,
    );

    return Scaffold(
      body: CyberBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            size: 72,
                            color: AppColors.lime,
                          ),
                          const SizedBox(height: 16),
                          AssessmentResultCard(
                            results: results,
                            totalScore: totalScore,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Return'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
