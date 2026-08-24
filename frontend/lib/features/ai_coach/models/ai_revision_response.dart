/// Parsed response from GET /api/v1/ai/revision-suggestions
class AiRevisionResponse {
  const AiRevisionResponse({
    required this.revisionTopics,
    required this.revisionActions,
    required this.estimatedRevisionTimeMinutes,
    required this.reason,
  });

  final List<String> revisionTopics;
  final List<String> revisionActions;
  final int estimatedRevisionTimeMinutes;
  final String reason;

  factory AiRevisionResponse.fromJson(Map<String, dynamic> json) {
    return AiRevisionResponse(
      revisionTopics: _strings(json['revisionTopics']),
      revisionActions: _strings(json['revisionActions']),
      estimatedRevisionTimeMinutes: int.tryParse(
              json['estimatedRevisionTimeMinutes']?.toString() ?? '') ??
          0,
      reason: json['reason']?.toString() ?? '',
    );
  }

  static List<String> _strings(dynamic raw) =>
      raw is List ? raw.map((e) => e.toString()).toList() : const [];

  static const empty = AiRevisionResponse(
    revisionTopics: [],
    revisionActions: [],
    estimatedRevisionTimeMinutes: 0,
    reason: '',
  );
}
