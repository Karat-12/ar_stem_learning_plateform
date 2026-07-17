/// Request model for recording a learner misconception.
class RecordMisconceptionRequest {
  final String sessionId;
  final String topicCode;
  final String misconceptionCode;
  final String misconceptionTitle;
  final String description;
  final String severity;

  RecordMisconceptionRequest({
    required this.sessionId,
    required this.topicCode,
    required this.misconceptionCode,
    required this.misconceptionTitle,
    required this.description,
    required this.severity,
  });

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'topicCode': topicCode,
      'misconceptionCode': misconceptionCode,
      'misconceptionTitle': misconceptionTitle,
      'description': description,
      'severity': severity,
    };
  }
}
