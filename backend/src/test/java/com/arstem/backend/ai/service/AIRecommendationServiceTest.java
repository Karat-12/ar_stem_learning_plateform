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

import com.arstem.backend.ai.domain.RecommendationResponse;
import com.arstem.backend.learninganalytics.domain.LearningAnalytics;
import com.arstem.backend.learninganalytics.repository.LearningAnalyticsRepository;
import com.arstem.backend.misconception.domain.Misconception;
import com.arstem.backend.misconception.repository.MisconceptionRepository;
import com.arstem.backend.progress.domain.Progress;
import com.arstem.backend.progress.repository.ProgressRepository;
import com.arstem.backend.user.domain.Role;
import com.arstem.backend.user.domain.User;
import com.arstem.backend.user.domain.UserStatus;
import com.arstem.backend.user.service.UserService;

@ExtendWith(MockitoExtension.class)
class AIRecommendationServiceTest {

    @Mock
    private ProgressRepository progressRepository;
    @Mock
    private LearningAnalyticsRepository analyticsRepository;
    @Mock
    private MisconceptionRepository misconceptionRepository;
    @Mock
    private UserService userService;
    @InjectMocks
    private AIRecommendationService recommendationService;

    @Test
    void recommendsPracticeWhenLowMasteryScoreInAnalytics() {
        when(userService.findByEmail("student@example.com")).thenReturn(Optional.of(user("user-1")));
        LearningAnalytics analytics = new LearningAnalytics("user-1", "DSA_STACK");
        analytics.update(1, 1, 50, 45, "BEGINNER", List.of(), false);
        when(analyticsRepository.findByUserId("user-1")).thenReturn(List.of(analytics));
        when(progressRepository.findByUserId("user-1")).thenReturn(List.of());
        when(misconceptionRepository.findByUserIdOrderByCreatedAtDesc("user-1")).thenReturn(List.of());

        List<RecommendationResponse> responses = recommendationService.getRecommendations("student@example.com");

        assertThat(responses).hasSize(1);
        assertThat(responses.get(0).recommendationType()).isEqualTo(com.arstem.backend.ai.domain.RecommendationType.PRACTICE);
    }

    @Test
    void recommendsNextTopicWhenMasteredAnalytics() {
        when(userService.findByEmail("student@example.com")).thenReturn(Optional.of(user("user-1")));
        LearningAnalytics analytics = new LearningAnalytics("user-1", "DSA_STACK");
        analytics.update(1, 1, 85, 90, "ADVANCED", List.of(), false);
        when(analyticsRepository.findByUserId("user-1")).thenReturn(List.of(analytics));
        when(progressRepository.findByUserId("user-1")).thenReturn(List.of());
        when(misconceptionRepository.findByUserIdOrderByCreatedAtDesc("user-1")).thenReturn(List.of());

        List<RecommendationResponse> responses = recommendationService.getRecommendations("student@example.com");

        assertThat(responses).hasSize(1);
        assertThat(responses.get(0).recommendationType()).isEqualTo(com.arstem.backend.ai.domain.RecommendationType.NEXT_TOPIC);
    }

    @Test
    void recommendsRevisionWhenMisconceptionsAboveThreshold() {
        when(userService.findByEmail("student@example.com")).thenReturn(Optional.of(user("user-1")));
        when(analyticsRepository.findByUserId("user-1")).thenReturn(List.of());
        when(progressRepository.findByUserId("user-1")).thenReturn(List.of());
        when(misconceptionRepository.findByUserIdOrderByCreatedAtDesc("user-1"))
                .thenReturn(List.of(
                        new Misconception("user-1", "session-1", "DSA_STACK", "M1", "Title", "", null),
                        new Misconception("user-1", "session-1", "DSA_STACK", "M2", "Title", "", null),
                        new Misconception("user-1", "session-1", "DSA_STACK", "M3", "Title", "", null),
                        new Misconception("user-1", "session-1", "DSA_STACK", "M4", "Title", "", null)));

        List<RecommendationResponse> responses = recommendationService.getRecommendations("student@example.com");

        assertThat(responses).hasSize(1);
        assertThat(responses.get(0).recommendationType()).isEqualTo(com.arstem.backend.ai.domain.RecommendationType.REVISION);
    }

    @Test
    void recommendsQuizPracticeWhenLowAverageScoreInAnalytics() {
        when(userService.findByEmail("student@example.com")).thenReturn(Optional.of(user("user-1")));
        LearningAnalytics analytics = new LearningAnalytics("user-1", "DSA_STACK");
        analytics.update(1, 1, 55, 65, "INTERMEDIATE", List.of(), false);
        when(analyticsRepository.findByUserId("user-1")).thenReturn(List.of(analytics));
        when(progressRepository.findByUserId("user-1")).thenReturn(List.of());
        when(misconceptionRepository.findByUserIdOrderByCreatedAtDesc("user-1")).thenReturn(List.of());

        List<RecommendationResponse> responses = recommendationService.getRecommendations("student@example.com");

        assertThat(responses).hasSize(1);
        assertThat(responses.get(0).recommendationType()).isEqualTo(com.arstem.backend.ai.domain.RecommendationType.QUIZ_PRACTICE);
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
