import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/session_response.dart';
import '../models/start_session_request.dart';

class SessionService {
  final ApiClient _apiClient;

  SessionService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<SessionResponse> startSession({
    required String domainCode,
    required String topicCode,
    required String activityCode,
  }) async {
    try {
      final request = StartSessionRequest(
        domainCode: domainCode,
        topicCode: topicCode,
        activityCode: activityCode,
      );

      final response = await _apiClient.post<Map<String, dynamic>>(
        path: '/api/v1/sessions/start',
        data: request.toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      return SessionResponse.fromJson(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to start session: ${e.toString()}',
        originalError: e,
      );
    }
  }

  Future<SessionResponse> endSession(String sessionId) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        path: '/api/v1/sessions/$sessionId/end',
        data: {},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      return SessionResponse.fromJson(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to end session: ${e.toString()}',
        originalError: e,
      );
    }
  }
}
