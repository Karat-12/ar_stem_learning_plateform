/// Parsed response from GET /api/v1/ai/insights
class AiInsightsResponse {
  const AiInsightsResponse({
    required this.strengths,
    required this.weaknesses,
    required this.topicsNeedingPractice,
    required this.totalTopicsLearned,
    required this.averageMasteryScore,
    required this.summary,
  });

  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> topicsNeedingPractice;
  final int totalTopicsLearned;
  final double averageMasteryScore;
  final String summary;

  factory AiInsightsResponse.fromJson(Map<String, dynamic> json) {
    return AiInsightsResponse(
      strengths: _strings(json['strengths']),
      weaknesses: _strings(json['weaknesses']),
      topicsNeedingPractice: _strings(json['topicsNeedingPractice']),
      totalTopicsLearned:
          int.tryParse(json['totalTopicsLearned']?.toString() ?? '') ?? 0,
      averageMasteryScore:
          double.tryParse(json['averageMasteryScore']?.toString() ?? '') ?? 0.0,
      summary: json['summary']?.toString() ?? '',
    );
  }

  static List<String> _strings(dynamic raw) =>
      raw is List ? raw.map((e) => e.toString()).toList() : const [];

  /// Empty placeholder used before data is loaded.
  static const empty = AiInsightsResponse(
    strengths: [],
    weaknesses: [],
    topicsNeedingPractice: [],
    totalTopicsLearned: 0,
    averageMasteryScore: 0,
    summary: '',
  );
}
