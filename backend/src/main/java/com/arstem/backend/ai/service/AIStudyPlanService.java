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
import com.arstem.backend.learninganalytics.service.LearningAnalyticsService;
import com.arstem.backend.misconception.domain.Misconception;
import com.arstem.backend.misconception.domain.MisconceptionStatus;
import com.arstem.backend.misconception.repository.MisconceptionRepository;
import com.arstem.backend.user.domain.User;
import com.arstem.backend.user.service.UserService;

/**
 * Generates a mastery-tier study plan for the AI Coach screen.
 *
 * <p>Task sets per tier:
 * <pre>
 *   BEGINNER   (< 40)   — Learn concept, Practice workspace, Retry assessment
 *   DEVELOPING (40–59)  — Practice insertion, Practice deletion, Attempt quiz
 *   PROFICIENT (60–79)  — Solve challenge mode, Timed assessment
 *   MASTERED   (≥ 80)   — Start next topic
 * </pre>
 *
 * <p>Active misconceptions (ACTIVE status only) are counted from the DB so
 * that resolved misconceptions never inflate task lists or priority levels.
 */
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

    // ── Public API ────────────────────────────────────────────────────────────

    /** Global study plan across all topics (dashboard use). */
    public StudyPlanResponse getStudyPlan(String authenticatedEmail) {
        User user = getUser(authenticatedEmail);
        String userId = user.getId();

        List<LearningAnalytics> analytics = analyticsRepository.findByUserId(userId);
        Map<String, Long> activeMisconceptionsByTopic =
                misconceptionRepository.findByUserIdOrderByCreatedAtDesc(userId).stream()
                        .filter(Misconception::isActive)
                        .collect(Collectors.groupingBy(
                                Misconception::getTopicCode, Collectors.counting()));

        return buildPlan(analytics, activeMisconceptionsByTopic);
    }

    /**
     * Topic-scoped study plan used by the AI Coach screen.
     * Only ACTIVE misconceptions are fetched from the DB — resolved ones
     * must never add extra tasks or raise priority.
     */
    public StudyPlanResponse getStudyPlanForTopic(String authenticatedEmail, String topicCode) {
        User user = getUser(authenticatedEmail);
        String userId = user.getId();
        String normalized = topicCode.trim().toUpperCase();

        List<LearningAnalytics> analytics = analyticsRepository.findByUserId(userId).stream()
                .filter(a -> a.getTopicCode().equals(normalized))
                .collect(Collectors.toList());

        // DB-level ACTIVE-only query — resolved misconceptions never returned.
        List<Misconception> activeMisconceptions =
                misconceptionRepository.findByUserIdAndTopicCodeAndStatusOrderByCreatedAtDesc(
                        userId, normalized, MisconceptionStatus.ACTIVE);
        Map<String, Long> activeMisconceptionsByTopic = activeMisconceptions.stream()
                .collect(Collectors.groupingBy(Misconception::getTopicCode, Collectors.counting()));

        return buildPlan(analytics, activeMisconceptionsByTopic);
    }

    // ── Core builder ──────────────────────────────────────────────────────────

    private StudyPlanResponse buildPlan(List<LearningAnalytics> analytics,
            Map<String, Long> activeMisconceptionsByTopic) {

        List<String> todayTasks    = new ArrayList<>();
        PriorityLevel overallPriority = PriorityLevel.LOW;
        List<String> reasons       = new ArrayList<>();

        for (LearningAnalytics entry : analytics) {
            String topicCode = entry.getTopicCode();
            int masteryScore = entry.getMasteryScore();
            long activeMisconceptions =
                    activeMisconceptionsByTopic.getOrDefault(topicCode, 0L);
            String label = LearningAnalyticsService.formatTopicLabel(topicCode);

            PriorityLevel topicPriority = tierPriority(masteryScore);
            addTierTasks(todayTasks, label, masteryScore, activeMisconceptions);

            // Active misconceptions raise priority regardless of tier.
            if (activeMisconceptions > 3) {
                todayTasks.add("Resolve " + activeMisconceptions
                        + " active misconceptions for " + label);
                topicPriority = raise(topicPriority);
            } else if (activeMisconceptions > 0) {
                todayTasks.add("Review " + activeMisconceptions
                        + " remaining misconception"
                        + (activeMisconceptions == 1 ? "" : "s") + " for " + label);
            }

            overallPriority = higher(overallPriority, topicPriority);
            reasons.add(tierReason(label, masteryScore, activeMisconceptions));
        }

        if (todayTasks.isEmpty()) {
            return new StudyPlanResponse(List.of(), 0, PriorityLevel.LOW,
                    "No study plan available yet — complete an assessment to get started.");
        }

        int estimatedTimeMinutes = minutesFor(overallPriority);
        return new StudyPlanResponse(
                List.copyOf(todayTasks),
                estimatedTimeMinutes,
                overallPriority,
                String.join(" ", reasons).trim());
    }

    // ── Tier-task sets ────────────────────────────────────────────────────────

    /**
     * Adds the appropriate task set for the student's current mastery tier.
     */
    private static void addTierTasks(List<String> tasks, String label,
            int masteryScore, long activeMisconceptions) {

        String tier = LearningAnalyticsService.calculateMasteryLevel(masteryScore);
        switch (tier) {
            case "BEGINNER" -> {
                tasks.add("Study the " + label + " concept in the learning workspace");
                tasks.add("Complete the " + label + " AR practice activity");
                tasks.add("Retry the " + label + " assessment");
            }
            case "DEVELOPING" -> {
                tasks.add("Practise " + label + " insertion operations");
                tasks.add("Practise " + label + " deletion operations");
                tasks.add("Attempt the " + label + " quiz again");
            }
            case "PROFICIENT" -> {
                tasks.add("Solve the " + label + " challenge mode");
                tasks.add("Complete a timed " + label + " assessment");
            }
            case "MASTERED" -> tasks.add("Start the next topic after " + label);
        }
    }

    // ── Priority helpers ──────────────────────────────────────────────────────

    private static PriorityLevel tierPriority(int masteryScore) {
        return switch (LearningAnalyticsService.calculateMasteryLevel(masteryScore)) {
            case "BEGINNER"   -> PriorityLevel.HIGH;
            case "DEVELOPING" -> PriorityLevel.HIGH;
            case "PROFICIENT" -> PriorityLevel.MEDIUM;
            default           -> PriorityLevel.LOW;
        };
    }

    private static PriorityLevel raise(PriorityLevel p) {
        return switch (p) {
            case LOW    -> PriorityLevel.MEDIUM;
            case MEDIUM -> PriorityLevel.HIGH;
            case HIGH   -> PriorityLevel.HIGH;
        };
    }

    private static PriorityLevel higher(PriorityLevel a, PriorityLevel b) {
        if (a == PriorityLevel.HIGH || b == PriorityLevel.HIGH) return PriorityLevel.HIGH;
        if (a == PriorityLevel.MEDIUM || b == PriorityLevel.MEDIUM) return PriorityLevel.MEDIUM;
        return PriorityLevel.LOW;
    }

    private static int minutesFor(PriorityLevel p) {
        return switch (p) {
            case HIGH   -> 60;
            case MEDIUM -> 45;
            case LOW    -> 30;
        };
    }

    // ── Reason generation ─────────────────────────────────────────────────────

    private static String tierReason(String label, int masteryScore, long activeMisconceptions) {
        String tier = LearningAnalyticsService.calculateMasteryLevel(masteryScore);
        String base = switch (tier) {
            case "BEGINNER"   -> label + " mastery is at BEGINNER level — "
                    + "start with the learning workspace before the assessment.";
            case "DEVELOPING" -> label + " is at DEVELOPING — "
                    + "practise operations to reach Proficient.";
            case "PROFICIENT" -> label + " is Proficient — "
                    + "challenge mode will push you to Mastered.";
            default           -> label + " is Mastered — advance to the next topic.";
        };
        if (activeMisconceptions > 0) {
            base += " " + activeMisconceptions + " active misconception"
                    + (activeMisconceptions == 1 ? "" : "s") + " still need attention.";
        }
        return base;
    }

    // ── Helper ────────────────────────────────────────────────────────────────

    private User getUser(String email) {
        return userService.findByEmail(email)
                .orElseThrow(() -> new UnauthorizedException("Authenticated user no longer exists."));
    }
}
