package com.arstem.backend.ai.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

import java.util.List;
import java.util.Optional;
import java.util.Set;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.arstem.backend.ai.domain.LearningInsightsResponse;
import com.arstem.backend.learninganalytics.domain.LearningAnalytics;
import com.arstem.backend.learninganalytics.repository.LearningAnalyticsRepository;
import com.arstem.backend.learninganalytics.service.LearningAnalyticsService;
import com.arstem.backend.misconception.repository.MisconceptionRepository;
import com.arstem.backend.progress.repository.ProgressRepository;
import com.arstem.backend.quiz.domain.QuizAttempt;
import com.arstem.backend.quiz.repository.QuizAttemptRepository;
import com.arstem.backend.user.domain.Role;
import com.arstem.backend.user.domain.User;
import com.arstem.backend.user.domain.UserStatus;
import com.arstem.backend.user.service.UserService;

@ExtendWith(MockitoExtension.class)
class AILearningInsightsServiceTest {

    @Mock private ProgressRepository progressRepository;
    @Mock private LearningAnalyticsRepository analyticsRepository;
    @Mock private MisconceptionRepository misconceptionRepository;
    @Mock private QuizAttemptRepository quizAttemptRepository;
    @Mock private UserService userService;
    @InjectMocks private AILearningInsightsService service;

    // ── Global insights ───────────────────────────────────────────────────────

    @Test
    void returnsNoDataSummaryWhenNoAnalytics() {
        when(userService.findByEmail("u@test.com")).thenReturn(Optional.of(user("u1")));
        when(analyticsRepository.findByUserId("u1")).thenReturn(List.of());

        LearningInsightsResponse r = service.getLearningInsights("u@test.com");

        assertThat(r.strengths()).isEmpty();
        assertThat(r.weaknesses()).isEmpty();
        assertThat(r.totalTopicsLearned()).isEqualTo(0);
        assertThat(r.summary()).contains("No learning data available yet");
    }

    @Test
    void masteredTopicAppearsInStrengths() {
        when(userService.findByEmail("u@test.com")).thenReturn(Optional.of(user("u1")));
        when(analyticsRepository.findByUserId("u1"))
                .thenReturn(List.of(analytics("u1", "DSA_LINKED_LIST", 90, 85)));

        LearningInsightsResponse r = service.getLearningInsights("u@test.com");

        assertThat(r.strengths()).containsExactly("DSA_LINKED_LIST");
        assertThat(r.weaknesses()).isEmpty();
    }

    @Test
    void beginnerTopicAppearsInWeaknesses() {
        // < 40 = BEGINNER = weakness
        when(userService.findByEmail("u@test.com")).thenReturn(Optional.of(user("u1")));
        when(analyticsRepository.findByUserId("u1"))
                .thenReturn(List.of(analytics("u1", "DSA_LINKED_LIST", 30, 35)));

        LearningInsightsResponse r = service.getLearningInsights("u@test.com");

        assertThat(r.weaknesses()).containsExactly("DSA_LINKED_LIST");
        assertThat(r.strengths()).isEmpty();
    }

    @Test
    void proficientTopicIsNeitherStrengthNorWeakness() {
        // 60–79 = PROFICIENT — not a strength (< 80) and not a weakness (>= 40)
        when(userService.findByEmail("u@test.com")).thenReturn(Optional.of(user("u1")));
        when(analyticsRepository.findByUserId("u1"))
                .thenReturn(List.of(analytics("u1", "DSA_LINKED_LIST", 70, 65)));

        LearningInsightsResponse r = service.getLearningInsights("u@test.com");

        assertThat(r.strengths()).isEmpty();
        assertThat(r.weaknesses()).isEmpty();
        assertThat(r.totalTopicsLearned()).isEqualTo(1);
    }

    @Test
    void globalSummaryAllMastered() {
        when(userService.findByEmail("u@test.com")).thenReturn(Optional.of(user("u1")));
        when(analyticsRepository.findByUserId("u1")).thenReturn(List.of(
                analytics("u1", "DSA_LINKED_LIST", 90, 85),
                analytics("u1", "DSA_STACK", 92, 88)));

        LearningInsightsResponse r = service.getLearningInsights("u@test.com");

        assertThat(r.summary()).contains("mastered all 2");
    }

    // ── Topic-scoped insights ─────────────────────────────────────────────────

    @Test
    void topicScopedInsightsNeverShowOtherTopics() {
        when(userService.findByEmail("u@test.com")).thenReturn(Optional.of(user("u1")));
        // User has two topics — only DSA_LINKED_LIST should appear.
        when(analyticsRepository.findByUserId("u1")).thenReturn(List.of(
                analytics("u1", "DSA_LINKED_LIST", 90, 85),  // MASTERED
                analytics("u1", "DSA_STACK", 30, 30)));        // BEGINNER

        LearningInsightsResponse r =
                service.getLearningInsightsForTopic("u@test.com", "DSA_LINKED_LIST");

        assertThat(r.strengths()).containsExactly("DSA_LINKED_LIST");
        assertThat(r.weaknesses()).isEmpty();
        assertThat(r.totalTopicsLearned()).isEqualTo(1);
        // DSA_STACK must not appear anywhere in the response.
        assertThat(r.summary()).doesNotContain("DSA_STACK");
        assertThat(r.summary()).doesNotContain("STACK");
    }

    @Test
    void topicScopedInsightsUsePrecomputedSummaryFromAnalytics() {
        when(userService.findByEmail("u@test.com")).thenReturn(Optional.of(user("u1")));
        LearningAnalytics a = analyticsWithSummary("u1", "DSA_LINKED_LIST", 90, 85,
                "You achieved a perfect score on the latest Linked List assessment.");
        when(analyticsRepository.findByUserId("u1")).thenReturn(List.of(a));

        LearningInsightsResponse r =
                service.getLearningInsightsForTopic("u@test.com", "DSA_LINKED_LIST");

        assertThat(r.summary()).contains("perfect score");
        assertThat(r.summary()).contains("Linked List");
    }

    @Test
    void topicScopedInsightsReturnEmptyWhenNoDataForTopic() {
        when(userService.findByEmail("u@test.com")).thenReturn(Optional.of(user("u1")));
        when(analyticsRepository.findByUserId("u1"))
                .thenReturn(List.of(analytics("u1", "DSA_STACK", 80, 82)));

        LearningInsightsResponse r =
                service.getLearningInsightsForTopic("u@test.com", "DSA_LINKED_LIST");

        assertThat(r.strengths()).isEmpty();
        assertThat(r.weaknesses()).isEmpty();
        assertThat(r.totalTopicsLearned()).isEqualTo(0);
        assertThat(r.summary()).contains("No learning data available yet");
    }

    @Test
    void topicScopedNormalizesTopicCodeToUpperCase() {
        when(userService.findByEmail("u@test.com")).thenReturn(Optional.of(user("u1")));
        when(analyticsRepository.findByUserId("u1"))
                .thenReturn(List.of(analytics("u1", "DSA_LINKED_LIST", 90, 85)));

        // Send lowercase — should still match.
        LearningInsightsResponse r =
                service.getLearningInsightsForTopic("u@test.com", "dsa_linked_list");

        assertThat(r.totalTopicsLearned()).isEqualTo(1);
    }

    // ── Practice topics (active misconceptions or low quiz) ───────────────────

    @Test
    void topicWithActiveMisconceptionsAppearsInPracticeTopics() {
        when(userService.findByEmail("u@test.com")).thenReturn(Optional.of(user("u1")));
        // misconceptionCount > 0 → practiceTopics
        LearningAnalytics a = analytics("u1", "DSA_LINKED_LIST", 70, 65);
        // default analytics helper sets misconceptionCount=0; we need non-zero
        LearningAnalytics withMisconceptions = analyticsWithActiveMisconceptions(
                "u1", "DSA_LINKED_LIST", 70, 65, 2);
        when(analyticsRepository.findByUserId("u1")).thenReturn(List.of(withMisconceptions));

        LearningInsightsResponse r = service.getLearningInsights("u@test.com");

        assertThat(r.topicsNeedingPractice()).containsExactly("DSA_LINKED_LIST");
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private static LearningAnalytics analytics(String userId, String topicCode,
            int avgQuizScore, int masteryScore) {
        LearningAnalytics a = new LearningAnalytics(userId, topicCode);
        String level = LearningAnalyticsService.calculateMasteryLevel(masteryScore);
        a.update(1, 0, avgQuizScore, masteryScore, level, List.of(), masteryScore < 80, "");
        return a;
    }

    private static LearningAnalytics analyticsWithSummary(String userId, String topicCode,
            int avgQuizScore, int masteryScore, String summary) {
        LearningAnalytics a = new LearningAnalytics(userId, topicCode);
        String level = LearningAnalyticsService.calculateMasteryLevel(masteryScore);
        a.update(1, 0, avgQuizScore, masteryScore, level, List.of(), masteryScore < 80, summary);
        return a;
    }

    private static LearningAnalytics analyticsWithActiveMisconceptions(String userId,
            String topicCode, int avgQuizScore, int masteryScore, int activeMisconceptions) {
        LearningAnalytics a = new LearningAnalytics(userId, topicCode);
        String level = LearningAnalyticsService.calculateMasteryLevel(masteryScore);
        a.update(1, activeMisconceptions, avgQuizScore, masteryScore, level,
                List.of("WEAK_AREA"), masteryScore < 80, "");
        return a;
    }

    private static User user(String id) {
        User u = new User("Student", "u@test.com", "hash",
                Set.of(Role.STUDENT), UserStatus.ACTIVE);
        try {
            var f = User.class.getDeclaredField("id");
            f.setAccessible(true);
            f.set(u, id);
        } catch (ReflectiveOperationException e) {
            throw new AssertionError(e);
        }
        return u;
    }
}
