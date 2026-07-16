/// Response model for a learning session
class SessionResponse {
  final String id;
  final String userId;
  final String domainCode;
  final String topicCode;
  final String activityCode;
  final String status;
  final DateTime? startedAt;
  final DateTime? endedAt;

  SessionResponse({
    required this.id,
    required this.userId,
    required this.domainCode,
    required this.topicCode,
    required this.activityCode,
    required this.status,
    this.startedAt,
    this.endedAt,
  });

  factory SessionResponse.fromJson(Map<String, dynamic> json) {
    return SessionResponse(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      domainCode: json['domainCode']?.toString() ?? '',
      topicCode: json['topicCode']?.toString() ?? '',
      activityCode: json['activityCode']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'].toString())
          : null,
      endedAt: json['endedAt'] != null
          ? DateTime.tryParse(json['endedAt'].toString())
          : null,
    );
  }
}
