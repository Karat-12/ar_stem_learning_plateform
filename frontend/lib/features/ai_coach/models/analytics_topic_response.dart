/// Parsed response from GET /api/v1/analytics/topic/{topicCode}
///
/// This model is intentionally separate from [ProgressResponse] —
/// the analytics endpoint returns additional fields (averageQuizScore,
/// masteryLevel, recommendedPractice) that the progress endpoint does not.
/// [ProgressResponse] is still used wherever only progress data is needed;
/// this model is used only inside the AI Coach feature.
class AnalyticsTopicResponse {
  const AnalyticsTopicResponse({
    required this.topicCode,
    required this.completedSessions,
    required this.misconceptionCount,
    required this.averageQuizScore,
    required this.masteryScore,
    required this.masteryLevel,
    required this.weakAreas,
    required this.recommendedPractice,
  });

  final String topicCode;
  final int completedSessions;
  final int misconceptionCount;
  final int averageQuizScore;
  final int masteryScore;

  /// BEGINNER | INTERMEDIATE | ADVANCED
  final String masteryLevel;
  final List<String> weakAreas;
  final bool recommendedPractice;

  factory AnalyticsTopicResponse.fromJson(Map<String, dynamic> json) {
    return AnalyticsTopicResponse(
      topicCode: json['topicCode']?.toString() ?? '',
      completedSessions:
          int.tryParse(json['completedSessions']?.toString() ?? '') ?? 0,
      misconceptionCount:
          int.tryParse(json['misconceptionCount']?.toString() ?? '') ?? 0,
      averageQuizScore:
          int.tryParse(json['averageQuizScore']?.toString() ?? '') ?? 0,
      masteryScore:
          int.tryParse(json['masteryScore']?.toString() ?? '') ?? 0,
      masteryLevel: json['masteryLevel']?.toString() ?? 'BEGINNER',
      weakAreas: json['weakAreas'] is List
          ? (json['weakAreas'] as List).map((e) => e.toString()).toList()
          : const [],
      recommendedPractice: json['recommendedPractice'] == true,
    );
  }

  /// Empty placeholder used before data loads or when topic has no analytics.
  static const empty = AnalyticsTopicResponse(
    topicCode: '',
    completedSessions: 0,
    misconceptionCount: 0,
    averageQuizScore: 0,
    masteryScore: 0,
    masteryLevel: 'BEGINNER',
    weakAreas: [],
    recommendedPractice: false,
  );
}
