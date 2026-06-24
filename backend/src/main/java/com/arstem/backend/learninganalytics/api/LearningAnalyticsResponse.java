package com.arstem.backend.learninganalytics.api;

import java.util.List;

import com.arstem.backend.learninganalytics.domain.LearningAnalytics;

public record LearningAnalyticsResponse(String topicCode, int completedSessions, int misconceptionCount,
        int averageQuizScore, int masteryScore, String masteryLevel, List<String> weakAreas,
        boolean recommendedPractice) {

    public static LearningAnalyticsResponse from(LearningAnalytics a) {
        return new LearningAnalyticsResponse(a.getTopicCode(), a.getCompletedSessions(), a.getMisconceptionCount(),
                a.getAverageQuizScore(), a.getMasteryScore(), a.getMasteryLevel(), a.getWeakAreas(),
                a.isRecommendedPractice());
    }
}
