package com.arstem.backend.session.service;

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

import com.arstem.backend.common.exception.UnauthorizedException;
import com.arstem.backend.session.api.StartSessionRequest;
import com.arstem.backend.session.domain.LearningSession;
import com.arstem.backend.session.domain.SessionStatus;
import com.arstem.backend.session.repository.LearningSessionRepository;
import com.arstem.backend.user.domain.Role;
import com.arstem.backend.user.domain.User;
import com.arstem.backend.user.domain.UserStatus;
import com.arstem.backend.user.service.UserService;

@ExtendWith(MockitoExtension.class)
class LearningSessionServiceTest {

    @Mock
    private LearningSessionRepository learningSessionRepository;
    @Mock
    private UserService userService;
    @Captor
    private ArgumentCaptor<LearningSession> sessionCaptor;
    @InjectMocks
    private LearningSessionService learningSessionService;

    @Test
    void startsAnActiveSessionForAuthenticatedUser() {
        User user = user("user-1", "student@example.com");
        when(userService.findByEmail("student@example.com")).thenReturn(Optional.of(user));
        when(learningSessionRepository.save(any(LearningSession.class))).thenAnswer(invocation -> invocation.getArgument(0));

        LearningSession session = learningSessionService.startSession("student@example.com",
                new StartSessionRequest("DSA", "DSA_STACK", "STACK"));

        assertThat(session.getUserId()).isEqualTo("user-1");
        assertThat(session.getStatus()).isEqualTo(SessionStatus.ACTIVE);
        assertThat(session.getStartedAt()).isNotNull();
        assertThat(session.getCreatedAt()).isNotNull();
        verify(learningSessionRepository).save(sessionCaptor.capture());
        assertThat(sessionCaptor.getValue().getTopicCode()).isEqualTo("DSA_STACK");
    }

    @Test
    void endsOwnedSession() {
        User user = user("user-1", "student@example.com");
        LearningSession session = new LearningSession("user-1", "DSA", "DSA_STACK", "STACK");
        session.markCreated();
        when(userService.findByEmail("student@example.com")).thenReturn(Optional.of(user));
        when(learningSessionRepository.findById("session-1")).thenReturn(Optional.of(session));
        when(learningSessionRepository.save(session)).thenReturn(session);

        LearningSession completed = learningSessionService.endSession("student@example.com", "session-1");

        assertThat(completed.getStatus()).isEqualTo(SessionStatus.COMPLETED);
        assertThat(completed.getEndedAt()).isNotNull();
        verify(learningSessionRepository).save(session);
    }

    @Test
    void rejectsEndingAnotherUsersSession() {
        when(userService.findByEmail("student@example.com")).thenReturn(Optional.of(user("user-1", "student@example.com")));
        when(learningSessionRepository.findById("session-2"))
                .thenReturn(Optional.of(new LearningSession("user-2", "DSA", "DSA_STACK", "STACK")));

        assertThatThrownBy(() -> learningSessionService.endSession("student@example.com", "session-2"))
                .isInstanceOf(UnauthorizedException.class);
    }

    @Test
    void getsOnlyAuthenticatedUsersSessionsInRepositoryOrder() {
        User user = user("user-1", "student@example.com");
        LearningSession newest = new LearningSession("user-1", "DSA", "DSA_QUEUE", "QUEUE");
        LearningSession oldest = new LearningSession("user-1", "DSA", "DSA_STACK", "STACK");
        when(userService.findByEmail("student@example.com")).thenReturn(Optional.of(user));
        when(learningSessionRepository.findByUserIdOrderByStartedAtDesc("user-1")).thenReturn(List.of(newest, oldest));

        assertThat(learningSessionService.getMySessions("student@example.com")).containsExactly(newest, oldest);
        verify(learningSessionRepository).findByUserIdOrderByStartedAtDesc("user-1");
    }

    private User user(String id, String email) {
        User user = new User("Student", email, "hash", Set.of(Role.STUDENT), UserStatus.ACTIVE);
        setId(user, id);
        return user;
    }

    private void setId(User user, String id) {
        try {
            var field = User.class.getDeclaredField("id");
            field.setAccessible(true);
            field.set(user, id);
        } catch (ReflectiveOperationException exception) {
            throw new AssertionError(exception);
        }
    }
}
