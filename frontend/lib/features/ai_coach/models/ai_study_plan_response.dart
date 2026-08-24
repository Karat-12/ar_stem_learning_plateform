/// Parsed response from GET /api/v1/ai/study-plan
class AiStudyPlanResponse {
  const AiStudyPlanResponse({
    required this.todayTasks,
    required this.estimatedTimeMinutes,
    required this.priorityLevel,
    required this.reason,
  });

  final List<String> todayTasks;
  final int estimatedTimeMinutes;

  /// One of: HIGH | MEDIUM | LOW
  final String priorityLevel;
  final String reason;

  factory AiStudyPlanResponse.fromJson(Map<String, dynamic> json) {
    return AiStudyPlanResponse(
      todayTasks: _strings(json['todayTasks']),
      estimatedTimeMinutes:
          int.tryParse(json['estimatedTimeMinutes']?.toString() ?? '') ?? 0,
      priorityLevel: json['priorityLevel']?.toString() ?? 'LOW',
      reason: json['reason']?.toString() ?? '',
    );
  }

  static List<String> _strings(dynamic raw) =>
      raw is List ? raw.map((e) => e.toString()).toList() : const [];

  static const empty = AiStudyPlanResponse(
    todayTasks: [],
    estimatedTimeMinutes: 0,
    priorityLevel: 'LOW',
    reason: '',
  );
}
