import 'ai_insights_response.dart';
import 'ai_recommendation_response.dart';
import 'ai_revision_response.dart';
import 'ai_study_plan_response.dart';
import 'analytics_topic_response.dart';

/// Composed model assembled from five parallel topic-scoped API calls by
/// [AiCoachService].
///
/// Every field in this model belongs exclusively to [topicCode].
/// No cross-topic data is stored here — if the user is reviewing
/// DSA_LINKED_LIST, Binary Tree and Chemistry data will never appear.
///
/// The screen only reads this — it never touches the individual response
/// objects directly.
class AiCoachReport {
  const AiCoachReport({
    required this.topicCode,
    required this.insights,
    required this.topicRecommendation,
    required this.revision,
    required this.studyPlan,
    required this.analytics,
  });

  /// The topic this report was generated for (e.g. 'DSA_LINKED_LIST').
  final String topicCode;

  /// Topic-scoped strengths/weaknesses/summary from
  /// GET /api/v1/ai/insights/{topicCode}.
  final AiInsightsResponse insights;

  /// The single recommendation for [topicCode] from
  /// GET /api/v1/ai/recommendations/{topicCode}.
  /// Null when the backend returned no recommendation for this topic.
  final AiRecommendationResponse? topicRecommendation;

  /// Topic-scoped revision suggestions from
  /// GET /api/v1/ai/revision-suggestions/{topicCode}.
  final AiRevisionResponse revision;

  /// Topic-scoped study plan from
  /// GET /api/v1/ai/study-plan/{topicCode}.
  final AiStudyPlanResponse studyPlan;

  /// Per-topic analytics from
  /// GET /api/v1/analytics/topic/{topicCode}.
  final AnalyticsTopicResponse analytics;

  // ── Convenience getters used directly by the screen ──────────────────────

  /// Overall performance narrative shown at the top of the coach screen.
  /// Uses the topic-scoped insights summary when available; falls back to a
  /// mastery-based sentence derived from the topic analytics so the text is
  /// always about this topic — never about Binary Tree, Stack, or Chemistry.
  String get overallSummary {
    if (insights.summary.isNotEmpty) return insights.summary;
    // Fallback: derive a simple narrative from the analytics mastery score.
    if (analytics.masteryScore == 0 && analytics.completedSessions == 0) {
      return 'Complete an assessment to generate a personalised performance summary.';
    }
    if (analytics.masteryScore >= 80) {
      return 'You are showing strong mastery of this topic. '
          'Keep up the excellent work!';
    }
    if (analytics.masteryScore >= 50) {
      return 'You are making good progress. '
          'Reviewing the revision actions below will help push your mastery higher.';
    }
    return 'This topic needs more practice. '
        'Revisit the learning workspace and retry the assessment when you feel ready.';
  }

  /// Mastery score 0–100.
  int get masteryScore => analytics.masteryScore;

  /// BEGINNER | INTERMEDIATE | ADVANCED
  String get masteryLevel => analytics.masteryLevel;

  /// True when the AI recommends additional practice for this topic.
  bool get practiceRecommended => analytics.recommendedPractice;

  /// Misconception codes recorded for this topic.
  List<String> get misconceptionCodes => analytics.weakAreas;

  /// Whether there are any actionable revision tasks for this topic.
  bool get hasRevisionActions => revision.revisionActions.isNotEmpty;
}
