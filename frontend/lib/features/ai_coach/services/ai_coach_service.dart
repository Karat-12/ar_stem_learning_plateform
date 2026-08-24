import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/ai_coach_report.dart';
import '../models/ai_insights_response.dart';
import '../models/ai_recommendation_response.dart';
import '../models/ai_revision_response.dart';
import '../models/ai_study_plan_response.dart';
import '../models/analytics_topic_response.dart';

/// Fetches all AI Coach data in parallel and assembles it into [AiCoachReport].
///
/// Every request is scoped to [topicCode].  No cross-topic data is fetched or
/// returned — if the user opens the AI Coach for DSA_LINKED_LIST they will
/// never see Binary Tree, Stack, or Chemistry data.
///
/// This service has no state and no cache — caching lives in [AiCoachProvider].
class AiCoachService {
  AiCoachService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Fetches five topic-scoped endpoints concurrently and returns a composed
  /// [AiCoachReport].  All five paths include the [topicCode] segment.
  ///
  /// Throws [ApiException] on any network failure so the provider can surface
  /// the error cleanly.
  Future<AiCoachReport> fetchReport(String topicCode) async {
    try {
      final results = await Future.wait([
        _fetchInsightsForTopic(topicCode),
        _fetchRecommendationForTopic(topicCode),
        _fetchRevisionForTopic(topicCode),
        _fetchStudyPlanForTopic(topicCode),
        _fetchTopicAnalytics(topicCode),
      ]);

      final insights          = results[0] as AiInsightsResponse;
      final topicRecommendation = results[1] as AiRecommendationResponse?;
      final revision          = results[2] as AiRevisionResponse;
      final studyPlan         = results[3] as AiStudyPlanResponse;
      final analytics         = results[4] as AnalyticsTopicResponse;

      return AiCoachReport(
        topicCode: topicCode,
        insights: insights,
        topicRecommendation: topicRecommendation,
        revision: revision,
        studyPlan: studyPlan,
        analytics: analytics,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'AI Coach data could not be loaded: ${e.toString()}',
        originalError: e,
      );
    }
  }

  // ── Private fetch helpers — every path includes topicCode ─────────────────

  /// GET /api/v1/ai/insights/{topicCode}
  /// Returns strengths, weaknesses, and summary for this topic only.
  Future<AiInsightsResponse> _fetchInsightsForTopic(String topicCode) async {
    try {
      final json = await _apiClient.get<Map<String, dynamic>>(
        path: '/api/v1/ai/insights/$topicCode',
        fromJson: (data) => data as Map<String, dynamic>,
      );
      return AiInsightsResponse.fromJson(json);
    } on ApiException catch (e) {
      // 404 = no analytics for this topic yet — return empty rather than fail.
      if (e.statusCode == 404) return AiInsightsResponse.empty;
      rethrow;
    }
  }

  /// GET /api/v1/ai/recommendations/{topicCode}
  /// Returns a single recommendation for this topic, or null (HTTP 204).
  Future<AiRecommendationResponse?> _fetchRecommendationForTopic(
      String topicCode) async {
    try {
      final json = await _apiClient.get<Map<String, dynamic>?>(
        path: '/api/v1/ai/recommendations/$topicCode',
        fromJson: (data) =>
            data == null ? null : data as Map<String, dynamic>,
      );
      if (json == null) return null;
      return AiRecommendationResponse.fromJson(json);
    } on ApiException catch (e) {
      // 204 No Content is surfaced by Dio as a null body; 404 also means
      // no recommendation — return null gracefully in both cases.
      if (e.statusCode == 204 || e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// GET /api/v1/ai/revision-suggestions/{topicCode}
  Future<AiRevisionResponse> _fetchRevisionForTopic(String topicCode) async {
    final json = await _apiClient.get<Map<String, dynamic>>(
      path: '/api/v1/ai/revision-suggestions/$topicCode',
      fromJson: (data) => data as Map<String, dynamic>,
    );
    return AiRevisionResponse.fromJson(json);
  }

  /// GET /api/v1/ai/study-plan/{topicCode}
  Future<AiStudyPlanResponse> _fetchStudyPlanForTopic(
      String topicCode) async {
    final json = await _apiClient.get<Map<String, dynamic>>(
      path: '/api/v1/ai/study-plan/$topicCode',
      fromJson: (data) => data as Map<String, dynamic>,
    );
    return AiStudyPlanResponse.fromJson(json);
  }

  /// GET /api/v1/analytics/topic/{topicCode}
  Future<AnalyticsTopicResponse> _fetchTopicAnalytics(
      String topicCode) async {
    try {
      final json = await _apiClient.get<Map<String, dynamic>>(
        path: '/api/v1/analytics/topic/$topicCode',
        fromJson: (data) => data as Map<String, dynamic>,
      );
      return AnalyticsTopicResponse.fromJson(json);
    } on ApiException catch (e) {
      // 404 means no analytics recorded yet — return empty rather than fail.
      if (e.statusCode == 404) return AnalyticsTopicResponse.empty;
      rethrow;
    }
  }
}
