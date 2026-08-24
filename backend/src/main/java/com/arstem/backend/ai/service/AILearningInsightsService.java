package com.arstem.backend.ai.service;

import java.util.List;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;

import com.arstem.backend.ai.domain.LearningInsightsResponse;
import com.arstem.backend.common.exception.UnauthorizedException;
import com.arstem.backend.learninganalytics.domain.LearningAnalytics;
import com.arstem.backend.learninganalytics.repository.LearningAnalyticsRepository;
import com.arstem.backend.learninganalytics.service.LearningAnalyticsService;
import com.arstem.backend.misconception.domain.MisconceptionStatus;
import com.arstem.backend.misconception.repository.MisconceptionRepository;
import com.arstem.backend.progress.repository.ProgressRepository;
import com.arstem.backend.quiz.domain.QuizAttempt;
import com.arstem.backend.quiz.repository.QuizAttemptRepository;
import com.arstem.backend.user.domain.User;
import com.arstem.backend.user.service.UserService;

/**
 * Generates learning insights for the AI Coach screen.
 *
 * <p>Key behaviours introduced in this version:
 * <ul>
 *   <li>Strengths use the MASTERED threshold (≥ 80), weaknesses use BEGINNER (< 40).</li>
 *   <li>Only ACTIVE (unresolved) misconceptions are counted — resolved ones never
 *       appear in the insights summary.</li>
 *   <li>The summary is personalised: it includes the latest quiz score, an
 *       improvement sentence when the student progressed, and encouragement
 *       or a concrete next action based on mastery tier.</li>
 * </ul>
 */
@Service
public class AILearningInsightsService {

    private final ProgressRepository progressRepository;
    private final LearningAnalyticsRepository analyticsRepository;
    private final MisconceptionRepository misconceptionRepository;
    private final QuizAttemptRepository quizAttemptRepository;
    private final UserService userService;

    public AILearningInsightsService(ProgressRepository progressRepository,
            LearningAnalyticsRepository analyticsRepository,
            MisconceptionRepository misconceptionRepository,
            QuizAttemptRepository quizAttemptRepository,
            UserService userService) {
        this.progressRepository = progressRepository;
        this.analyticsRepository = analyticsRepository;
        this.misconceptionRepository = misconceptionRepository;
        this.quizAttemptRepository = quizAttemptRepository;
        this.userService = userService;
    }

    // ── Public API ────────────────────────────────────────────────────────────

    /** Global insights across all topics (dashboard use). */
    public LearningInsightsResponse getLearningInsights(String authenticatedEmail) {
        User user = getUser(authenticatedEmail);
        List<LearningAnalytics> analytics = analyticsRepository.findByUserId(user.getId());
        return buildInsights(analytics, user.getId(), null);
    }

    /**
     * Topic-scoped insights for the AI Coach screen.
     *
     * <p>Returns insights exclusively for {@code topicCode} — no other topic's
     * data will appear in strengths, weaknesses, or the summary text.
     */
    public LearningInsightsResponse getLearningInsightsForTopic(String authenticatedEmail,
            String topicCode) {
        User user = getUser(authenticatedEmail);
        String normalized = topicCode.trim().toUpperCase();

        List<LearningAnalytics> analytics = analyticsRepository.findByUserId(user.getId())
                .stream()
                .filter(a -> a.getTopicCode().equals(normalized))
                .collect(Collectors.toList());

        return buildInsights(analytics, user.getId(), normalized);
    }

    // ── Core builder ──────────────────────────────────────────────────────────

    private LearningInsightsResponse buildInsights(List<LearningAnalytics> analytics,
            String userId, String singleTopicCode) {

        // ── Mastery tiers ─────────────────────────────────────────────────────
        // MASTERED ≥ 80  →  strength
        // PROFICIENT 60–79  →  neither strength nor weakness
        // DEVELOPING 40–59  →  neither
        // BEGINNER < 40  →  weakness
        List<String> strengths = analytics.stream()
                .filter(a -> a.getMasteryScore() >= 80)
                .map(LearningAnalytics::getTopicCode)
                .collect(Collectors.toList());
        List<String> weaknesses = analytics.stream()
                .filter(a -> a.getMasteryScore() < 40)
                .map(LearningAnalytics::getTopicCode)
                .collect(Collectors.toList());

        // Practice topics: ACTIVE misconceptions exist OR averageQuizScore < 60
        List<String> practiceTopics = analytics.stream()
                .filter(a -> a.getMisconceptionCount() > 0 || a.getAverageQuizScore() < 60)
                .map(LearningAnalytics::getTopicCode)
                .collect(Collectors.toList());

        int totalTopicsLearned = (int) analytics.stream()
                .map(LearningAnalytics::getTopicCode)
                .distinct()
                .count();
        double averageMasteryScore = analytics.isEmpty() ? 0.0
                : analytics.stream()
                        .mapToInt(LearningAnalytics::getMasteryScore)
                        .average()
                        .orElse(0.0);

        // ── Personalised summary ──────────────────────────────────────────────
        String summary = buildSummary(analytics, userId, singleTopicCode);

        return new LearningInsightsResponse(strengths, weaknesses, practiceTopics,
                totalTopicsLearned, averageMasteryScore, summary);
    }

    // ── Summary generation ────────────────────────────────────────────────────

    /**
     * When the AI Coach is opened for a single topic, the summary is rich and
     * personalised.  For the global (dashboard) case it falls back to a simpler
     * cross-topic narrative.
     */
    private String buildSummary(List<LearningAnalytics> analytics, String userId,
            String singleTopicCode) {

        if (analytics.isEmpty()) {
            return "No learning data available yet. "
                    + "Complete an assessment to generate your personalised summary.";
        }

        // Single-topic path: use the pre-computed summary stored in the analytics
        // document (generated by LearningAnalyticsService.buildPersonalizedSummary)
        // and optionally enrich it with improvement detection from raw quiz attempts.
        if (singleTopicCode != null) {
            LearningAnalytics topicAnalytics = analytics.get(0);

            // Pull the two most-recent attempts to detect improvement/regression.
            List<QuizAttempt> recent = quizAttemptRepository
                    .findByUserIdAndTopicCodeOrderBySubmittedAtDesc(userId, singleTopicCode);

            String base = topicAnalytics.getSummary();
            if (!base.isEmpty()) {
                return base;
            }

            // Fallback if summary not yet persisted (first run).
            return LearningAnalyticsService.buildPersonalizedSummary(
                    singleTopicCode, recent,
                    recent.isEmpty() ? 0 : recent.get(0).getScore(),
                    topicAnalytics.getMasteryScore(),
                    topicAnalytics.getMasteryLevel(),
                    topicAnalytics.getMisconceptionCount(), 0);
        }

        // ── Global / multi-topic summary ──────────────────────────────────────
        long masteredCount    = analytics.stream().filter(a -> a.getMasteryScore() >= 80).count();
        long proficientCount  = analytics.stream()
                .filter(a -> a.getMasteryScore() >= 60 && a.getMasteryScore() < 80).count();
        long beginnerCount    = analytics.stream().filter(a -> a.getMasteryScore() < 40).count();

        if (masteredCount == analytics.size()) {
            return "You have mastered all " + analytics.size()
                    + " studied topic" + (analytics.size() == 1 ? "" : "s") + ". Outstanding!";
        }
        if (beginnerCount == analytics.size()) {
            return "All studied topics still need practice. "
                    + "Focus on the revision actions listed below.";
        }
        if (masteredCount > 0 && beginnerCount > 0) {
            return masteredCount + " topic" + (masteredCount == 1 ? " is" : "s are")
                    + " mastered and " + beginnerCount
                    + " still need" + (beginnerCount == 1 ? "s" : "") + " revision.";
        }
        if (masteredCount > 0) {
            return masteredCount + " topic" + (masteredCount == 1 ? " is" : "s are")
                    + " mastered. Keep practising the remaining topics to build full proficiency.";
        }
        if (proficientCount > 0) {
            return "You are making good progress — "
                    + proficientCount + " topic" + (proficientCount == 1 ? " is" : "s are")
                    + " at Proficient level. Push on to Mastered!";
        }
        return "Your learning is progressing. "
                + "Continue practising to move topics through Developing → Proficient → Mastered.";
    }

    // ── Helper ────────────────────────────────────────────────────────────────

    private User getUser(String email) {
        return userService.findByEmail(email)
                .orElseThrow(() -> new UnauthorizedException("Authenticated user no longer exists."));
    }
}
