import '../../../core/config/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/record_misconception_request.dart';

class MisconceptionService {
  final ApiClient _apiClient;

  MisconceptionService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<void> recordMisconception(
    RecordMisconceptionRequest request,
  ) async {
    try {
      await _apiClient.post<dynamic>(
        path: ApiConstants.misconceptionsEndpoint,
        data: request.toJson(),
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to record misconception: ${e.toString()}',
        originalError: e,
      );
    }
  }
}
