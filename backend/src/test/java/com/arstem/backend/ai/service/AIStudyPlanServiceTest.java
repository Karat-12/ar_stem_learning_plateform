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

import com.arstem.backend.ai.domain.PriorityLevel;
import com.arstem.backend.ai.domain.StudyPlanResponse;
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
class AIStudyPlanServiceTest {

    @Mock private LearningAnalyticsRepository analyticsRepository;
    @Mock private MisconceptionRepository misconceptionRepository;
    @Mock private UserService userService;
    @InjectMocks private AIStudyPlanService service;

    // ── BEGINNER tier (< 40) ──────────────────────────────────────────────────

    @Test
    void beginnerTierGeneratesLearnPracticeRetryTasks() {
        when(userService.findByEmail("u@test.com")).thenReturn(Optional.of(user("u1")));
        when(analyticsRepository.findByUserId("u1"))
                .thenReturn(List.of(analytics("u1", "DSA_LINKED_LIST", 35, 30)));
        when(misconceptionRepository.findByUserIdAndTopicCodeAndStatusOrderByCreatedAtDesc(
                "u1", "DSA_LINKED_LIST", MisconceptionStatus.ACTIVE))
                .thenReturn(List.of());

        StudyPlanResponse r = service.getStudyPlanForTopic("u@test.com", "DSA_LINKED_LIST");

        assertThat(r.todayTasks()).anyMatch(t -> t.contains("learning workspace"));
        assertThat(r.todayTasks()).anyMatch(t -> t.contains("AR practice"));
        assertThat(r.todayTasks()).anyMatch(t -> t.contains("Retry"));
        assertThat(r.priorityLevel()).isEqualTo(PriorityLevel.HIGH);
        assertThat(r.reason()).contains("BEGINNER");
    }

    // ── DEVELOPING tier (40–59) ───────────────────────────────────────────────

    @Test
    void developingTierGeneratesInsertionDeletionTasks() {
        when(userService.findByEmail("u@test.com")).thenReturn(Optional.of(user("u1")));
        when(analyticsRepository.findByUserId("u1"))
                .thenReturn(List.of(analytics("u1", "DSA_LINKED_LIST", 55, 48)));
        when(misconceptionRepository.findByUserIdAndTopicCodeAndStatusOrderByCreatedAtDesc(
                "u1", "DSA_LINKED_LIST", MisconceptionStatus.ACTIVE))
                .thenReturn(List.of());

        StudyPlanResponse r = service.getStudyPlanForTopic("u@test.com", "DSA_LINKED_LIST");

        assertThat(r.todayTasks()).anyMatch(t -> t.contains("insertion"));
        assertThat(r.todayTasks()).anyMatch(t -> t.contains("deletion"));
        assertThat(r.priorityLevel()).isEqualTo(PriorityLevel.HIGH);
        assertThat(r.reason()).contains("DEVELOPING");
    }

    // ── PROFICIENT tier (60–79) ───────────────────────────────────────────────

    @Test
    void proficientTierGeneratesChallengeAndTimedAssessmentTasks() {
        when(userService.findByEmail("u@test.com")).thenReturn(Optional.of(user("u1")));
        when(analyticsRepository.findByUserId("u1"))
                .thenReturn(List.of(analytics("u1", "DSA_LINKED_LIST", 72, 68)));
        when(misconceptionRepository.findByUserIdAndTopicCodeAndStatusOrderByCreatedAtDesc(
                "u1", "DSA_LINKED_LIST", MisconceptionStatus.ACTIVE))
                .thenReturn(List.of());

        StudyPlanResponse r = service.getStudyPlanForTopic("u@test.com", "DSA_LINKED_LIST");

        assertThat(r.todayTasks()).anyMatch(t -> t.contains("challenge mode"));
        assertThat(r.todayTasks()).anyMatch(t -> t.contains("timed"));
        assertThat(r.priorityLevel()).isEqualTo(PriorityLevel.MEDIUM);
        assertThat(r.reason()).contains("Proficient");
    }

    // ── MASTERED tier (≥ 80) ──────────────────────────────────────────────────

    @Test
    void masteredTierGeneratesStartNextTopicTask() {
        when(userService.findByEmail("u@test.com")).thenReturn(Optional.of(user("u1")));
        when(analyticsRepository.findByUserId("u1"))
                .thenReturn(List.of(analytics("u1", "DSA_LINKED_LIST", 90, 85)));
        when(misconceptionRepository.findByUserIdAndTopicCodeAndStatusOrderByCreatedAtDesc(
                "u1", "DSA_LINKED_LIST", MisconceptionStatus.ACTIVE))
                .thenReturn(List.of());

        StudyPlanResponse r = service.getStudyPlanForTopic("u@test.com", "DSA_LINKED_LIST");

        assertThat(r.todayTasks()).anyMatch(t -> t.contains("Start the next topic"));
        assertThat(r.priorityLevel()).isEqualTo(PriorityLevel.LOW);
        assertThat(r.estimatedTimeMinutes()).isEqualTo(30);
        assertThat(r.reason()).contains("Mastered");
    }

    // ── Active misconceptions raise priority and add tasks ────────────────────

    @Test
    void activeMisconceptionsAbove3RaisePriorityAndAddReviewTask() {
        when(userService.findByEmail("u@test.com")).thenReturn(Optional.of(user("u1")));
        // MASTERED score, but 4 active misconceptions.
        when(analyticsRepository.findByUserId("u1"))
                .thenReturn(List.of(analytics("u1", "DSA_LINKED_LIST", 88, 82)));
        when(misconceptionRepository.findByUserIdAndTopicCodeAndStatusOrderByCreatedAtDesc(
                "u1", "DSA_LINKED_LIST", MisconceptionStatus.ACTIVE))
                .thenReturn(List.of(
                        misconception("u1", "DSA_LINKED_LIST"),
                        misconception("u1", "DSA_LINKED_LIST"),
                        misconception("u1", "DSA_LINKED_LIST"),
                        misconception("u1", "DSA_LINKED_LIST")));

        StudyPlanResponse r = service.getStudyPlanForTopic("u@test.com", "DSA_LINKED_LIST");

        // Priority raised from LOW (MASTERED) to MEDIUM (4 misconceptions > 3).
        assertThat(r.priorityLevel()).isEqualTo(PriorityLevel.MEDIUM);
        assertThat(r.todayTasks()).anyMatch(t -> t.contains("Resolve 4 active misconceptions"));
    }

    @Test
    void resolvedMisconceptionsNeverAddTasksOrRaisePriority() {
        // The ACTIVE DB query returns empty — all misconceptions were resolved.
        when(userService.findByEmail("u@test.com")).thenReturn(Optional.of(user("u1")));
        when(analyticsRepository.findByUserId("u1"))
                .thenReturn(List.of(analytics("u1", "DSA_LINKED_LIST", 90, 85)));
        when(misconceptionRepository.findByUserIdAndTopicCodeAndStatusOrderByCreatedAtDesc(
                "u1", "DSA_LINKED_LIST", MisconceptionStatus.ACTIVE))
                .thenReturn(List.of()); // empty — all resolved

        StudyPlanResponse r = service.getStudyPlanForTopic("u@test.com", "DSA_LINKED_LIST");

        assertThat(r.priorityLevel()).isEqualTo(PriorityLevel.LOW); // not raised
        assertThat(r.todayTasks()).noneMatch(t -> t.contains("misconception"));
        assertThat(r.todayTasks()).anyMatch(t -> t.contains("Start the next topic"));
    }

    // ── Topic isolation ───────────────────────────────────────────────────────

    @Test
    void topicScopedPlanNeverSurfacesOtherTopics() {
        when(userService.findByEmail("u@test.com")).thenReturn(Optional.of(user("u1")));
        when(analyticsRepository.findByUserId("u1")).thenReturn(List.of(
                analytics("u1", "DSA_LINKED_LIST", 88, 82), // MASTERED
                analytics("u1", "DSA_STACK", 30, 28)));     // BEGINNER
        when(misconceptionRepository.findByUserIdAndTopicCodeAndStatusOrderByCreatedAtDesc(
                "u1", "DSA_LINKED_LIST", MisconceptionStatus.ACTIVE))
                .thenReturn(List.of());

        StudyPlanResponse r = service.getStudyPlanForTopic("u@test.com", "DSA_LINKED_LIST");

        assertThat(r.todayTasks()).noneMatch(t -> t.contains("Stack"));
        assertThat(r.todayTasks()).noneMatch(t -> t.contains("DSA_STACK"));
        assertThat(r.reason()).doesNotContain("Stack");
        assertThat(r.reason()).doesNotContain("DSA_STACK");
    }

    @Test
    void emptyDataReturnsEmptyPlan() {
        when(userService.findByEmail("u@test.com")).thenReturn(Optional.of(user("u1")));
        when(analyticsRepository.findByUserId("u1")).thenReturn(List.of());
        when(misconceptionRepository.findByUserIdAndTopicCodeAndStatusOrderByCreatedAtDesc(
                "u1", "DSA_LINKED_LIST", MisconceptionStatus.ACTIVE))
                .thenReturn(List.of());

        StudyPlanResponse r = service.getStudyPlanForTopic("u@test.com", "DSA_LINKED_LIST");

        assertThat(r.todayTasks()).isEmpty();
        assertThat(r.priorityLevel()).isEqualTo(PriorityLevel.LOW);
        assertThat(r.reason()).contains("No study plan");
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
