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

import com.arstem.backend.ai.domain.RevisionSuggestionResponse;
import com.arstem.backend.learninganalytics.domain.LearningAnalytics;
import com.arstem.backend.learninganalytics.repository.LearningAnalyticsRepository;
import com.arstem.backend.learninganalytics.service.LearningAnalyticsService;
import com.arstem.backend.misconception.domain.Misconception;
import com.arstem.backend.misconception.domain.MisconceptionStatus;
import com.arstem.backend.misconception.repository.MisconceptionRepository;
import com.arstem.backend.user.domain.Role;
import com.arstem.backend.user.domain.User;
import com.arstem.backend.user.domain.UserStatus;
import com.arstem.backend.user.service.UserService;

@ExtendWith(MockitoExtension.class)
class AIRevisionSuggestionServiceTest {

    @Mock private LearningAnalyticsRepository analyticsRepository;
    @Mock private MisconceptionRepository misconceptionRepository;
    @Mock private UserService userService;
    @InjectMocks private AIRevisionSuggestionService service;

    // ── Topic-scoped: ACTIVE-only misconceptions ──────────────────────────────

    @Test
    void activeMisconceptionsProduceRevisionActions() {
        when(userService.findByEmail("u@test.com")).thenReturn(Optional.of(user("u1")));
        when(analyticsRepository.findByUserId("u1"))
                .thenReturn(List.of(analytics("u1", "DSA_LINKED_LIST", 55, 35)));
        when(misconceptionRepository.findByUserIdAndTopicCodeAndStatusOrderByCreatedAtDesc(
                "u1", "DSA_LINKED_LIST", MisconceptionStatus.ACTIVE))
                .thenReturn(List.of(
                        misconception("u1", "DSA_LINKED_LIST"),
                        misconception("u1", "DSA_LINKED_LIST"),
                        misconception("u1", "DSA_LINKED_LIST"),
                        misconception("u1", "DSA_LINKED_LIST"),
                        misconception("u1", "DSA_LINKED_LIST"))); // 5 active

        RevisionSuggestionResponse r =
                service.getRevisionSuggestionsForTopic("u@test.com", "DSA_LINKED_LIST");

        assertThat(r.revisionTopics()).containsExactly("DSA_LINKED_LIST"); // lowMastery < 40
        assertThat(r.revisionActions()).anyMatch(a -> a.contains("active misconceptions"));
        assertThat(r.revisionActions()).anyMatch(a -> a.contains("quiz"));
        assertThat(r.reason()).contains("Linked List");
        assertThat(r.reason()).doesNotContain("DSA_LINKED_LIST"); // should use human label
    }

    @Test
    void resolvedMisconceptionsDoNotAppearInRevisionActions() {
        // All misconceptions are RESOLVED — the ACTIVE query returns empty.
        when(userService.findByEmail("u@test.com")).thenReturn(Optional.of(user("u1")));
        when(analyticsRepository.findByUserId("u1"))
                .thenReturn(List.of(analytics("u1", "DSA_LINKED_LIST", 90, 85)));
        when(misconceptionRepository.findByUserIdAndTopicCodeAndStatusOrderByCreatedAtDesc(
                "u1", "DSA_LINKED_LIST", MisconceptionStatus.ACTIVE))
                .thenReturn(List.of()); // nothing active

        RevisionSuggestionResponse r =
                service.getRevisionSuggestionsForTopic("u@test.com", "DSA_LINKED_LIST");

        assertThat(r.revisionTopics()).isEmpty();
        assertThat(r.revisionActions()).isEmpty();
        assertThat(r.reason()).isEqualTo("No revision needed — keep up the great work!");
    }

    @Test
    void masteredTopicWithNoActiveMisconceptionsProducesNoRevision() {
        when(userService.findByEmail("u@test.com")).thenReturn(Optional.of(user("u1")));
        when(analyticsRepository.findByUserId("u1"))
                .thenReturn(List.of(analytics("u1", "DSA_LINKED_LIST", 92, 88)));
        when(misconceptionRepository.findByUserIdAndTopicCodeAndStatusOrderByCreatedAtDesc(
                "u1", "DSA_LINKED_LIST", MisconceptionStatus.ACTIVE))
                .thenReturn(List.of());

        RevisionSuggestionResponse r =
                service.getRevisionSuggestionsForTopic("u@test.com", "DSA_LINKED_LIST");

        assertThat(r.revisionTopics()).isEmpty();
        assertThat(r.revisionActions()).isEmpty();
    }

    @Test
    void topicScopedNeverSurfacesOtherTopics() {
        // User has active misconceptions for DSA_STACK only.
        // The Linked List request must not see Stack data.
        when(userService.findByEmail("u@test.com")).thenReturn(Optional.of(user("u1")));
        when(analyticsRepository.findByUserId("u1")).thenReturn(List.of(
                analytics("u1", "DSA_LINKED_LIST", 90, 85), // MASTERED
                analytics("u1", "DSA_STACK", 30, 28)));     // BEGINNER
        // ACTIVE query for DSA_LINKED_LIST returns empty.
        when(misconceptionRepository.findByUserIdAndTopicCodeAndStatusOrderByCreatedAtDesc(
                "u1", "DSA_LINKED_LIST", MisconceptionStatus.ACTIVE))
                .thenReturn(List.of());

        RevisionSuggestionResponse r =
                service.getRevisionSuggestionsForTopic("u@test.com", "DSA_LINKED_LIST");

        assertThat(r.revisionTopics()).isEmpty();
        assertThat(r.revisionActions()).noneMatch(a -> a.contains("Stack"));
        assertThat(r.revisionActions()).noneMatch(a -> a.contains("DSA_STACK"));
    }

    @Test
    void beginnerMasteryAloneTriggersRevisionTopic() {
        // masteryScore=35 < 40 = BEGINNER = lowMastery → added to revisionTopics
        // avgQuizScore=50 < 60 → also triggers low-quiz action
        when(userService.findByEmail("u@test.com")).thenReturn(Optional.of(user("u1")));
        when(analyticsRepository.findByUserId("u1"))
                .thenReturn(List.of(analytics("u1", "DSA_LINKED_LIST", 50, 35)));
        when(misconceptionRepository.findByUserIdAndTopicCodeAndStatusOrderByCreatedAtDesc(
                "u1", "DSA_LINKED_LIST", MisconceptionStatus.ACTIVE))
                .thenReturn(List.of());

        RevisionSuggestionResponse r =
                service.getRevisionSuggestionsForTopic("u@test.com", "DSA_LINKED_LIST");

        assertThat(r.revisionTopics()).containsExactly("DSA_LINKED_LIST");
        // reason mentions BEGINNER mastery (plus possibly quiz performance)
        assertThat(r.reason()).containsAnyOf("BEGINNER", "low mastery");
    }

    @Test
    void lowQuizScoreAloneTriggersRetakeAction() {
        when(userService.findByEmail("u@test.com")).thenReturn(Optional.of(user("u1")));
        // masteryScore = 65 (PROFICIENT, not BEGINNER) but avgQuizScore = 55 (< 60)
        when(analyticsRepository.findByUserId("u1"))
                .thenReturn(List.of(analytics("u1", "DSA_LINKED_LIST", 55, 65)));
        when(misconceptionRepository.findByUserIdAndTopicCodeAndStatusOrderByCreatedAtDesc(
                "u1", "DSA_LINKED_LIST", MisconceptionStatus.ACTIVE))
                .thenReturn(List.of());

        RevisionSuggestionResponse r =
                service.getRevisionSuggestionsForTopic("u@test.com", "DSA_LINKED_LIST");

        // Not in revisionTopics (mastery >= 40) but retake action added.
        assertThat(r.revisionTopics()).isEmpty();
        assertThat(r.revisionActions()).anyMatch(a -> a.contains("quiz"));
        assertThat(r.reason()).contains("60%");
    }

    // ── Global path: active-only filter in memory ─────────────────────────────

    @Test
    void globalRevisionFiltersOutResolvedMisconceptions() {
        when(userService.findByEmail("u@test.com")).thenReturn(Optional.of(user("u1")));
        when(analyticsRepository.findByUserId("u1"))
                .thenReturn(List.of(analytics("u1", "DSA_LINKED_LIST", 90, 85)));

        Misconception resolved = misconception("u1", "DSA_LINKED_LIST");
        resolved.resolve();
        Misconception active = misconception("u1", "DSA_LINKED_LIST");

        when(misconceptionRepository.findByUserIdOrderByCreatedAtDesc("u1"))
                .thenReturn(List.of(resolved, active)); // mix of states

        RevisionSuggestionResponse r = service.getRevisionSuggestions("u@test.com");

        // Only 1 active → not > 3, so no "Review misconceptions" action.
        // masteryScore >= 80 → not lowMastery.
        // avgQuizScore >= 60 → not lowQuiz.
        // No actions should be generated.
        assertThat(r.revisionTopics()).isEmpty();
        assertThat(r.revisionActions()).noneMatch(a -> a.contains("Review the"));
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private static LearningAnalytics analytics(String userId, String topicCode,
            int avgQuiz, int mastery) {
        LearningAnalytics a = new LearningAnalytics(userId, topicCode);
        String level = LearningAnalyticsService.calculateMasteryLevel(mastery);
        a.update(1, 0, avgQuiz, mastery, level, List.of(), mastery < 80, "");
        return a;
    }

    private static Misconception misconception(String userId, String topicCode) {
        Misconception m = new Misconception(userId, "session-1", topicCode,
                "CODE", "Title", "", null);
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
