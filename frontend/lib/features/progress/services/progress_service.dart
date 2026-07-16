import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/progress_response.dart';

class ProgressService {
  final ApiClient _apiClient;

  ProgressService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<ProgressResponse>> getMyProgress() async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        path: '/api/v1/progress/me',
        fromJson: (json) => json as List<dynamic>,
      );

      return response
          .map(
            (item) => ProgressResponse.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to load progress: ${e.toString()}',
        originalError: e,
      );
    }
  }

  Future<ProgressResponse> getTopicProgress(String topicCode) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        path: '/api/v1/progress/topic/$topicCode',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      return ProgressResponse.fromJson(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to load topic progress: ${e.toString()}',
        originalError: e,
      );
    }
  }
}
