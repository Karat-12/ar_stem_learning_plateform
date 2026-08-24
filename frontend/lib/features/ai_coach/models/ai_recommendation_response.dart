/// A single recommendation entry from GET /api/v1/ai/recommendations
class AiRecommendationResponse {
  const AiRecommendationResponse({
    required this.topicCode,
    required this.recommendationType,
    required this.reason,
  });

  final String topicCode;

  /// One of: PRACTICE | NEXT_TOPIC | REVISION | QUIZ_PRACTICE
  final String recommendationType;
  final String reason;

  factory AiRecommendationResponse.fromJson(Map<String, dynamic> json) {
    return AiRecommendationResponse(
      topicCode: json['topicCode']?.toString() ?? '',
      recommendationType: json['recommendationType']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
    );
  }
}
