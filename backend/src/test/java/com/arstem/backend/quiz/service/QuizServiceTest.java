package com.arstem.backend.quiz.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.List;
import java.util.Optional;
import java.util.Set;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Captor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.arstem.backend.common.exception.ResourceNotFoundException;
import com.arstem.backend.common.exception.UnauthorizedException;
import com.arstem.backend.quiz.api.SubmitQuizRequest;
import com.arstem.backend.quiz.domain.QuizAttempt;
import com.arstem.backend.quiz.repository.QuizAttemptRepository;
import com.arstem.backend.session.domain.LearningSession;
import com.arstem.backend.session.repository.LearningSessionRepository;
import com.arstem.backend.user.domain.Role;
import com.arstem.backend.user.domain.User;
import com.arstem.backend.user.domain.UserStatus;
import com.arstem.backend.user.service.UserService;

@ExtendWith(MockitoExtension.class)
class QuizServiceTest {

    @Mock
    private QuizAttemptRepository quizAttemptRepository;
    @Mock
    private LearningSessionRepository learningSessionRepository;
    @Mock
    private UserService userService;
    @Captor
    private ArgumentCaptor<QuizAttempt> attemptCaptor;
    @InjectMocks
    private QuizService quizService;

    @Test
    void calculatesScore() {
        assertThat(QuizService.calculateScore(10, 10)).isEqualTo(100);
        assertThat(QuizService.calculateScore(8, 10)).isEqualTo(80);
        assertThat(QuizService.calculateScore(5, 10)).isEqualTo(50);
        assertThat(QuizService.calculateScore(0, 10)).isEqualTo(0);
    }

    @Test
    void submitsQuizForOwnedSession() {
        authenticate("user-1");
        when(learningSessionRepository.findById("session-1"))
            .thenReturn(Optional.of(new LearningSession("user-1", "DSA", "DSA_STACK", "STACK")));
        when(quizAttemptRepository.save(any(QuizAttempt.class))).thenAnswer(invocation -> invocation.getArgument(0));

        int score = quizService.submitQuiz("student@example.com", new SubmitQuizRequest("session-1", "DSA_STACK", 10, 8));

        assertThat(score).isEqualTo(80);
        verify(quizAttemptRepository).save(attemptCaptor.capture());
        QuizAttempt saved = attemptCaptor.getValue();
        assertThat(saved.getUserId()).isEqualTo("user-1");
        assertThat(saved.getScore()).isEqualTo(80);
        assertThat(saved.getSubmittedAt()).isNotNull();
    }

    @Test
    void getsMyAttemptsInRepoOrder() {
        authenticate("user-1");
        QuizAttempt newest = new QuizAttempt("user-1", "session-2", "DSA_STACK", 10, 9, 90);
        QuizAttempt oldest = new QuizAttempt("user-1", "session-1", "DSA_STACK", 10, 8, 80);
        when(quizAttemptRepository.findByUserIdOrderBySubmittedAtDesc("user-1")).thenReturn(List.of(newest, oldest));

        assertThat(quizService.getMyAttempts("student@example.com")).containsExactly(newest, oldest);
        verify(quizAttemptRepository).findByUserIdOrderBySubmittedAtDesc("user-1");
    }

    @Test
    void getsTopicAttemptsFiltered() {
        authenticate("user-1");
        QuizAttempt a = new QuizAttempt("user-1", "session-1", "DSA_STACK", 10, 7, 70);
        when(quizAttemptRepository.findByUserIdAndTopicCodeOrderBySubmittedAtDesc("user-1", "DSA_STACK"))
                .thenReturn(List.of(a));

        assertThat(quizService.getTopicAttempts("student@example.com", "DSA_STACK")).containsExactly(a);
        verify(quizAttemptRepository).findByUserIdAndTopicCodeOrderBySubmittedAtDesc("user-1", "DSA_STACK");
    }

    @Test
    void rejectsAccessToAnotherUsersSession() {
        authenticate("user-1");
        when(learningSessionRepository.findById("session-2"))
                .thenReturn(Optional.of(new LearningSession("user-2", "DSA", "DSA_STACK", "STACK")));

        assertThatThrownBy(() -> quizService.submitQuiz("student@example.com", new SubmitQuizRequest("session-2", "DSA_STACK", 10, 8)))
                .isInstanceOf(UnauthorizedException.class);
    }

    @Test
    void rejectsUnknownSession() {
        authenticate("user-1");
        when(learningSessionRepository.findById("unknown-session")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> quizService.submitQuiz("student@example.com", new SubmitQuizRequest("unknown-session", "DSA_STACK", 10, 8)))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void rejectsInvalidTotalQuestions() {
        authenticate("user-1");
        when(learningSessionRepository.findById("session-1"))
            .thenReturn(Optional.of(new LearningSession("user-1", "DSA", "DSA_STACK", "STACK")));

        assertThatThrownBy(() -> quizService.submitQuiz("student@example.com", new SubmitQuizRequest("session-1", "DSA_STACK", 0, 0)))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void rejectsInvalidCorrectAnswers() {
        authenticate("user-1");
        when(learningSessionRepository.findById("session-1"))
            .thenReturn(Optional.of(new LearningSession("user-1", "DSA", "DSA_STACK", "STACK")));

        assertThatThrownBy(() -> quizService.submitQuiz("student@example.com", new SubmitQuizRequest("session-1", "DSA_STACK", 10, -1)))
                .isInstanceOf(IllegalArgumentException.class);

        assertThatThrownBy(() -> quizService.submitQuiz("student@example.com", new SubmitQuizRequest("session-1", "DSA_STACK", 10, 11)))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void emptyResultsWhenNoAttempts() {
        authenticate("user-1");
        when(quizAttemptRepository.findByUserIdOrderBySubmittedAtDesc("user-1")).thenReturn(List.of());

        assertThat(quizService.getMyAttempts("student@example.com")).isEmpty();
    }

    private void authenticate(String userId) {
        when(userService.findByEmail("student@example.com")).thenReturn(Optional.of(user(userId)));
    }

    

    // clean user builder
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
