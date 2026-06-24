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

import com.arstem.backend.ai.domain.FeedbackResponse;
import com.arstem.backend.learninganalytics.domain.LearningAnalytics;
import com.arstem.backend.learninganalytics.repository.LearningAnalyticsRepository;
import com.arstem.backend.misconception.domain.Misconception;
import com.arstem.backend.misconception.repository.MisconceptionRepository;
import com.arstem.backend.user.domain.Role;
import com.arstem.backend.user.domain.User;
import com.arstem.backend.user.domain.UserStatus;
import com.arstem.backend.user.service.UserService;

@ExtendWith(MockitoExtension.class)
class AIFeedbackServiceTest {

    @Mock
    private LearningAnalyticsRepository analyticsRepository;
    @Mock
    private MisconceptionRepository misconceptionRepository;
    @Mock
    private UserService userService;
    @InjectMocks
    private AIFeedbackService feedbackService;

    @Test
    void generatesFeedbackForStrongAndWeakTopics() {
        when(userService.findByEmail("student@example.com")).thenReturn(Optional.of(user("user-1")));

        LearningAnalytics strongTopic = new LearningAnalytics("user-1", "DSA_STACK");
        strongTopic.update(2, 0, 85, 90, "ADVANCED", List.of(), false);
        LearningAnalytics weakTopic = new LearningAnalytics("user-1", "DSA_LINKED_LIST");
        weakTopic.update(1, 4, 55, 45, "BEGINNER", List.of(), true);

        when(analyticsRepository.findByUserId("user-1")).thenReturn(List.of(strongTopic, weakTopic));
        when(misconceptionRepository.findByUserIdOrderByCreatedAtDesc("user-1")).thenReturn(List.of(
                new Misconception("user-1", "session-1", "DSA_LINKED_LIST", "M1", "Title", "", null),
                new Misconception("user-1", "session-1", "DSA_LINKED_LIST", "M2", "Title", "", null),
                new Misconception("user-1", "session-1", "DSA_LINKED_LIST", "M3", "Title", "", null),
                new Misconception("user-1", "session-1", "DSA_LINKED_LIST", "M4", "Title", "", null)));

        FeedbackResponse feedback = feedbackService.getFeedback("student@example.com");

        assertThat(feedback.feedback()).containsExactly(
                "You are performing strongly in DSA_STACK.",
                "Your mastery score for DSA_LINKED_LIST is below target.",
                "You encountered multiple misconceptions in DSA_LINKED_LIST.",
                "Your quiz performance in DSA_LINKED_LIST needs improvement.");
    }

    @Test
    void returnsDefaultFeedbackWhenNoAnalytics() {
        when(userService.findByEmail("student@example.com")).thenReturn(Optional.of(user("user-1")));
        when(analyticsRepository.findByUserId("user-1")).thenReturn(List.of());
        when(misconceptionRepository.findByUserIdOrderByCreatedAtDesc("user-1")).thenReturn(List.of());

        FeedbackResponse feedback = feedbackService.getFeedback("student@example.com");

        assertThat(feedback.feedback()).containsExactly(
                "Keep learning. More activity is needed to generate personalized feedback.");
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
