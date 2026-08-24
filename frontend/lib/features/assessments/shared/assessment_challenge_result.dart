class AssessmentChallengeResult {
  const AssessmentChallengeResult({
    required this.passed,
    required this.score,
    required this.feedback,
  });

  final bool passed;
  final int score;
  final String feedback;
}
