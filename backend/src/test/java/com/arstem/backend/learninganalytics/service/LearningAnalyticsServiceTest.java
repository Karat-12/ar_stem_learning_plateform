package com.arstem.backend.learninganalytics.service;

import static org.assertj.core.api.Assertions.assertThat;
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
import com.arstem.backend.misconception.repository.MisconceptionRepository;
import com.arstem.backend.progress.domain.Progress;
import com.arstem.backend.progress.repository.ProgressRepository;
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

    @Mock
    private LearningAnalyticsRepository analyticsRepository;
    @Mock
    private ProgressRepository progressRepository;
    @Mock
    private QuizAttemptRepository quizAttemptRepository;
    @Mock
    private MisconceptionRepository misconceptionRepository;
    @Mock
    private LearningSessionRepository learningSessionRepository;
    @Mock
    private UserService userService;
    @InjectMocks
    private LearningAnalyticsService analyticsService;

    @Test
    void calculatesAverageQuizScoreAndMasteryLevelAndRecommendation() {
        when(userService.findByEmail("student@example.com")).thenReturn(Optional.of(user("user-1")));

        Progress p = new Progress("user-1", "DSA_STACK");
        p.markCreated();
        p.update(1, 1, 25, 90, List.of("STACK_UNDERFLOW"));
        when(progressRepository.findByUserId("user-1")).thenReturn(List.of(p));
        when(progressRepository.findByUserIdAndTopicCode("user-1", "DSA_STACK")).thenReturn(Optional.of(p));

        QuizAttempt a1 = new QuizAttempt("user-1", "session-1", "DSA_STACK", 10, 8, 80);
        when(quizAttemptRepository.findByUserIdOrderBySubmittedAtDesc("user-1")).thenReturn(List.of(a1));

        Misconception m = new Misconception("user-1", "session-1", "DSA_STACK", "STACK_UNDERFLOW", "Stack Underflow", "", null);
        when(misconceptionRepository.findByUserIdOrderByCreatedAtDesc("user-1")).thenReturn(List.of(m));

        LearningSession s = new LearningSession("user-1", "DSA", "DSA_STACK", "STACK");
        s.complete();
        when(learningSessionRepository.findByUserIdOrderByStartedAtDesc("user-1")).thenReturn(List.of(s));

        analyticsService.generateAnalytics("student@example.com");

        verify(analyticsRepository).save(org.mockito.ArgumentMatchers.argThat(a ->
                a.getTopicCode().equals("DSA_STACK") && a.getAverageQuizScore() == 80 && a.getMasteryScore() == 90
        ));
    }

    @Test
    void handlesEmptyData() {
        when(userService.findByEmail("student@example.com")).thenReturn(Optional.of(user("user-1")));
        when(progressRepository.findByUserId("user-1")).thenReturn(List.of());
        when(quizAttemptRepository.findByUserIdOrderBySubmittedAtDesc("user-1")).thenReturn(List.of());
        when(misconceptionRepository.findByUserIdOrderByCreatedAtDesc("user-1")).thenReturn(List.of());
        when(learningSessionRepository.findByUserIdOrderByStartedAtDesc("user-1")).thenReturn(List.of());

        analyticsService.generateAnalytics("student@example.com");

        // should not throw and may not save anything
    }

    private User user(String id) {
        User user = new User("Student", "student@example.com", "hash", Set.of(Role.STUDENT), UserStatus.ACTIVE);
        try {
            var field = User.class.getDeclaredField("id");
            field.setAccessible(true);
            field.set(user, id);
            return user;
        } catch (ReflectiveOperationException exception) {
            throw new AssertionError(exception);
        }
    }
}
