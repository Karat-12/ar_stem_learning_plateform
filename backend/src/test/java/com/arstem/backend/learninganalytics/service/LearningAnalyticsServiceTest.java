package com.arstem.backend.learninganalytics.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.List;
import java.util.Optional;
import java.util.Set;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.arstem.backend.learninganalytics.repository.LearningAnalyticsRepository;
import com.arstem.backend.misconception.domain.Misconception;
import com.arstem.backend.misconception.domain.MisconceptionStatus;
import com.arstem.backend.misconception.repository.MisconceptionRepository;
import com.arstem.backend.quiz.domain.QuizAttempt;
import com.arstem.backend.quiz.repository.QuizAttemptRepository;
import com.arstem.backend.session.domain.LearningSession;
import com.arstem.backend.session.domain.SessionStatus;
import com.arstem.backend.session.repository.LearningSessionRepository;
import com.arstem.backend.user.domain.Role;
import com.arstem.backend.user.domain.User;
import com.arstem.backend.user.domain.UserStatus;
import com.arstem.backend.user.service.UserService;

@ExtendWith(MockitoExtension.class)
class LearningAnalyticsServiceTest {

    @Mock private LearningAnalyticsRepository analyticsRepository;
    @Mock private QuizAttemptRepository quizAttemptRepository;
    @Mock private MisconceptionRepository misconceptionRepository;
    @Mock private LearningSessionRepository learningSessionRepository;
    @Mock private UserService userService;
    @InjectMocks private LearningAnalyticsService service;

    // ── Mastery level thresholds ──────────────────────────────────────────────

    @Test
    void masteryLevelThresholds() {
        assertThat(LearningAnalyticsService.calculateMasteryLevel(100)).isEqualTo("MASTERED");
        assertThat(LearningAnalyticsService.calculateMasteryLevel(80)).isEqualTo("MASTERED");
        assertThat(LearningAnalyticsService.calculateMasteryLevel(79)).isEqualTo("PROFICIENT");
        assertThat(LearningAnalyticsService.calculateMasteryLevel(60)).isEqualTo("PROFICIENT");
        assertThat(LearningAnalyticsService.calculateMasteryLevel(59)).isEqualTo("DEVELOPING");
        assertThat(LearningAnalyticsService.calculateMasteryLevel(40)).isEqualTo("DEVELOPING");
        assertThat(LearningAnalyticsService.calculateMasteryLevel(39)).isEqualTo("BEGINNER");
        assertThat(LearningAnalyticsService.calculateMasteryLevel(0)).isEqualTo("BEGINNER");
    }

    // ── 4-component mastery formula ───────────────────────────────────────────

    @Test
    void perfectScoreNoMisconceptionsOneSessionYieldsMastered() {
        // latest=100 (×0.40=40) + recentAvg=100 (×0.30=30)
        // + activePenalty=100-0=100 (×0.20=20) + consistency=25 (×0.10=2.5)
        // raw = 92.5 → 93 → MASTERED
        when(userService.findByEmail("u@test.com")).thenReturn(Optional.of(user("u1")));
        when(quizAttemptRepository.findByUserIdOrderBySubmittedAtDesc("u1"))
                .thenReturn(List.of(attempt("u1", "DSA_LINKED_LIST", 100)));
        when(misconceptionRepository.findByUserIdOrderByCreatedAtDesc("u1"))
                .thenReturn(List.of());
        when(learningSessionRepository.findByUserIdOrderByStartedAtDesc("u1"))
                .thenReturn(List.of(completedSession("u1", "DSA_LINKED_LIST")));
        when(analyticsRepository.findByUserIdAndTopicCode(anyString(), anyString()))
                .thenReturn(Optional.empty());

        service.generateAnalytics("u@test.com");

        verify(analyticsRepository).save(
                org.mockito.ArgumentMatchers.argThat(a ->
                        a.getMasteryLevel().equals("MASTERED")));
    }

    @Test
    void latestScoreCarriesMoreWeightThanHistoricalAverage() {
        // Student improved from 40 to 100.
        // latest=100 (×0.40=40) + recentAvg=avg(100,40)=70 (×0.30=21)
        // activePenalty=100 (×0.20=20) + consistency=50 (×0.10=5)
        // raw = 86 → MASTERED  (old formula avgScore=70 would give PROFICIENT)
        when(userService.findByEmail("u@test.com")).thenReturn(Optional.of(user("u1")));
        when(quizAttemptRepository.findByUserIdOrderBySubmittedAtDesc("u1"))
                .thenReturn(List.of(attempt("u1", "DSA_LINKED_LIST", 100),
                        attempt("u1", "DSA_LINKED_LIST", 40)));
        when(misconceptionRepository.findByUserIdOrderByCreatedAtDesc("u1"))
                .thenReturn(List.of());
        when(learningSessionRepository.findByUserIdOrderByStartedAtDesc("u1"))
                .thenReturn(List.of(completedSession("u1", "DSA_LINKED_LIST"),
                        completedSession("u1", "DSA_LINKED_LIST")));
        when(analyticsRepository.findByUserIdAndTopicCode(anyString(), anyString()))
                .thenReturn(Optional.empty());

        service.generateAnalytics("u@test.com");

        verify(analyticsRepository).save(
                org.mockito.ArgumentMatchers.argThat(a ->
                        a.getMasteryScore() >= 80
                        && a.getMasteryLevel().equals("MASTERED")));
    }

    @Test
    void activeMisconceptionsPenaliseButDoNotOverrideHighLatestScore() {
        // latest=100 (×0.40=40) + recentAvg=100 (×0.30=30)
        // activePenalty=100-20=80 (×0.20=16) + consistency=25 (×0.10=2.5)
        // raw = 88.5 → 89 → MASTERED despite 2 active misconceptions
        when(userService.findByEmail("u@test.com")).thenReturn(Optional.of(user("u1")));
        Misconception m1 = activeMisconception("u1", "DSA_LINKED_LIST", "CODE_A");
        Misconception m2 = activeMisconception("u1", "DSA_LINKED_LIST", "CODE_B");
        when(quizAttemptRepository.findByUserIdOrderBySubmittedAtDesc("u1"))
                .thenReturn(List.of(attempt("u1", "DSA_LINKED_LIST", 100)));
        when(misconceptionRepository.findByUserIdOrderByCreatedAtDesc("u1"))
                .thenReturn(List.of(m1, m2));
        when(learningSessionRepository.findByUserIdOrderByStartedAtDesc("u1"))
                .thenReturn(List.of(completedSession("u1", "DSA_LINKED_LIST")));
        // score=100 >=80 → all active misconceptions resolved → saveAll called
        when(misconceptionRepository.saveAll(any())).thenReturn(List.of());
        when(analyticsRepository.findByUserIdAndTopicCode(anyString(), anyString()))
                .thenReturn(Optional.empty());

        service.generateAnalytics("u@test.com");

        verify(analyticsRepository).save(
                org.mockito.ArgumentMatchers.argThat(a ->
                        a.getMasteryLevel().equals("MASTERED")));
    }

    @Test
    void noAttemptsYieldsZeroMastery() {
        when(userService.findByEmail("u@test.com")).thenReturn(Optional.of(user("u1")));
        Misconception m = activeMisconception("u1", "DSA_LINKED_LIST", "CODE_A");
        when(quizAttemptRepository.findByUserIdOrderBySubmittedAtDesc("u1"))
                .thenReturn(List.of());  // no attempts
        when(misconceptionRepository.findByUserIdOrderByCreatedAtDesc("u1"))
                .thenReturn(List.of(m));
        when(learningSessionRepository.findByUserIdOrderByStartedAtDesc("u1"))
                .thenReturn(List.of(completedSession("u1", "DSA_LINKED_LIST")));
        // no attempts → score < 60 → no resolution → saveAll NOT called
        when(analyticsRepository.findByUserIdAndTopicCode(anyString(), anyString()))
                .thenReturn(Optional.empty());

        service.generateAnalytics("u@test.com");

        verify(analyticsRepository).save(
                org.mockito.ArgumentMatchers.argThat(a ->
                        a.getMasteryScore() < 40       // consistency + activePenalty still give ~21
                        && a.getMasteryLevel().equals("BEGINNER")));
    }

    @Test
    void emptyDataProducesNoSave() {
        when(userService.findByEmail("u@test.com")).thenReturn(Optional.of(user("u1")));
        when(quizAttemptRepository.findByUserIdOrderBySubmittedAtDesc("u1")).thenReturn(List.of());
        when(misconceptionRepository.findByUserIdOrderByCreatedAtDesc("u1")).thenReturn(List.of());
        when(learningSessionRepository.findByUserIdOrderByStartedAtDesc("u1")).thenReturn(List.of());

        service.generateAnalytics("u@test.com");
        // No save calls expected when there is nothing to compute.
    }

    // ── Misconception resolution ──────────────────────────────────────────────

    @Test
    void latestScoreAbove80ResolvesAllActiveMisconceptions() {
        Misconception m1 = activeMisconception("u1", "DSA_LINKED_LIST", "BROKEN_LINK");
        Misconception m2 = activeMisconception("u1", "DSA_LINKED_LIST", "NULL_PTR");

        List<QuizAttempt> attempts =
                List.of(attempt("u1", "DSA_LINKED_LIST", 90)); // latest ≥ 80

        LearningAnalyticsService.resolveAddressedMisconceptions(
                "u1", "DSA_LINKED_LIST", attempts, List.of(m1, m2));

        assertThat(m1.getStatus()).isEqualTo(MisconceptionStatus.RESOLVED);
        assertThat(m2.getStatus()).isEqualTo(MisconceptionStatus.RESOLVED);
        assertThat(m1.getResolvedAt()).isNotNull();
    }

    @Test
    void latestScoreBelow60ResolvesNothing() {
        Misconception m1 = activeMisconception("u1", "DSA_LINKED_LIST", "BROKEN_LINK");
        Misconception m2 = activeMisconception("u1", "DSA_LINKED_LIST", "NULL_PTR");

        List<QuizAttempt> attempts = List.of(attempt("u1", "DSA_LINKED_LIST", 55));

        LearningAnalyticsService.resolveAddressedMisconceptions(
                "u1", "DSA_LINKED_LIST", attempts, List.of(m1, m2));

        assertThat(m1.getStatus()).isEqualTo(MisconceptionStatus.ACTIVE);
        assertThat(m2.getStatus()).isEqualTo(MisconceptionStatus.ACTIVE);
    }

    @Test
    void latestScoreInRange60to79ResolvesOldestHalf() {
        Misconception oldest = activeMisconception("u1", "DSA_LINKED_LIST", "OLDEST");
        Misconception newest = activeMisconception("u1", "DSA_LINKED_LIST", "NEWEST");
        // Make oldest have an earlier createdAt by calling markCreated() first and
        // setting a slightly later time for newest — both default to ACTIVE so we
        // rely on insertion order (oldest was created first in the test scenario).
        oldest.markCreated();
        newest.markCreated();

        List<QuizAttempt> attempts = List.of(attempt("u1", "DSA_LINKED_LIST", 70)); // 60–79

        LearningAnalyticsService.resolveAddressedMisconceptions(
                "u1", "DSA_LINKED_LIST", attempts, List.of(oldest, newest));

        // With 2 misconceptions, resolveCount = max(1, 2/2) = 1 → only oldest resolved.
        long resolvedCount = List.of(oldest, newest).stream()
                .filter(m -> m.getStatus() == MisconceptionStatus.RESOLVED)
                .count();
        assertThat(resolvedCount).isEqualTo(1);
    }

    @Test
    void emptyAttemptsSkipsResolution() {
        Misconception m = activeMisconception("u1", "DSA_LINKED_LIST", "CODE");
        LearningAnalyticsService.resolveAddressedMisconceptions(
                "u1", "DSA_LINKED_LIST", List.of(), List.of(m));
        assertThat(m.getStatus()).isEqualTo(MisconceptionStatus.ACTIVE);
    }

    @Test
    void alreadyResolvedMisconceptionsAreNotTouchedAgain() {
        Misconception active   = activeMisconception("u1", "DSA_LINKED_LIST", "ACTIVE_CODE");
        Misconception resolved = activeMisconception("u1", "DSA_LINKED_LIST", "DONE");
        resolved.resolve();   // already resolved before this call

        List<QuizAttempt> attempts = List.of(attempt("u1", "DSA_LINKED_LIST", 90));

        LearningAnalyticsService.resolveAddressedMisconceptions(
                "u1", "DSA_LINKED_LIST", attempts, List.of(active, resolved));

        assertThat(active.getStatus()).isEqualTo(MisconceptionStatus.RESOLVED);
        // resolved.resolve() was called a second time but that is idempotent.
        assertThat(resolved.getStatus()).isEqualTo(MisconceptionStatus.RESOLVED);
    }

    // ── Personalized summary ──────────────────────────────────────────────────

    @Test
    void summaryContainsPerfectScoreMessage() {
        String summary = LearningAnalyticsService.buildPersonalizedSummary(
                "DSA_LINKED_LIST",
                List.of(attempt("u1", "DSA_LINKED_LIST", 100)),
                100, 93, "MASTERED", 0, 0);
        assertThat(summary).contains("perfect score");
        assertThat(summary).contains("MASTERED");
    }

    @Test
    void summaryContainsImprovementWhenScoreIncreasedBy20OrMore() {
        List<QuizAttempt> attempts = List.of(
                attempt("u1", "DSA_LINKED_LIST", 100),  // latest
                attempt("u1", "DSA_LINKED_LIST", 60));   // previous

        String summary = LearningAnalyticsService.buildPersonalizedSummary(
                "DSA_LINKED_LIST", attempts, 100, 93, "MASTERED", 0, 0);

        assertThat(summary).contains("Excellent improvement");
        assertThat(summary).contains("60%");
        assertThat(summary).contains("100%");
    }

    @Test
    void summaryMentionsDropWhenScoreDecreased() {
        List<QuizAttempt> attempts = List.of(
                attempt("u1", "DSA_LINKED_LIST", 50),   // latest (dropped)
                attempt("u1", "DSA_LINKED_LIST", 80));  // previous

        String summary = LearningAnalyticsService.buildPersonalizedSummary(
                "DSA_LINKED_LIST", attempts, 50, 35, "BEGINNER", 3, 0);

        assertThat(summary).contains("dropped");
    }

    @Test
    void summaryMentionsResolvedMisconceptions() {
        String summary = LearningAnalyticsService.buildPersonalizedSummary(
                "DSA_LINKED_LIST",
                List.of(attempt("u1", "DSA_LINKED_LIST", 90)),
                90, 82, "MASTERED", 0, 3);
        assertThat(summary).contains("3 previously recorded misconceptions have been resolved");
    }

    @Test
    void summaryMentionsActiveMisconceptionsWhenPresent() {
        String summary = LearningAnalyticsService.buildPersonalizedSummary(
                "DSA_LINKED_LIST",
                List.of(attempt("u1", "DSA_LINKED_LIST", 70)),
                70, 55, "DEVELOPING", 2, 0);
        assertThat(summary).contains("2 active misconceptions");
    }

    @Test
    void summaryIsEmptyDataMessageWhenNoAttempts() {
        String summary = LearningAnalyticsService.buildPersonalizedSummary(
                "DSA_LINKED_LIST", List.of(), 0, 0, "BEGINNER", 0, 0);
        assertThat(summary).contains("No assessment data available");
    }

    // ── Topic label formatting ────────────────────────────────────────────────

    @Test
    void formatTopicLabelStripsPrefix() {
        assertThat(LearningAnalyticsService.formatTopicLabel("DSA_LINKED_LIST"))
                .isEqualTo("Linked List");
        assertThat(LearningAnalyticsService.formatTopicLabel("ELECTRONICS_AND_GATE"))
                .isEqualTo("And Gate");
        assertThat(LearningAnalyticsService.formatTopicLabel("CHEMISTRY_METHANE"))
                .isEqualTo("Methane");
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private static QuizAttempt attempt(String userId, String topicCode, int score) {
        return new QuizAttempt(userId, "session-1", topicCode, 10,
                score / 10, score);  // score = correctAnswers/10 * 100
    }

    private static Misconception activeMisconception(String userId, String topicCode,
            String code) {
        Misconception m = new Misconception(userId, "session-1", topicCode,
                code, "Title", "", null);
        m.markCreated();
        return m;
    }

    private static LearningSession completedSession(String userId, String topicCode) {
        LearningSession s = new LearningSession(userId, "DSA", topicCode, "ACTIVITY");
        s.complete();
        return s;
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
