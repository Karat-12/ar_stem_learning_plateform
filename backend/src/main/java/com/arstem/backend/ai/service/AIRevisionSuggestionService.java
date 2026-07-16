package com.arstem.backend.ai.service;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;

import com.arstem.backend.ai.domain.RevisionSuggestionResponse;
import com.arstem.backend.common.exception.UnauthorizedException;
import com.arstem.backend.learninganalytics.domain.LearningAnalytics;
import com.arstem.backend.learninganalytics.repository.LearningAnalyticsRepository;
import com.arstem.backend.misconception.domain.Misconception;
import com.arstem.backend.misconception.repository.MisconceptionRepository;
import com.arstem.backend.user.domain.User;
import com.arstem.backend.user.service.UserService;

@Service
public class AIRevisionSuggestionService {

    private final LearningAnalyticsRepository analyticsRepository;
    private final MisconceptionRepository misconceptionRepository;
    private final UserService userService;

    public AIRevisionSuggestionService(LearningAnalyticsRepository analyticsRepository,
            MisconceptionRepository misconceptionRepository,
            UserService userService) {
        this.analyticsRepository = analyticsRepository;
        this.misconceptionRepository = misconceptionRepository;
        this.userService = userService;
    }

    public RevisionSuggestionResponse getRevisionSuggestions(String authenticatedEmail) {
        User user = userService.findByEmail(authenticatedEmail)
                .orElseThrow(() -> new UnauthorizedException("Authenticated user no longer exists."));
        String userId = user.getId();

        List<LearningAnalytics> analytics = analyticsRepository.findByUserId(userId);
        Map<String, Long> misconceptionsByTopic = misconceptionRepository.findByUserIdOrderByCreatedAtDesc(userId).stream()
                .collect(Collectors.groupingBy(Misconception::getTopicCode, Collectors.counting()));

        List<String> revisionTopics = new ArrayList<>();
        List<String> revisionActions = new ArrayList<>();
        List<String> reasons = new ArrayList<>();

        for (LearningAnalytics analyticsEntry : analytics) {
            String topicCode = analyticsEntry.getTopicCode();
            int masteryScore = analyticsEntry.getMasteryScore();
            int averageQuizScore = analyticsEntry.getAverageQuizScore();
            long misconceptionCount = misconceptionsByTopic.getOrDefault(topicCode, 0L);

            boolean lowMastery = masteryScore < 50;
            boolean repeatedMisconceptions = misconceptionCount > 3;
            boolean lowQuiz = averageQuizScore < 60;

            if (lowMastery) {
                revisionTopics.add(topicCode);
            }

            if (repeatedMisconceptions) {
                revisionActions.add("Review misconceptions for " + topicCode);
            }

            if (lowQuiz) {
                revisionActions.add("Retake quiz for " + topicCode);
            }

            if (lowMastery || repeatedMisconceptions || lowQuiz) {
                reasons.add(generateReason(topicCode, lowMastery, repeatedMisconceptions, lowQuiz));
            }
        }

        int estimatedRevisionTimeMinutes = revisionTopics.size() * 20;
        String reason = String.join(" ", reasons).trim();

        return new RevisionSuggestionResponse(
                List.copyOf(revisionTopics),
                List.copyOf(revisionActions),
                estimatedRevisionTimeMinutes,
                reason.isEmpty() ? "No revision suggestions available." : reason);
    }

    private String generateReason(String topicCode, boolean lowMastery, boolean repeatedMisconceptions, boolean lowQuiz) {
        if (lowMastery && repeatedMisconceptions) {
            return topicCode + " requires revision because of repeated misconceptions and low mastery.";
        }
        if (lowMastery && lowQuiz) {
            return topicCode + " requires revision because of low mastery and quiz performance.";
        }
        if (repeatedMisconceptions) {
            return topicCode + " requires revision because repeated misconceptions were detected.";
        }
        if (lowMastery) {
            return topicCode + " requires revision because mastery is below target.";
        }
        if (lowQuiz) {
            return topicCode + " requires revision because quiz score is low.";
        }
        return topicCode + " requires revision.";
    }
}
