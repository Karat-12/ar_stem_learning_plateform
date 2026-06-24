package com.arstem.backend.ai.service;

import java.util.ArrayList;
import java.util.List;
import java.util.TreeSet;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;

import com.arstem.backend.ai.domain.RecommendationResponse;
import com.arstem.backend.ai.domain.RecommendationType;
import com.arstem.backend.common.exception.UnauthorizedException;
import com.arstem.backend.learninganalytics.domain.LearningAnalytics;
import com.arstem.backend.learninganalytics.repository.LearningAnalyticsRepository;
import com.arstem.backend.misconception.domain.Misconception;
import com.arstem.backend.misconception.repository.MisconceptionRepository;
import com.arstem.backend.progress.domain.Progress;
import com.arstem.backend.progress.repository.ProgressRepository;
import com.arstem.backend.user.domain.User;
import com.arstem.backend.user.service.UserService;

@Service
public class AIRecommendationService {

    private final ProgressRepository progressRepository;
    private final LearningAnalyticsRepository analyticsRepository;
    private final MisconceptionRepository misconceptionRepository;
    private final UserService userService;

    public AIRecommendationService(ProgressRepository progressRepository,
            LearningAnalyticsRepository analyticsRepository,
            MisconceptionRepository misconceptionRepository,
            UserService userService) {
        this.progressRepository = progressRepository;
        this.analyticsRepository = analyticsRepository;
        this.misconceptionRepository = misconceptionRepository;
        this.userService = userService;
    }

    public List<RecommendationResponse> getRecommendations(String authenticatedEmail) {
        User user = userService.findByEmail(authenticatedEmail)
                .orElseThrow(() -> new UnauthorizedException("Authenticated user no longer exists."));
        String userId = user.getId();

        List<Progress> progressRecords = progressRepository.findByUserId(userId);
        List<LearningAnalytics> analyticsRecords = analyticsRepository.findByUserId(userId);
        List<Misconception> misconceptions = misconceptionRepository.findByUserIdOrderByCreatedAtDesc(userId);

        var analyticsByTopic = analyticsRecords.stream().collect(Collectors.toMap(LearningAnalytics::getTopicCode, a -> a));
        var progressByTopic = progressRecords.stream().collect(Collectors.toMap(Progress::getTopicCode, p -> p));
        var misconceptionCountByTopic = misconceptions.stream()
                .collect(Collectors.groupingBy(Misconception::getTopicCode, Collectors.counting()));

        var topicCodes = new TreeSet<String>();
        topicCodes.addAll(analyticsByTopic.keySet());
        topicCodes.addAll(progressByTopic.keySet());
        topicCodes.addAll(misconceptionCountByTopic.keySet());

        List<RecommendationResponse> recommendations = new ArrayList<>();

        for (String topicCode : topicCodes) {
            int misconceptionCount = misconceptionCountByTopic.getOrDefault(topicCode, 0L).intValue();
            if (misconceptionCount > 3) {
                recommendations.add(new RecommendationResponse(topicCode, RecommendationType.REVISION,
                        "Multiple misconceptions detected. Revision recommended."));
                continue;
            }

            if (analyticsByTopic.containsKey(topicCode)) {
                RecommendationResponse recommendation = buildRecommendationFromAnalytics(analyticsByTopic.get(topicCode));
                if (recommendation != null) {
                    recommendations.add(recommendation);
                }
                continue;
            }

            if (progressByTopic.containsKey(topicCode)) {
                RecommendationResponse recommendation = buildRecommendationFromProgress(progressByTopic.get(topicCode));
                if (recommendation != null) {
                    recommendations.add(recommendation);
                }
            }
        }

        return recommendations;
    }

    private RecommendationResponse buildRecommendationFromAnalytics(LearningAnalytics analytics) {
        int masteryScore = analytics.getMasteryScore();
        int misconceptionCount = analytics.getMisconceptionCount();
        int averageQuizScore = analytics.getAverageQuizScore();
        String topicCode = analytics.getTopicCode();

        // Rule 1: Low mastery score should trigger a practice recommendation.
        if (masteryScore < 50) {
            return new RecommendationResponse(topicCode, RecommendationType.PRACTICE,
                    "Low mastery score detected. Additional practice is recommended.");
        }

        // Rule 2: Mastered topics should move learners to the next topic.
        if (masteryScore >= 80) {
            return new RecommendationResponse(topicCode, RecommendationType.NEXT_TOPIC,
                    "Topic mastered. Ready for advanced learning.");
        }

        // Rule 3: Multiple misconceptions on a topic indicate revision is needed.
        if (misconceptionCount > 3) {
            return new RecommendationResponse(topicCode, RecommendationType.REVISION,
                    "Multiple misconceptions detected. Revision recommended.");
        }

        // Rule 4: Low quiz performance should trigger quiz practice.
        if (averageQuizScore < 60) {
            return new RecommendationResponse(topicCode, RecommendationType.QUIZ_PRACTICE,
                    "Quiz performance is below target. Additional quiz practice recommended.");
        }

        return null;
    }

    private RecommendationResponse buildRecommendationFromProgress(Progress progress) {
        int masteryScore = progress.getMasteryScore();
        String topicCode = progress.getTopicCode();

        if (masteryScore < 50) {
            return new RecommendationResponse(topicCode, RecommendationType.PRACTICE,
                    "Low mastery score detected. Additional practice is recommended.");
        }

        if (masteryScore >= 80) {
            return new RecommendationResponse(topicCode, RecommendationType.NEXT_TOPIC,
                    "Topic mastered. Ready for advanced learning.");
        }

        return null;
    }

    private RecommendationResponse buildRevisionRecommendation(List<Misconception> misconceptions) {
        String topicCode = misconceptions.get(0).getTopicCode();
        long countForTopic = misconceptions.stream().filter(m -> m.getTopicCode().equals(topicCode)).count();
        if (countForTopic > 3) {
            return new RecommendationResponse(topicCode, RecommendationType.REVISION,
                    "Multiple misconceptions detected. Revision recommended.");
        }
        return null;
    }
}
