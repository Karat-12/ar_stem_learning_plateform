/// Request model for starting a learning session
class StartSessionRequest {
  final String domainCode;
  final String topicCode;
  final String activityCode;

  StartSessionRequest({
    required this.domainCode,
    required this.topicCode,
    required this.activityCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'domainCode': domainCode,
      'topicCode': topicCode,
      'activityCode': activityCode,
    };
  }
}
