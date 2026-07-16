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
import com.arstem.backend.misconception.domain.Misconception;
import com.arstem.backend.misconception.repository.MisconceptionRepository;
import com.arstem.backend.user.domain.Role;
import com.arstem.backend.user.domain.User;
import com.arstem.backend.user.domain.UserStatus;
import com.arstem.backend.user.service.UserService;

@ExtendWith(MockitoExtension.class)
class AIRevisionSuggestionServiceTest {

    @Mock
    private LearningAnalyticsRepository analyticsRepository;
    @Mock
    private MisconceptionRepository misconceptionRepository;
    @Mock
    private UserService userService;
    @InjectMocks
    private AIRevisionSuggestionService revisionSuggestionService;

    @Test
    void generatesRevisionSuggestionsForLowMasteryAndMisconceptions() {
        when(userService.findByEmail("student@example.com")).thenReturn(Optional.of(user("user-1")));

        LearningAnalytics analytics = new LearningAnalytics("user-1", "DSA_LINKED_LIST");
        analytics.update(1, 4, 55, 45, "BEGINNER", List.of(), true);
        when(analyticsRepository.findByUserId("user-1")).thenReturn(List.of(analytics));
        when(misconceptionRepository.findByUserIdOrderByCreatedAtDesc("user-1")).thenReturn(List.of(
                new Misconception("user-1", "session-1", "DSA_LINKED_LIST", "M1", "Title", "", null),
                new Misconception("user-1", "session-1", "DSA_LINKED_LIST", "M2", "Title", "", null),
                new Misconception("user-1", "session-1", "DSA_LINKED_LIST", "M3", "Title", "", null),
                new Misconception("user-1", "session-1", "DSA_LINKED_LIST", "M4", "Title", "", null)));

        RevisionSuggestionResponse response = revisionSuggestionService.getRevisionSuggestions("student@example.com");

        assertThat(response.revisionTopics()).containsExactly("DSA_LINKED_LIST");
        assertThat(response.revisionActions()).containsExactly(
                "Review misconceptions for DSA_LINKED_LIST",
                "Retake quiz for DSA_LINKED_LIST");
        assertThat(response.estimatedRevisionTimeMinutes()).isEqualTo(20);
        assertThat(response.reason()).contains("repeated misconceptions");
    }

    @Test
    void generatesRevisionActionForLowQuizOnly() {
        when(userService.findByEmail("student@example.com")).thenReturn(Optional.of(user("user-1")));

        LearningAnalytics analytics = new LearningAnalytics("user-1", "DSA_STACK");
        analytics.update(2, 1, 55, 70, "INTERMEDIATE", List.of(), false);
        when(analyticsRepository.findByUserId("user-1")).thenReturn(List.of(analytics));
        when(misconceptionRepository.findByUserIdOrderByCreatedAtDesc("user-1")).thenReturn(List.of());

        RevisionSuggestionResponse response = revisionSuggestionService.getRevisionSuggestions("student@example.com");

        assertThat(response.revisionTopics()).isEmpty();
        assertThat(response.revisionActions()).containsExactly("Retake quiz for DSA_STACK");
        assertThat(response.estimatedRevisionTimeMinutes()).isEqualTo(0);
        assertThat(response.reason()).contains("quiz score is low");
    }

    @Test
    void returnsNoRevisionSuggestionsWhenNoCriteriaMet() {
        when(userService.findByEmail("student@example.com")).thenReturn(Optional.of(user("user-1")));

        LearningAnalytics analytics = new LearningAnalytics("user-1", "DSA_GRAPH");
        analytics.update(3, 0, 85, 90, "ADVANCED", List.of(), false);
        when(analyticsRepository.findByUserId("user-1")).thenReturn(List.of(analytics));
        when(misconceptionRepository.findByUserIdOrderByCreatedAtDesc("user-1")).thenReturn(List.of());

        RevisionSuggestionResponse response = revisionSuggestionService.getRevisionSuggestions("student@example.com");

        assertThat(response.revisionTopics()).isEmpty();
        assertThat(response.revisionActions()).isEmpty();
        assertThat(response.estimatedRevisionTimeMinutes()).isEqualTo(0);
        assertThat(response.reason()).isEqualTo("No revision suggestions available.");
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
