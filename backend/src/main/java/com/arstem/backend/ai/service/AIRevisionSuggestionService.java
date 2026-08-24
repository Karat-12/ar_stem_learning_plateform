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
import com.arstem.backend.learninganalytics.service.LearningAnalyticsService;
import com.arstem.backend.misconception.domain.Misconception;
import com.arstem.backend.misconception.domain.MisconceptionStatus;
import com.arstem.backend.misconception.repository.MisconceptionRepository;
import com.arstem.backend.user.domain.User;
import com.arstem.backend.user.service.UserService;

/**
 * Generates revision suggestions for the AI Coach screen.
 *
 * <p>Only ACTIVE (unresolved) misconceptions are considered.  Resolved
 * misconceptions are permanently excluded — a student who corrected their
 * understanding should never see stale revision actions about it.
 *
 * <p>Mastery-tier thresholds aligned with new levels:
 * <pre>
 *   lowMastery          masteryScore &lt; 40   (BEGINNER)
 *   repeatedMisconceptions  activeMisconceptions &gt; 3
 *   lowQuiz             averageQuizScore &lt; 60
 * </pre>
 */
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

    // ── Public API ────────────────────────────────────────────────────────────

    /** Global revision suggestions across all topics (dashboard use). */
    public RevisionSuggestionResponse getRevisionSuggestions(String authenticatedEmail) {
        User user = getUser(authenticatedEmail);
        String userId = user.getId();

        List<LearningAnalytics> analytics = analyticsRepository.findByUserId(userId);

        // Active misconceptions only — resolved must not drive revision.
        Map<String, Long> activeMisconceptionsByTopic =
                misconceptionRepository.findByUserIdOrderByCreatedAtDesc(userId).stream()
                        .filter(Misconception::isActive)
                        .collect(Collectors.groupingBy(
                                Misconception::getTopicCode, Collectors.counting()));

        return buildResponse(analytics, activeMisconceptionsByTopic);
    }

    /**
     * Topic-scoped revision suggestions — used by the AI Coach screen.
     * Uses the DB-level ACTIVE-only query so resolved misconceptions are
     * excluded at the database level, not just filtered in memory.
     */
    public RevisionSuggestionResponse getRevisionSuggestionsForTopic(
            String authenticatedEmail, String topicCode) {
        User user = getUser(authenticatedEmail);
        String userId = user.getId();
        String normalized = topicCode.trim().toUpperCase();

        List<LearningAnalytics> analytics = analyticsRepository.findByUserId(userId).stream()
                .filter(a -> a.getTopicCode().equals(normalized))
                .collect(Collectors.toList());

        // DB-level ACTIVE-only filter — resolved misconceptions never returned.
        List<Misconception> activeMisconceptions =
                misconceptionRepository.findByUserIdAndTopicCodeAndStatusOrderByCreatedAtDesc(
                        userId, normalized, MisconceptionStatus.ACTIVE);
        Map<String, Long> activeMisconceptionsByTopic = activeMisconceptions.stream()
                .collect(Collectors.groupingBy(Misconception::getTopicCode, Collectors.counting()));

        return buildResponse(analytics, activeMisconceptionsByTopic);
    }

    // ── Core builder ──────────────────────────────────────────────────────────

    private RevisionSuggestionResponse buildResponse(List<LearningAnalytics> analytics,
            Map<String, Long> activeMisconceptionsByTopic) {

        List<String> revisionTopics  = new ArrayList<>();
        List<String> revisionActions = new ArrayList<>();
        List<String> reasons         = new ArrayList<>();

        for (LearningAnalytics entry : analytics) {
            String topicCode   = entry.getTopicCode();
            int masteryScore   = entry.getMasteryScore();
            int averageQuizScore = entry.getAverageQuizScore();
            long activeMisconceptions = activeMisconceptionsByTopic.getOrDefault(topicCode, 0L);

            // Aligned with new mastery levels: BEGINNER < 40.
            boolean lowMastery             = masteryScore < 40;
            boolean repeatedMisconceptions = activeMisconceptions > 3;
            boolean lowQuiz                = averageQuizScore < 60;
            boolean anyActiveMisconceptions = activeMisconceptions > 0;

            String label = LearningAnalyticsService.formatTopicLabel(topicCode);

            if (lowMastery) {
                revisionTopics.add(topicCode);
            }

            if (repeatedMisconceptions) {
                revisionActions.add("Review the " + activeMisconceptions
                        + " active misconceptions for " + label);
            } else if (anyActiveMisconceptions) {
                revisionActions.add("Resolve the remaining " + activeMisconceptions
                        + " active misconception"
                        + (activeMisconceptions == 1 ? "" : "s") + " for " + label);
            }

            if (lowQuiz) {
                revisionActions.add("Retake the " + label + " quiz to improve your score");
            }

            if (lowMastery || repeatedMisconceptions || lowQuiz) {
                reasons.add(generateReason(label, masteryScore, activeMisconceptions,
                        lowMastery, repeatedMisconceptions, lowQuiz));
            }
        }

        int estimatedRevisionTimeMinutes = revisionTopics.size() * 20
                + (int) revisionActions.stream()
                        .filter(a -> a.startsWith("Review") || a.startsWith("Resolve"))
                        .count() * 10;
        String reason = String.join(" ", reasons).trim();

        return new RevisionSuggestionResponse(
                List.copyOf(revisionTopics),
                List.copyOf(revisionActions),
                estimatedRevisionTimeMinutes,
                reason.isEmpty() ? "No revision needed — keep up the great work!" : reason);
    }

    // ── Reason generation ─────────────────────────────────────────────────────

    private static String generateReason(String label, int masteryScore,
            long activeMisconceptions,
            boolean lowMastery, boolean repeatedMisconceptions, boolean lowQuiz) {

        if (lowMastery && repeatedMisconceptions) {
            return label + " needs focused revision: mastery is at BEGINNER level "
                    + "and " + activeMisconceptions + " active misconceptions remain.";
        }
        if (lowMastery && lowQuiz) {
            return label + " requires revision due to low mastery (" + masteryScore
                    + ") and quiz performance below 60%.";
        }
        if (repeatedMisconceptions) {
            return label + " has " + activeMisconceptions
                    + " unresolved misconceptions that are holding back progress.";
        }
        if (lowMastery) {
            return label + " mastery (" + masteryScore
                    + ") is at BEGINNER level — review the learning workspace.";
        }
        if (lowQuiz) {
            return label + " quiz score is below 60% — retaking the assessment will help.";
        }
        return label + " requires some revision.";
    }

    // ── Helper ────────────────────────────────────────────────────────────────

    private User getUser(String email) {
        return userService.findByEmail(email)
                .orElseThrow(() -> new UnauthorizedException("Authenticated user no longer exists."));
    }
}
