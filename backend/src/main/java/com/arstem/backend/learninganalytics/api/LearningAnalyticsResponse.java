package com.arstem.backend.learninganalytics.api;

import java.util.List;

import com.arstem.backend.learninganalytics.domain.LearningAnalytics;

/**
 * API response for a single topic's learning analytics.
 *
 * <p>The {@code summary} field is additive — older frontend versions that
 * don't read it will simply ignore it without breaking.
 */
public record LearningAnalyticsResponse(
        String topicCode,
        int completedSessions,
        int misconceptionCount,
        int averageQuizScore,
        int masteryScore,
        String masteryLevel,
        List<String> weakAreas,
        boolean recommendedPractice,
        String summary) {

    public static LearningAnalyticsResponse from(LearningAnalytics a) {
        return new LearningAnalyticsResponse(
                a.getTopicCode(),
                a.getCompletedSessions(),
                a.getMisconceptionCount(),
                a.getAverageQuizScore(),
                a.getMasteryScore(),
                a.getMasteryLevel(),
                a.getWeakAreas(),
                a.isRecommendedPractice(),
                a.getSummary());
    }
}
