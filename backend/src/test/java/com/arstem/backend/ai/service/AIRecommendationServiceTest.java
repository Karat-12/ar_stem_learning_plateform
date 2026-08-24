package com.arstem.backend.ai.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

import java.util.List;
import java.util.Optional;
import java.util.Set;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.arstem.backend.ai.domain.RecommendationResponse;
import com.arstem.backend.ai.domain.RecommendationType;
import com.arstem.backend.learninganalytics.domain.LearningAnalytics;
import com.arstem.backend.learninganalytics.repository.LearningAnalyticsRepository;
import com.arstem.backend.learninganalytics.service.LearningAnalyticsService;
import com.arstem.backend.misconception.domain.MisconceptionStatus;
import com.arstem.backend.misconception.repository.MisconceptionRepository;
import com.arstem.backend.progress.repository.ProgressRepository;
import com.arstem.backend.user.domain.Role;
import com.arstem.backend.user.domain.User;
import com.arstem.backend.user.domain.UserStatus;
import com.arstem.backend.user.service.UserService;

@ExtendWith(MockitoExtension.class)
class AIRecommendationServiceTest {

    @Mock private ProgressRepository progressRepository;
    @Mock private LearningAnalyticsRepository analyticsRepository;
    @Mock private MisconceptionRepository misconceptionRepository;
    @Mock private UserService userService;
    @InjectMocks private AIRecommendationService service;

    // ── Tier-based static helper ──────────────────────────────────────────────

    @Test
    void masteredWithNoActiveMisconceptionsReturnsNextTopic() {
        RecommendationResponse r =
                AIRecommendationService.tierRecommendation("DSA_LINKED_LIST", 85, 0);
        assertThat(r.recommendationType()).isEqualTo(RecommendationType.NEXT_TOPIC);
        assertThat(r.reason()).contains("mastered");
        assertThat(r.reason()).contains("Linked List");
    }

    @Test
    void proficientReturnsQuizPractice() {
        RecommendationResponse r =
                AIRecommendationService.tierRecommendation("DSA_LINKED_LIST", 70, 0);
        assertThat(r.recommendationType()).isEqualTo(RecommendationType.QUIZ_PRACTICE);
        assertThat(r.reason()).contains("insertion and deletion");
    }

    @Test
    void developingReturnsRevision() {
        RecommendationResponse r =
                AIRecommendationService.tierRecommendation("DSA_LINKED_LIST", 50, 0);
        assertThat(r.recommendationType()).isEqualTo(RecommendationType.REVISION);
        assertThat(r.reason()).contains("Repeat the assessment");
    }

    @Test
    void beginnerReturnsPractice() {
        RecommendationResponse r =
                AIRecommendationService.tierRecommendation("DSA_LINKED_LIST", 30, 0);
        assertThat(r.recommendationType()).isEqualTo(RecommendationType.PRACTICE);
        assertThat(r.reason()).contains("learning workspace");
    }

    @Test
    void activeMisconceptionsAlwaysOverrideTierWithRevision() {
        // Even a MASTERED score should produce REVISION when active misconceptions exist.
        RecommendationResponse r =
                AIRecommendationService.tierRecommendation("DSA_LINKED_LIST", 90, 3);
        assertThat(r.recommendationType()).isEqualTo(RecommendationType.REVISION);
        assertThat(r.reason()).contains("3 active misconception");
    }

    // ── Topic-scoped service method ───────────────────────────────────────────

    @Test
    void topicScopedReturnsNextTopicForMasteredWithNoActiveMisconceptions() {
        when(userService.findByEmail("u@test.com")).thenReturn(Optional.of(user("u1")));
        when(analyticsRepository.findByUserId("u1"))
                .thenReturn(List.of(analytics("u1", "DSA_LINKED_LIST", 90, 85)));
        when(progressRepository.findByUserId("u1")).thenReturn(List.of());
        when(misconceptionRepository.findByUserIdAndTopicCodeAndStatusOrderByCreatedAtDesc(
                "u1", "DSA_LINKED_LIST", MisconceptionStatus.ACTIVE))
                .thenReturn(List.of());

        RecommendationResponse r =
                service.getRecommendationForTopic("u@test.com", "DSA_LINKED_LIST");

        assertThat(r).isNotNull();
        assertThat(r.topicCode()).isEqualTo("DSA_LINKED_LIST");
        assertThat(r.recommendationType()).isEqualTo(RecommendationType.NEXT_TOPIC);
    }

    @Test
    void topicScopedReturnsRevisionWhenActiveMisconceptionsExist() {
        when(userService.findByEmail("u@test.com")).thenReturn(Optional.of(user("u1")));
        when(analyticsRepository.findByUserId("u1"))
                .thenReturn(List.of(analytics("u1", "DSA_LINKED_LIST", 90, 85)));
        when(progressRepository.findByUserId("u1")).thenReturn(List.of());
        when(misconceptionRepository.findByUserIdAndTopicCodeAndStatusOrderByCreatedAtDesc(
                "u1", "DSA_LINKED_LIST", MisconceptionStatus.ACTIVE))
                .thenReturn(List.of(
                        misconception("u1", "DSA_LINKED_LIST"),
                        misconception("u1", "DSA_LINKED_LIST")));

        RecommendationResponse r =
                service.getRecommendationForTopic("u@test.com", "DSA_LINKED_LIST");

        assertThat(r.recommendationType()).isEqualTo(RecommendationType.REVISION);
        assertThat(r.reason()).contains("active misconception");
    }

    @Test
    void topicScopedReturnsNullWhenNoData() {
        when(userService.findByEmail("u@test.com")).thenReturn(Optional.of(user("u1")));
        when(analyticsRepository.findByUserId("u1")).thenReturn(List.of());
        when(progressRepository.findByUserId("u1")).thenReturn(List.of());

        RecommendationResponse r =
                service.getRecommendationForTopic("u@test.com", "DSA_LINKED_LIST");

        assertThat(r).isNull();
    }

    @Test
    void topicScopedNeverReturnsDataForOtherTopics() {
        // User has MASTERED Binary Tree; Linked List is DEVELOPING.
        // Linked List recommendation must never say "move to next topic"
        // because that applies to Binary Tree, not Linked List.
        when(userService.findByEmail("u@test.com")).thenReturn(Optional.of(user("u1")));
        when(analyticsRepository.findByUserId("u1")).thenReturn(List.of(
                analytics("u1", "DSA_LINKED_LIST", 55, 48),    // DEVELOPING
                analytics("u1", "DSA_BINARY_TREE", 92, 88)));  // MASTERED
        when(progressRepository.findByUserId("u1")).thenReturn(List.of());
        when(misconceptionRepository.findByUserIdAndTopicCodeAndStatusOrderByCreatedAtDesc(
                "u1", "DSA_LINKED_LIST", MisconceptionStatus.ACTIVE))
                .thenReturn(List.of());

        RecommendationResponse r =
                service.getRecommendationForTopic("u@test.com", "DSA_LINKED_LIST");

        assertThat(r.topicCode()).isEqualTo("DSA_LINKED_LIST");
        assertThat(r.recommendationType()).isEqualTo(RecommendationType.REVISION);
        assertThat(r.reason()).doesNotContain("Binary Tree");
        assertThat(r.reason()).doesNotContain("DSA_BINARY_TREE");
    }

    @Test
    void topicScopedResolvedMisconceptionsDoNotTriggerRevision() {
        // All misconceptions are RESOLVED → mastery-tier rule should apply, not REVISION.
        when(userService.findByEmail("u@test.com")).thenReturn(Optional.of(user("u1")));
        when(analyticsRepository.findByUserId("u1"))
                .thenReturn(List.of(analytics("u1", "DSA_LINKED_LIST", 90, 85)));
        when(progressRepository.findByUserId("u1")).thenReturn(List.of());
        // ACTIVE query returns empty — all resolved.
        when(misconceptionRepository.findByUserIdAndTopicCodeAndStatusOrderByCreatedAtDesc(
                "u1", "DSA_LINKED_LIST", MisconceptionStatus.ACTIVE))
                .thenReturn(List.of());

        RecommendationResponse r =
                service.getRecommendationForTopic("u@test.com", "DSA_LINKED_LIST");

        assertThat(r.recommendationType()).isEqualTo(RecommendationType.NEXT_TOPIC);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private static LearningAnalytics analytics(String userId, String topicCode,
            int avgQuiz, int mastery) {
        LearningAnalytics a = new LearningAnalytics(userId, topicCode);
        String level = LearningAnalyticsService.calculateMasteryLevel(mastery);
        a.update(1, 0, avgQuiz, mastery, level, List.of(), mastery < 80, "");
        return a;
    }

    private static com.arstem.backend.misconception.domain.Misconception
            misconception(String userId, String topicCode) {
        com.arstem.backend.misconception.domain.Misconception m =
                new com.arstem.backend.misconception.domain.Misconception(
                        userId, "session-1", topicCode, "CODE", "Title", "", null);
        m.markCreated();
        return m;
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
