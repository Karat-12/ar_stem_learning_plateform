import 'assessment_challenge_result.dart';

class AssessmentResultModel {
  const AssessmentResultModel({
    required this.challengeResults,
    required this.totalScore,
    required this.passedChallenges,
  });

  final List<AssessmentChallengeResult> challengeResults;
  final int totalScore;
  final int passedChallenges;
}
