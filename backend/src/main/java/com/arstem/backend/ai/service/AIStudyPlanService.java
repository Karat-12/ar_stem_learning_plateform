package com.arstem.backend.ai.service;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;

import com.arstem.backend.ai.domain.PriorityLevel;
import com.arstem.backend.ai.domain.StudyPlanResponse;
import com.arstem.backend.common.exception.UnauthorizedException;
import com.arstem.backend.learninganalytics.domain.LearningAnalytics;
import com.arstem.backend.learninganalytics.repository.LearningAnalyticsRepository;
import com.arstem.backend.misconception.domain.Misconception;
import com.arstem.backend.misconception.repository.MisconceptionRepository;
import com.arstem.backend.user.domain.User;
import com.arstem.backend.user.service.UserService;

@Service
public class AIStudyPlanService {

    private final LearningAnalyticsRepository analyticsRepository;
    private final MisconceptionRepository misconceptionRepository;
    private final UserService userService;

    public AIStudyPlanService(LearningAnalyticsRepository analyticsRepository,
            MisconceptionRepository misconceptionRepository,
            UserService userService) {
        this.analyticsRepository = analyticsRepository;
        this.misconceptionRepository = misconceptionRepository;
        this.userService = userService;
    }

    public StudyPlanResponse getStudyPlan(String authenticatedEmail) {
        User user = userService.findByEmail(authenticatedEmail)
                .orElseThrow(() -> new UnauthorizedException("Authenticated user no longer exists."));
        String userId = user.getId();

        List<LearningAnalytics> analytics = analyticsRepository.findByUserId(userId);
        Map<String, Long> misconceptionsByTopic = misconceptionRepository.findByUserIdOrderByCreatedAtDesc(userId).stream()
                .collect(Collectors.groupingBy(Misconception::getTopicCode, Collectors.counting()));

        List<String> todayTasks = new ArrayList<>();
        PriorityLevel overallPriority = PriorityLevel.LOW;
        List<String> reasons = new ArrayList<>();

        for (LearningAnalytics analyticsEntry : analytics) {
            String topicCode = analyticsEntry.getTopicCode();
            int masteryScore = analyticsEntry.getMasteryScore();
            long misconceptionCount = misconceptionsByTopic.getOrDefault(topicCode, 0L);

            PriorityLevel topicPriority = determinePriority(masteryScore);
            addStudyTasks(todayTasks, topicCode, masteryScore);

            if (misconceptionCount > 3) {
                todayTasks.add("Review misconceptions for " + topicCode);
                topicPriority = increasePriority(topicPriority);
            }

            overallPriority = pickHigherPriority(overallPriority, topicPriority);
            reasons.add(generateReason(topicCode, masteryScore, misconceptionCount));
        }

        if (todayTasks.isEmpty()) {
            return new StudyPlanResponse(List.of(), 0, PriorityLevel.LOW,
                    "No study plan can be generated because no analytics data is available.");
        }

        int estimatedTimeMinutes = minutesForPriority(overallPriority);
        String reason = String.join(" ", reasons).trim();
        return new StudyPlanResponse(List.copyOf(todayTasks), estimatedTimeMinutes, overallPriority, reason);
    }

    private PriorityLevel determinePriority(int masteryScore) {
        if (masteryScore < 50) {
            return PriorityLevel.HIGH;
        }
        if (masteryScore < 80) {
            return PriorityLevel.MEDIUM;
        }
        return PriorityLevel.LOW;
    }

    private void addStudyTasks(List<String> todayTasks, String topicCode, int masteryScore) {
        if (masteryScore < 50) {
            todayTasks.add("Review " + topicCode + " concepts");
            todayTasks.add("Complete " + topicCode + " practice activity");
            todayTasks.add("Attempt " + topicCode + " quiz");
            return;
        }
        if (masteryScore < 80) {
            todayTasks.add("Practice " + topicCode);
            todayTasks.add("Attempt quiz revision");
            return;
        }
        todayTasks.add("Explore next topic after " + topicCode);
    }

    private PriorityLevel increasePriority(PriorityLevel priorityLevel) {
        if (priorityLevel == PriorityLevel.LOW) {
            return PriorityLevel.MEDIUM;
        }
        if (priorityLevel == PriorityLevel.MEDIUM) {
            return PriorityLevel.HIGH;
        }
        return PriorityLevel.HIGH;
    }

    private PriorityLevel pickHigherPriority(PriorityLevel current, PriorityLevel candidate) {
        if (candidate == PriorityLevel.HIGH || current == PriorityLevel.LOW && candidate == PriorityLevel.MEDIUM) {
            return candidate;
        }
        if (current == PriorityLevel.MEDIUM && candidate == PriorityLevel.LOW) {
            return current;
        }
        return current;
    }

    private int minutesForPriority(PriorityLevel priorityLevel) {
        return switch (priorityLevel) {
            case HIGH -> 60;
            case MEDIUM -> 45;
            case LOW -> 30;
        };
    }

    private String generateReason(String topicCode, int masteryScore, long misconceptionCount) {
        if (masteryScore < 50 && misconceptionCount > 3) {
            return topicCode + " mastery score is below target and repeated misconceptions were detected.";
        }
        if (masteryScore < 50) {
            return topicCode + " mastery score is below target.";
        }
        if (masteryScore < 80) {
            return topicCode + " needs targeted practice to improve mastery.";
        }
        return topicCode + " is ready for extension learning.";
    }
}
