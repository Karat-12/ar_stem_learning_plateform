import 'package:flutter_test/flutter_test.dart';
import 'package:ar_stem_learning_prototype/features/sessions/models/session_response.dart';
import 'package:ar_stem_learning_prototype/features/sessions/models/start_session_request.dart';

void main() {
  test('StartSessionRequest serializes workspace codes', () {
    final request = StartSessionRequest(
      domainCode: 'data-structures',
      topicCode: 'linked-list',
      activityCode: 'workspace',
    );

    expect(request.toJson(), {
      'domainCode': 'data-structures',
      'topicCode': 'linked-list',
      'activityCode': 'workspace',
    });
  });

  test('SessionResponse parses backend payload', () {
    final session = SessionResponse.fromJson({
      'id': 'session-1',
      'userId': 'user-1',
      'domainCode': 'data-structures',
      'topicCode': 'linked-list',
      'activityCode': 'workspace',
      'status': 'ACTIVE',
      'startedAt': '2026-07-16T13:00:00Z',
      'endedAt': null,
    });

    expect(session.id, 'session-1');
    expect(session.domainCode, 'data-structures');
    expect(session.status, 'ACTIVE');
  });
}
