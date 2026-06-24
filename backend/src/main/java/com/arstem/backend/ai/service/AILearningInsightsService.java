package com.arstem.backend.ai.service;

import java.util.List;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;

import com.arstem.backend.ai.domain.LearningInsightsResponse;
import com.arstem.backend.common.exception.UnauthorizedException;
import com.arstem.backend.learninganalytics.domain.LearningAnalytics;
import com.arstem.backend.learninganalytics.repository.LearningAnalyticsRepository;
import com.arstem.backend.misconception.repository.MisconceptionRepository;
import com.arstem.backend.progress.repository.ProgressRepository;
import com.arstem.backend.user.domain.User;
import com.arstem.backend.user.service.UserService;

@Service
public class AILearningInsightsService {

    private final ProgressRepository progressRepository;
    private final LearningAnalyticsRepository analyticsRepository;
    private final MisconceptionRepository misconceptionRepository;
    private final UserService userService;

    public AILearningInsightsService(ProgressRepository progressRepository,
            LearningAnalyticsRepository analyticsRepository,
            MisconceptionRepository misconceptionRepository,
            UserService userService) {
        this.progressRepository = progressRepository;
        this.analyticsRepository = analyticsRepository;
        this.misconceptionRepository = misconceptionRepository;
        this.userService = userService;
    }

    public LearningInsightsResponse getLearningInsights(String authenticatedEmail) {
        User user = userService.findByEmail(authenticatedEmail)
                .orElseThrow(() -> new UnauthorizedException("Authenticated user no longer exists."));
        String userId = user.getId();

        List<LearningAnalytics> analytics = analyticsRepository.findByUserId(userId);
        List<String> strengths = analytics.stream()
                .filter(a -> a.getMasteryScore() >= 80)
                .map(LearningAnalytics::getTopicCode)
                .collect(Collectors.toList());
        List<String> weaknesses = analytics.stream()
                .filter(a -> a.getMasteryScore() < 50)
                .map(LearningAnalytics::getTopicCode)
                .collect(Collectors.toList());
        List<String> practiceTopics = analytics.stream()
                .filter(a -> a.getAverageQuizScore() < 60)
                .map(LearningAnalytics::getTopicCode)
                .collect(Collectors.toList());

        int totalTopicsLearned = (int) analytics.stream().map(LearningAnalytics::getTopicCode).distinct().count();
        double averageMasteryScore = analytics.isEmpty() ? 0.0
                : analytics.stream().mapToInt(LearningAnalytics::getMasteryScore).average().orElse(0.0);

        String summary = generateSummary(strengths, weaknesses);

        return new LearningInsightsResponse(strengths, weaknesses, practiceTopics, totalTopicsLearned, averageMasteryScore,
                summary);
    }

    private String generateSummary(List<String> strengths, List<String> weaknesses) {
        if (strengths.isEmpty() && weaknesses.isEmpty()) {
            return "No learning data available yet.";
        }
        if (!strengths.isEmpty() && weaknesses.isEmpty()) {
            return "You are showing strong performance across your completed topics.";
        }
        if (strengths.isEmpty() && !weaknesses.isEmpty()) {
            return "You should focus on improving your weaker topics.";
        }
        return String.format("You are performing strongly in %s but need more practice in %s.",
                String.join(", ", strengths), String.join(", ", weaknesses));
    }
}
