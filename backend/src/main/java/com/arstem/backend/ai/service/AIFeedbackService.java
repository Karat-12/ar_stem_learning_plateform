package com.arstem.backend.ai.service;

import java.util.ArrayList;
import java.util.List;
import java.util.TreeSet;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;

import com.arstem.backend.ai.domain.FeedbackResponse;
import com.arstem.backend.common.exception.UnauthorizedException;
import com.arstem.backend.learninganalytics.domain.LearningAnalytics;
import com.arstem.backend.learninganalytics.repository.LearningAnalyticsRepository;
import com.arstem.backend.misconception.repository.MisconceptionRepository;
import com.arstem.backend.user.domain.User;
import com.arstem.backend.user.service.UserService;

@Service
public class AIFeedbackService {

    private final LearningAnalyticsRepository analyticsRepository;
    private final MisconceptionRepository misconceptionRepository;
    private final UserService userService;

    public AIFeedbackService(LearningAnalyticsRepository analyticsRepository,
            MisconceptionRepository misconceptionRepository,
            UserService userService) {
        this.analyticsRepository = analyticsRepository;
        this.misconceptionRepository = misconceptionRepository;
        this.userService = userService;
    }

    public FeedbackResponse getFeedback(String authenticatedEmail) {
        User user = userService.findByEmail(authenticatedEmail)
                .orElseThrow(() -> new UnauthorizedException("Authenticated user no longer exists."));
        String userId = user.getId();

        List<LearningAnalytics> analytics = analyticsRepository.findByUserId(userId);
        List<String> feedback = new ArrayList<>();

        var misconceptionsByTopic = misconceptionRepository.findByUserIdOrderByCreatedAtDesc(userId).stream()
                .collect(Collectors.groupingBy(m -> m.getTopicCode(), Collectors.counting()));

        for (LearningAnalytics analyticsEntry : analytics) {
            String topicCode = analyticsEntry.getTopicCode();
            int masteryScore = analyticsEntry.getMasteryScore();
            int averageQuizScore = analyticsEntry.getAverageQuizScore();
            long misconceptionCount = misconceptionsByTopic.getOrDefault(topicCode, 0L);

            if (masteryScore >= 80) {
                feedback.add("You are performing strongly in " + topicCode + ".");
            }
            if (masteryScore < 50) {
                feedback.add("Your mastery score for " + topicCode + " is below target.");
            }
            if (misconceptionCount > 3) {
                feedback.add("You encountered multiple misconceptions in " + topicCode + ".");
            }
            if (averageQuizScore < 60) {
                feedback.add("Your quiz performance in " + topicCode + " needs improvement.");
            }
        }

        if (feedback.isEmpty()) {
            feedback.add("Keep learning. More activity is needed to generate personalized feedback.");
        }

        return new FeedbackResponse(feedback);
    }
}
