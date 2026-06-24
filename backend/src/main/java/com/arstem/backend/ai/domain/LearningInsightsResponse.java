package com.arstem.backend.ai.domain;

import java.util.List;

public record LearningInsightsResponse(
        List<String> strengths,
        List<String> weaknesses,
        List<String> topicsNeedingPractice,
        int totalTopicsLearned,
        double averageMasteryScore,
        String summary) {
}
