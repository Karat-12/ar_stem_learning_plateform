package com.arstem.backend.misconception.service;

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
import com.arstem.backend.misconception.api.RecordMisconceptionRequest;
import com.arstem.backend.misconception.domain.Misconception;
import com.arstem.backend.misconception.domain.MisconceptionSeverity;
import com.arstem.backend.misconception.repository.MisconceptionRepository;
import com.arstem.backend.session.domain.LearningSession;
import com.arstem.backend.session.repository.LearningSessionRepository;
import com.arstem.backend.user.domain.Role;
import com.arstem.backend.user.domain.User;
import com.arstem.backend.user.domain.UserStatus;
import com.arstem.backend.user.service.UserService;

@ExtendWith(MockitoExtension.class)
class MisconceptionServiceTest {

    @Mock
    private MisconceptionRepository misconceptionRepository;
    @Mock
    private LearningSessionRepository learningSessionRepository;
    @Mock
    private UserService userService;
    @Captor
    private ArgumentCaptor<Misconception> misconceptionCaptor;
    @InjectMocks
    private MisconceptionService misconceptionService;

    @Test
    void recordsMisconceptionForOwnedSession() {
        authenticate("user-1");
        when(learningSessionRepository.findById("session-1"))
                .thenReturn(Optional.of(new LearningSession("user-1", "DSA", "DSA_STACK", "STACK")));
        when(misconceptionRepository.save(any(Misconception.class))).thenAnswer(invocation -> invocation.getArgument(0));

        Misconception misconception = misconceptionService.recordMisconception("student@example.com", request("session-1"));

        assertThat(misconception.getUserId()).isEqualTo("user-1");
        assertThat(misconception.getSeverity()).isEqualTo(MisconceptionSeverity.MEDIUM);
        assertThat(misconception.getCreatedAt()).isNotNull();
        verify(misconceptionRepository).save(misconceptionCaptor.capture());
        assertThat(misconceptionCaptor.getValue().getMisconceptionCode()).isEqualTo("STACK_UNDERFLOW");
    }

    @Test
    void getsMyMisconceptionsInRepositoryOrder() {
        authenticate("user-1");
        Misconception newest = new Misconception("user-1", "session-2", "DSA_QUEUE", "QUEUE_EMPTY", "Empty Queue", "", MisconceptionSeverity.LOW);
        Misconception oldest = new Misconception("user-1", "session-1", "DSA_STACK", "STACK_UNDERFLOW", "Stack Underflow", "", MisconceptionSeverity.MEDIUM);
        when(misconceptionRepository.findByUserIdOrderByCreatedAtDesc("user-1")).thenReturn(List.of(newest, oldest));

        assertThat(misconceptionService.getMyMisconceptions("student@example.com")).containsExactly(newest, oldest);
        verify(misconceptionRepository).findByUserIdOrderByCreatedAtDesc("user-1");
    }

    @Test
    void getsMisconceptionsForOwnedSession() {
        authenticate("user-1");
        LearningSession session = new LearningSession("user-1", "DSA", "DSA_STACK", "STACK");
        Misconception misconception = new Misconception("user-1", "session-1", "DSA_STACK", "STACK_UNDERFLOW", "Stack Underflow", "", MisconceptionSeverity.MEDIUM);
        when(learningSessionRepository.findById("session-1")).thenReturn(Optional.of(session));
        when(misconceptionRepository.findBySessionId("session-1")).thenReturn(List.of(misconception));

        assertThat(misconceptionService.getSessionMisconceptions("student@example.com", "session-1"))
                .containsExactly(misconception);
    }

    @Test
    void rejectsAccessToAnotherUsersSession() {
        authenticate("user-1");
        when(learningSessionRepository.findById("session-2"))
                .thenReturn(Optional.of(new LearningSession("user-2", "DSA", "DSA_STACK", "STACK")));

        assertThatThrownBy(() -> misconceptionService.recordMisconception("student@example.com", request("session-2")))
                .isInstanceOf(UnauthorizedException.class);
    }

    @Test
    void rejectsUnknownSession() {
        authenticate("user-1");
        when(learningSessionRepository.findById("unknown-session")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> misconceptionService.getSessionMisconceptions("student@example.com", "unknown-session"))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    private void authenticate(String userId) {
        when(userService.findByEmail("student@example.com")).thenReturn(Optional.of(user(userId)));
    }

    private RecordMisconceptionRequest request(String sessionId) {
        return new RecordMisconceptionRequest(sessionId, "DSA_STACK", "STACK_UNDERFLOW", "Stack Underflow",
                "Student attempted POP on an empty stack.", MisconceptionSeverity.MEDIUM);
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
