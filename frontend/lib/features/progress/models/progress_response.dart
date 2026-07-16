/// Response model for progress endpoints
class ProgressResponse {
  final String topicCode;
  final int completedSessions;
  final int misconceptionCount;
  final int completionPercent;
  final int masteryScore;
  final List<String> weakAreas;

  ProgressResponse({
    required this.topicCode,
    required this.completedSessions,
    required this.misconceptionCount,
    required this.completionPercent,
    required this.masteryScore,
    required this.weakAreas,
  });

  factory ProgressResponse.fromJson(Map<String, dynamic> json) {
    final weakAreas = json['weakAreas'];

    return ProgressResponse(
      topicCode: json['topicCode']?.toString() ?? '',
      completedSessions:
          int.tryParse(json['completedSessions']?.toString() ?? '') ?? 0,
      misconceptionCount:
          int.tryParse(json['misconceptionCount']?.toString() ?? '') ?? 0,
      completionPercent:
          int.tryParse(json['completionPercent']?.toString() ?? '') ?? 0,
      masteryScore: int.tryParse(json['masteryScore']?.toString() ?? '') ?? 0,
      weakAreas: weakAreas is List
          ? weakAreas.map((item) => item.toString()).toList()
          : const [],
    );
  }
}
