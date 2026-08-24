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
import com.arstem.backend.learninganalytics.service.LearningAnalyticsService;
import com.arstem.backend.misconception.domain.MisconceptionStatus;
import com.arstem.backend.misconception.repository.MisconceptionRepository;
import com.arstem.backend.progress.domain.Progress;
import com.arstem.backend.progress.repository.ProgressRepository;
import com.arstem.backend.user.domain.User;
import com.arstem.backend.user.service.UserService;

/**
 * Generates mastery-tier recommendations for the AI Coach screen.
 *
 * <p>Tier → recommendation map:
 * <pre>
 *   MASTERED   (≥ 80)  →  NEXT_TOPIC   "You are ready for the next topic."
 *   PROFICIENT (60–79) →  QUIZ_PRACTICE "Practise Insert/Delete to reach Mastered."
 *   DEVELOPING (40–59) →  REVISION     "Repeat the assessment to consolidate."
 *   BEGINNER   (< 40)  →  PRACTICE     "Review the learning workspace first."
 * </pre>
 *
 * <p>Active misconceptions (ACTIVE status only) take precedence and always
 * produce a REVISION recommendation regardless of the mastery score.
 */
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

    // ── Public API ────────────────────────────────────────────────────────────

    /** Global recommendations — all topics, used by the dashboard. */
    public List<RecommendationResponse> getRecommendations(String authenticatedEmail) {
        User user = getUser(authenticatedEmail);
        String userId = user.getId();

        List<Progress> progress = progressRepository.findByUserId(userId);
        List<LearningAnalytics> analytics = analyticsRepository.findByUserId(userId);

        // For the global list we can still use the full misconception counts stored
        // in the analytics document (misconceptionCount = active-only since the fix).
        return buildRecommendations(progress, analytics, userId, null);
    }

    /**
     * Single topic-scoped recommendation for the AI Coach screen.
     * Returns {@code null} (→ HTTP 204) when no recommendation applies.
     */
    public RecommendationResponse getRecommendationForTopic(String authenticatedEmail,
            String topicCode) {
        User user = getUser(authenticatedEmail);
        String userId = user.getId();
        String normalized = topicCode.trim().toUpperCase();

        List<Progress> progress = progressRepository.findByUserId(userId).stream()
                .filter(p -> p.getTopicCode().equals(normalized))
                .collect(Collectors.toList());
        List<LearningAnalytics> analytics = analyticsRepository.findByUserId(userId).stream()
                .filter(a -> a.getTopicCode().equals(normalized))
                .collect(Collectors.toList());

        List<RecommendationResponse> results =
                buildRecommendations(progress, analytics, userId, normalized);
        return results.isEmpty() ? null : results.get(0);
    }

    // ── Core builder ──────────────────────────────────────────────────────────

    private List<RecommendationResponse> buildRecommendations(
            List<Progress> progressRecords,
            List<LearningAnalytics> analyticsRecords,
            String userId, String singleTopicCode) {

        var analyticsByTopic = analyticsRecords.stream()
                .collect(Collectors.toMap(LearningAnalytics::getTopicCode, a -> a));
        var progressByTopic = progressRecords.stream()
                .collect(Collectors.toMap(Progress::getTopicCode, p -> p));

        var topicCodes = new TreeSet<String>();
        topicCodes.addAll(analyticsByTopic.keySet());
        topicCodes.addAll(progressByTopic.keySet());

        List<RecommendationResponse> recommendations = new ArrayList<>();

        for (String topicCode : topicCodes) {

            // Live count of ACTIVE misconceptions from DB (most accurate).
            long activeMisconceptions = singleTopicCode != null
                    ? misconceptionRepository
                            .findByUserIdAndTopicCodeAndStatusOrderByCreatedAtDesc(
                                    userId, topicCode, MisconceptionStatus.ACTIVE)
                            .size()
                    : (analyticsByTopic.containsKey(topicCode)
                            ? analyticsByTopic.get(topicCode).getMisconceptionCount()
                            : 0L);

            if (analyticsByTopic.containsKey(topicCode)) {
                RecommendationResponse rec = buildFromAnalytics(
                        analyticsByTopic.get(topicCode), (int) activeMisconceptions);
                if (rec != null) recommendations.add(rec);
            } else if (progressByTopic.containsKey(topicCode)) {
                RecommendationResponse rec = buildFromProgress(
                        progressByTopic.get(topicCode), (int) activeMisconceptions);
                if (rec != null) recommendations.add(rec);
            }
        }

        return recommendations;
    }

    // ── Tier-based recommendation rules ──────────────────────────────────────

    private RecommendationResponse buildFromAnalytics(LearningAnalytics a,
            int activeMisconceptions) {
        return tierRecommendation(a.getTopicCode(), a.getMasteryScore(), activeMisconceptions);
    }

    private RecommendationResponse buildFromProgress(Progress p, int activeMisconceptions) {
        return tierRecommendation(p.getTopicCode(), p.getMasteryScore(), activeMisconceptions);
    }

    /**
     * Maps the student's current mastery tier to the most appropriate next action.
     *
     * <p>Active misconceptions always override the tier rule — a student with
     * unresolved conceptual errors needs revision even if their raw score is high.
     */
    static RecommendationResponse tierRecommendation(String topicCode, int masteryScore,
            int activeMisconceptions) {

        String level = LearningAnalyticsService.calculateMasteryLevel(masteryScore);
        String label = LearningAnalyticsService.formatTopicLabel(topicCode);

        // Active misconceptions take priority — even a high scorer needs to
        // address residual conceptual errors before advancing.
        if (activeMisconceptions > 0) {
            return new RecommendationResponse(topicCode, RecommendationType.REVISION,
                    activeMisconceptions + " active misconception"
                    + (activeMisconceptions == 1 ? "" : "s")
                    + " detected for " + label
                    + ". Resolve these before advancing.");
        }

        return switch (level) {
            case "MASTERED" -> new RecommendationResponse(topicCode, RecommendationType.NEXT_TOPIC,
                    "You have mastered " + label
                    + ". Move on to the next topic to continue your learning journey.");

            case "PROFICIENT" -> new RecommendationResponse(topicCode,
                    RecommendationType.QUIZ_PRACTICE,
                    "You are proficient in " + label
                    + ". Practise insertion and deletion operations "
                    + "to push your mastery to Mastered level.");

            case "DEVELOPING" -> new RecommendationResponse(topicCode, RecommendationType.REVISION,
                    "You are developing your understanding of " + label
                    + ". Repeat the assessment after reviewing the revision suggestions.");

            default -> new RecommendationResponse(topicCode, RecommendationType.PRACTICE,
                    "Review the " + label
                    + " learning workspace before attempting the assessment again.");
        };
    }

    // ── Helper ────────────────────────────────────────────────────────────────

    private User getUser(String email) {
        return userService.findByEmail(email)
                .orElseThrow(() -> new UnauthorizedException("Authenticated user no longer exists."));
    }
}
