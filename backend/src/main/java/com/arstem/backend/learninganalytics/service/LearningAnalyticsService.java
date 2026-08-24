package com.arstem.backend.learninganalytics.service;

import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;

import com.arstem.backend.common.exception.ResourceNotFoundException;
import com.arstem.backend.common.exception.UnauthorizedException;
import com.arstem.backend.learninganalytics.domain.LearningAnalytics;
import com.arstem.backend.learninganalytics.repository.LearningAnalyticsRepository;
import com.arstem.backend.misconception.domain.Misconception;
import com.arstem.backend.misconception.domain.MisconceptionStatus;
import com.arstem.backend.misconception.repository.MisconceptionRepository;
import com.arstem.backend.quiz.domain.QuizAttempt;
import com.arstem.backend.quiz.repository.QuizAttemptRepository;
import com.arstem.backend.session.domain.LearningSession;
import com.arstem.backend.session.domain.SessionStatus;
import com.arstem.backend.session.repository.LearningSessionRepository;
import com.arstem.backend.user.domain.User;
import com.arstem.backend.user.service.UserService;

@Service
public class LearningAnalyticsService {

    private final LearningAnalyticsRepository analyticsRepository;
    private final QuizAttemptRepository quizAttemptRepository;
    private final MisconceptionRepository misconceptionRepository;
    private final LearningSessionRepository learningSessionRepository;
    private final UserService userService;

    public LearningAnalyticsService(LearningAnalyticsRepository analyticsRepository,
            QuizAttemptRepository quizAttemptRepository,
            MisconceptionRepository misconceptionRepository,
            LearningSessionRepository learningSessionRepository,
            UserService userService) {
        this.analyticsRepository = analyticsRepository;
        this.quizAttemptRepository = quizAttemptRepository;
        this.misconceptionRepository = misconceptionRepository;
        this.learningSessionRepository = learningSessionRepository;
        this.userService = userService;
    }

    // ── Public API ────────────────────────────────────────────────────────────

    public void generateAnalytics(String authenticatedEmail) {
        User user = getAuthenticatedUser(authenticatedEmail);
        generateForUser(user.getId());
    }

    public List<LearningAnalytics> getMyAnalytics(String authenticatedEmail) {
        User user = getAuthenticatedUser(authenticatedEmail);
        generateForUser(user.getId());
        return analyticsRepository.findByUserId(user.getId());
    }

    public LearningAnalytics getTopicAnalytics(String authenticatedEmail, String topicCode) {
        User user = getAuthenticatedUser(authenticatedEmail);
        String normalized = normalizeTopicCode(topicCode);
        generateForUser(user.getId());
        return analyticsRepository.findByUserIdAndTopicCode(user.getId(), normalized)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Analytics for topic '" + topicCode + "' not found."));
    }

    // ── Core generation ───────────────────────────────────────────────────────

    private void generateForUser(String userId) {
        List<QuizAttempt> attempts = quizAttemptRepository.findByUserIdOrderBySubmittedAtDesc(userId);
        List<Misconception> allMisconceptions = misconceptionRepository.findByUserIdOrderByCreatedAtDesc(userId);
        List<LearningSession> sessions = learningSessionRepository.findByUserIdOrderByStartedAtDesc(userId);

        // Normalize topicCodes before grouping so legacy "linked-list" and canonical
        // "DSA_LINKED_LIST" always land in the same bucket.
        Map<String, List<QuizAttempt>> attemptsByTopic = attempts.stream()
                .collect(Collectors.groupingBy(a -> normalizeTopicCode(a.getTopicCode())));
        Map<String, List<Misconception>> allMisconceptionsByTopic = allMisconceptions.stream()
                .collect(Collectors.groupingBy(m -> normalizeTopicCode(m.getTopicCode())));
        Map<String, List<LearningSession>> sessionsByTopic = sessions.stream()
                .collect(Collectors.groupingBy(s -> normalizeTopicCode(s.getTopicCode())));

        Set<String> topicCodes = new TreeSet<>();
        topicCodes.addAll(attemptsByTopic.keySet());
        topicCodes.addAll(allMisconceptionsByTopic.keySet());
        topicCodes.addAll(sessionsByTopic.keySet());

        for (String topicCode : topicCodes) {
            List<QuizAttempt> topicAttempts =
                    attemptsByTopic.getOrDefault(topicCode, List.of());
            List<Misconception> topicMisconceptions =
                    allMisconceptionsByTopic.getOrDefault(topicCode, List.of());
            List<LearningSession> topicSessions =
                    sessionsByTopic.getOrDefault(topicCode, List.of());

            // Step 1: resolve misconceptions based on latest quiz performance.
            resolveAddressedMisconceptions(userId, topicCode, topicAttempts, topicMisconceptions);

            // Step 2: recompute analytics using only still-active misconceptions.
            List<Misconception> activeMisconceptions = topicMisconceptions.stream()
                    .filter(Misconception::isActive)
                    .collect(Collectors.toList());

            computeAndSave(userId, topicCode, topicAttempts, activeMisconceptions,
                    topicMisconceptions, topicSessions);
        }
    }

    // ── Misconception resolution ──────────────────────────────────────────────

    /**
     * Resolves ACTIVE misconceptions for a topic when the student's latest
     * quiz score shows they have overcome their previous misunderstandings.
     *
     * <p>Resolution rules:
     * <ul>
     *   <li>latestScore ≥ 80 → resolve ALL active misconceptions for the topic.</li>
     *   <li>latestScore ≥ 60 → resolve the oldest half of active misconceptions
     *       (student shows significant improvement but not full mastery yet).</li>
     *   <li>latestScore &lt; 60 → no resolution; misconceptions remain active.</li>
     * </ul>
     */
    static void resolveAddressedMisconceptions(String userId, String topicCode,
            List<QuizAttempt> topicAttempts, List<Misconception> topicMisconceptions) {

        if (topicAttempts.isEmpty()) return;

        // Latest attempt is first because the query orders by submittedAt DESC.
        int latestScore = topicAttempts.get(0).getScore();

        if (latestScore < 60) return;   // no resolution below 60

        List<Misconception> active = topicMisconceptions.stream()
                .filter(Misconception::isActive)
                .sorted(Comparator.comparing(Misconception::getCreatedAt))  // oldest first
                .collect(Collectors.toList());

        if (active.isEmpty()) return;

        List<Misconception> toResolve;
        if (latestScore >= 80) {
            toResolve = active;   // resolve everything
        } else {
            // 60–79: resolve the older half — student is improving but not done
            int resolveCount = Math.max(1, active.size() / 2);
            toResolve = active.subList(0, resolveCount);
        }

        toResolve.forEach(Misconception::resolve);
        // Note: the caller already holds these objects; the caller's
        // computeAndSave will re-filter to isActive() after this returns.
        // Persistence of the resolved flags happens in computeAndSave via
        // the misconceptionRepository.saveAll call below.
    }

    // ── Core per-topic computation ────────────────────────────────────────────

    /**
     * Computes and upserts a {@link LearningAnalytics} document for one topic.
     *
     * <h3>4-component mastery formula</h3>
     * <pre>
     *   latestScore   (40 %)  — score of the most-recent quiz attempt
     *   recentAvg     (30 %)  — average of the 3 most-recent attempts
     *   activePenalty (20 %)  — 100 − min(activeMisconceptions × 10, 100)
     *   consistency   (10 %)  — min(completedSessions × 25, 100)
     *
     *   masteryScore = round(latestScore×0.40 + recentAvg×0.30
     *                        + activePenalty×0.20 + consistency×0.10)
     *   clamped to [0, 100]
     * </pre>
     *
     * <h3>Mastery levels</h3>
     * <pre>
     *   80–100  MASTERED
     *   60–79   PROFICIENT
     *   40–59   DEVELOPING
     *   0–39    BEGINNER
     * </pre>
     *
     * @param activeMisconceptions   only ACTIVE (unresolved) misconceptions
     * @param allMisconceptions      all (incl. resolved) — used to count total
     *                               historical misconceptions and weak areas
     */
    private void computeAndSave(String userId, String topicCode,
            List<QuizAttempt> topicAttempts,
            List<Misconception> activeMisconceptions,
            List<Misconception> allMisconceptions,
            List<LearningSession> topicSessions) {

        // ── Persist resolution changes ────────────────────────────────────────
        // Any misconceptions whose status changed to RESOLVED need to be saved.
        List<Misconception> resolved = allMisconceptions.stream()
                .filter(m -> m.getStatus() == MisconceptionStatus.RESOLVED
                        && m.getResolvedAt() != null
                        && m.getUpdatedAt() != null
                        && m.getResolvedAt().equals(m.getUpdatedAt()))
                .collect(Collectors.toList());
        if (!resolved.isEmpty()) {
            misconceptionRepository.saveAll(resolved);
        }

        // ── Completed sessions ────────────────────────────────────────────────
        int completedSessions = (int) topicSessions.stream()
                .filter(s -> s.getStatus() == SessionStatus.COMPLETED)
                .count();

        // ── Quiz performance ──────────────────────────────────────────────────
        // Attempts are already sorted newest-first by the repository query.
        int latestScore = topicAttempts.isEmpty() ? 0 : topicAttempts.get(0).getScore();
        int recentAvg = topicAttempts.isEmpty() ? 0
                : (int) Math.round(
                        topicAttempts.stream()
                                .limit(3)
                                .mapToInt(QuizAttempt::getScore)
                                .average()
                                .orElse(0));
        int averageQuizScore = topicAttempts.isEmpty() ? 0
                : (int) Math.round(topicAttempts.stream()
                        .mapToInt(QuizAttempt::getScore)
                        .average()
                        .orElse(0));

        // ── Misconception counts ──────────────────────────────────────────────
        int activeMisconceptionCount = activeMisconceptions.size();
        // Historical count includes resolved — shown in analytics graphs.
        int totalMisconceptionCount = allMisconceptions.size();

        // weakAreas: only from ACTIVE misconceptions — drives revision suggestions.
        List<String> weakAreas = activeMisconceptions.stream()
                .map(Misconception::getMisconceptionCode)
                .distinct()
                .sorted()
                .collect(Collectors.toList());

        // ── 4-component mastery score ─────────────────────────────────────────
        int activePenaltyComponent = 100 - Math.min(activeMisconceptionCount * 10, 100);
        int consistencyComponent   = Math.min(completedSessions * 25, 100);

        double raw = latestScore       * 0.40
                   + recentAvg         * 0.30
                   + activePenaltyComponent * 0.20
                   + consistencyComponent   * 0.10;
        int masteryScore = Math.min(100, Math.max(0, (int) Math.round(raw)));

        String masteryLevel   = calculateMasteryLevel(masteryScore);
        boolean recommendedPractice = masteryScore < 80 || activeMisconceptionCount > 0;

        // ── Personalized summary ──────────────────────────────────────────────
        String summary = buildPersonalizedSummary(topicCode, topicAttempts,
                latestScore, masteryScore, masteryLevel,
                activeMisconceptionCount, allMisconceptions.size() - activeMisconceptionCount);

        // ── Upsert ────────────────────────────────────────────────────────────
        LearningAnalytics analytics = analyticsRepository
                .findByUserIdAndTopicCode(userId, topicCode)
                .orElseGet(() -> {
                    LearningAnalytics a = new LearningAnalytics(userId, topicCode);
                    a.markCreated();
                    return a;
                });

        analytics.update(completedSessions, activeMisconceptionCount, averageQuizScore,
                masteryScore, masteryLevel, weakAreas, recommendedPractice, summary);
        analyticsRepository.save(analytics);
    }

    // ── Personalized summary ──────────────────────────────────────────────────

    public static String buildPersonalizedSummary(String topicCode,
            List<QuizAttempt> attempts,
            int latestScore, int masteryScore, String masteryLevel,
            int activeMisconceptions, int resolvedMisconceptions) {

        String topicLabel = formatTopicLabel(topicCode);

        if (attempts.isEmpty()) {
            return "No assessment data available for " + topicLabel + " yet. "
                    + "Complete an assessment to generate your personalised summary.";
        }

        StringBuilder sb = new StringBuilder();

        // Latest performance sentence
        if (latestScore == 100) {
            sb.append("You achieved a perfect score on the latest ")
              .append(topicLabel).append(" assessment — excellent work!");
        } else if (latestScore >= 80) {
            sb.append("You scored ").append(latestScore)
              .append("% on the latest ").append(topicLabel).append(" assessment. Strong performance.");
        } else if (latestScore >= 60) {
            sb.append("You scored ").append(latestScore)
              .append("% on the latest ").append(topicLabel).append(" assessment. Good progress.");
        } else {
            sb.append("You scored ").append(latestScore)
              .append("% on the latest ").append(topicLabel).append(" assessment.");
        }

        // Improvement sentence (requires at least 2 attempts)
        if (attempts.size() >= 2) {
            int previousScore = attempts.get(1).getScore();
            int delta = latestScore - previousScore;
            if (delta >= 20) {
                sb.append(" Excellent improvement — your score rose from ")
                  .append(previousScore).append("% to ").append(latestScore).append("%.");
            } else if (delta > 0) {
                sb.append(" Your score improved by ").append(delta).append(" points from the previous attempt.");
            } else if (delta < 0) {
                sb.append(" Your score dropped ").append(Math.abs(delta))
                  .append(" points from the previous attempt — reviewing the revision suggestions below will help.");
            }
        }

        // Resolved misconceptions
        if (resolvedMisconceptions > 0) {
            sb.append(" ").append(resolvedMisconceptions == 1
                    ? "One previously recorded misconception has been resolved."
                    : resolvedMisconceptions + " previously recorded misconceptions have been resolved.");
        }

        // Active misconceptions / encouragement
        if (activeMisconceptions > 0) {
            sb.append(" There ").append(activeMisconceptions == 1 ? "is" : "are")
              .append(" still ").append(activeMisconceptions)
              .append(activeMisconceptions == 1 ? " active misconception" : " active misconceptions")
              .append(" to address — see the revision suggestions below.");
        } else if (masteryScore >= 80) {
            sb.append(" No active misconceptions detected. Keep up the outstanding work!");
        }

        // Mastery-tier closing line
        sb.append(" Current mastery level: ").append(masteryLevel).append(".");

        return sb.toString();
    }

    // ── Mastery level ─────────────────────────────────────────────────────────

    /**
     * Maps a 0–100 mastery score to a named level.
     * <pre>
     *   80–100  MASTERED
     *   60–79   PROFICIENT
     *   40–59   DEVELOPING
     *   0–39    BEGINNER
     * </pre>
     */
    public static String calculateMasteryLevel(int masteryScore) {
        if (masteryScore >= 80) return "MASTERED";
        if (masteryScore >= 60) return "PROFICIENT";
        if (masteryScore >= 40) return "DEVELOPING";
        return "BEGINNER";
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private User getAuthenticatedUser(String email) {
        return userService.findByEmail(email)
                .orElseThrow(() -> new UnauthorizedException("Authenticated user no longer exists."));
    }

    private String normalizeTopicCode(String topicCode) {
        return topicCode.trim().toUpperCase();
    }

    /**
     * Converts "DSA_LINKED_LIST" → "Linked List" for human-readable summaries.
     */
    public static String formatTopicLabel(String topicCode) {
        String[] parts = topicCode.split("_");
        // Drop the leading domain prefix (DSA, ELECTRONICS, CHEMISTRY)
        int start = parts.length > 1 ? 1 : 0;
        StringBuilder sb = new StringBuilder();
        for (int i = start; i < parts.length; i++) {
            if (sb.length() > 0) sb.append(" ");
            String w = parts[i];
            sb.append(Character.toUpperCase(w.charAt(0)))
              .append(w.substring(1).toLowerCase());
        }
        return sb.length() > 0 ? sb.toString() : topicCode;
    }
}
