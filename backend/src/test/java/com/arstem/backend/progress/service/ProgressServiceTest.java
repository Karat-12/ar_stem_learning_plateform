package com.arstem.backend.progress.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.times;
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
import com.arstem.backend.misconception.domain.Misconception;
import com.arstem.backend.misconception.domain.MisconceptionSeverity;
import com.arstem.backend.misconception.repository.MisconceptionRepository;
import com.arstem.backend.progress.domain.Progress;
import com.arstem.backend.progress.repository.ProgressRepository;
import com.arstem.backend.session.domain.LearningSession;
import com.arstem.backend.session.domain.SessionStatus;
import com.arstem.backend.session.repository.LearningSessionRepository;
import com.arstem.backend.user.domain.Role;
import com.arstem.backend.user.domain.User;
import com.arstem.backend.user.domain.UserStatus;
import com.arstem.backend.user.service.UserService;

@ExtendWith(MockitoExtension.class)
class ProgressServiceTest {

    @Mock private ProgressRepository progressRepository;
    @Mock private LearningSessionRepository learningSessionRepository;
    @Mock private MisconceptionRepository misconceptionRepository;
    @Mock private UserService userService;
    @Captor private ArgumentCaptor<Progress> progressCaptor;
    @InjectMocks private ProgressService progressService;

    @Test
    void calculatesCompletionPercentageWithOneHundredPercentCap() {
        assertThat(ProgressService.completionPercent(0)).isZero();
        assertThat(ProgressService.completionPercent(1)).isEqualTo(25);
        assertThat(ProgressService.completionPercent(3)).isEqualTo(75);
        assertThat(ProgressService.completionPercent(4)).isEqualTo(100);
        assertThat(ProgressService.completionPercent(10)).isEqualTo(100);
    }

    @Test
    void calculatesMasteryScoreWithZeroFloor() {
        assertThat(ProgressService.masteryScore(0)).isEqualTo(100);
        assertThat(ProgressService.masteryScore(1)).isEqualTo(90);
        assertThat(ProgressService.masteryScore(3)).isEqualTo(70);
        assertThat(ProgressService.masteryScore(10)).isZero();
    }

    @Test
    void generatesProgressAndExtractsUniqueWeakAreas() {
        authenticate();
        when(learningSessionRepository.findByUserIdOrderByStartedAtDesc("user-1"))
                .thenReturn(List.of(completedSession("DSA_STACK"), activeSession("DSA_STACK")));
        when(misconceptionRepository.findByUserIdOrderByCreatedAtDesc("user-1"))
                .thenReturn(List.of(misconception("DSA_STACK", "STACK_OVERFLOW"), misconception("DSA_STACK", "STACK_UNDERFLOW"),
                        misconception("DSA_STACK", "STACK_UNDERFLOW")));
        when(progressRepository.findByUserIdAndTopicCode("user-1", "DSA_STACK")).thenReturn(Optional.empty());
        when(progressRepository.save(any(Progress.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(progressRepository.findByUserId("user-1")).thenAnswer(invocation -> List.of());

        progressService.getMyProgress("student@example.com");

        verify(progressRepository).save(progressCaptor.capture());
        Progress progress = progressCaptor.getValue();
        assertThat(progress.getCompletedSessions()).isEqualTo(1);
        assertThat(progress.getMisconceptionCount()).isEqualTo(3);
        assertThat(progress.getCompletionPercent()).isEqualTo(25);
        assertThat(progress.getMasteryScore()).isEqualTo(70);
        assertThat(progress.getWeakAreas()).containsExactly("STACK_OVERFLOW", "STACK_UNDERFLOW");
    }

    @Test
    void returnsRequestedTopicAfterRegeneration() {
        authenticate();
        Progress progress = new Progress("user-1", "DSA_STACK");
        setupEmptySourceData();
        when(progressRepository.findByUserIdAndTopicCode("user-1", "DSA_STACK")).thenReturn(Optional.of(progress));

        assertThat(progressService.getTopicProgress("student@example.com", "dsa_stack")).isSameAs(progress);
    }

    @Test
    void handlesEmptyDataAndReportsMissingTopicProgress() {
        authenticate();
        setupEmptySourceData();
        when(progressRepository.findByUserId("user-1")).thenReturn(List.of());
        when(progressRepository.findByUserIdAndTopicCode("user-1", "UNKNOWN")).thenReturn(Optional.empty());

        assertThat(progressService.getMyProgress("student@example.com")).isEmpty();
        assertThatThrownBy(() -> progressService.getTopicProgress("student@example.com", "unknown"))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void updatesExistingProgressInsteadOfCreatingAnotherDocument() {
        authenticate();
        Progress existing = new Progress("user-1", "DSA_STACK");
        setupSourceDataForStack();
        when(progressRepository.findByUserIdAndTopicCode("user-1", "DSA_STACK")).thenReturn(Optional.of(existing));
        when(progressRepository.save(existing)).thenReturn(existing);
        when(progressRepository.findByUserId("user-1")).thenReturn(List.of(existing));

        progressService.getMyProgress("student@example.com");
        progressService.getMyProgress("student@example.com");

        verify(progressRepository, times(2)).save(existing);
        assertThat(existing.getCompletedSessions()).isEqualTo(1);
        assertThat(existing.getId()).isNull();
    }

    private void authenticate() {
        when(userService.findByEmail("student@example.com")).thenReturn(Optional.of(user()));
    }

    private void setupEmptySourceData() {
        when(learningSessionRepository.findByUserIdOrderByStartedAtDesc("user-1")).thenReturn(List.of());
        when(misconceptionRepository.findByUserIdOrderByCreatedAtDesc("user-1")).thenReturn(List.of());
    }

    private void setupSourceDataForStack() {
        when(learningSessionRepository.findByUserIdOrderByStartedAtDesc("user-1")).thenReturn(List.of(completedSession("DSA_STACK")));
        when(misconceptionRepository.findByUserIdOrderByCreatedAtDesc("user-1")).thenReturn(List.of());
    }

    private LearningSession completedSession(String topicCode) {
        LearningSession session = new LearningSession("user-1", "DSA", topicCode, "STACK");
        session.complete();
        return session;
    }

    private LearningSession activeSession(String topicCode) {
        return new LearningSession("user-1", "DSA", topicCode, "STACK");
    }

    private Misconception misconception(String topicCode, String code) {
        return new Misconception("user-1", "session-1", topicCode, code, "Title", "Description", MisconceptionSeverity.MEDIUM);
    }

    private User user() {
        User user = new User("Student", "student@example.com", "hash", Set.of(Role.STUDENT), UserStatus.ACTIVE);
        try {
            var field = User.class.getDeclaredField("id");
            field.setAccessible(true);
            field.set(user, "user-1");
            return user;
        } catch (ReflectiveOperationException exception) {
            throw new AssertionError(exception);
        }
    }
}
