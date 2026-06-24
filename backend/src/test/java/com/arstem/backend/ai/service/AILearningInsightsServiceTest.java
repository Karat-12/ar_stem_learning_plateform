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

import com.arstem.backend.ai.domain.LearningInsightsResponse;
import com.arstem.backend.learninganalytics.domain.LearningAnalytics;
import com.arstem.backend.learninganalytics.repository.LearningAnalyticsRepository;
import com.arstem.backend.user.domain.Role;
import com.arstem.backend.user.domain.User;
import com.arstem.backend.user.domain.UserStatus;
import com.arstem.backend.user.service.UserService;

@ExtendWith(MockitoExtension.class)
class AILearningInsightsServiceTest {

    @Mock
    private LearningAnalyticsRepository analyticsRepository;
    @Mock
    private UserService userService;
    @InjectMocks
    private AILearningInsightsService learningInsightsService;

    @Test
    void returnsNoDataSummaryWhenNoAnalytics() {
        when(userService.findByEmail("student@example.com")).thenReturn(Optional.of(user("user-1")));
        when(analyticsRepository.findByUserId("user-1")).thenReturn(List.of());

        LearningInsightsResponse response = learningInsightsService.getLearningInsights("student@example.com");

        assertThat(response.strengths()).isEmpty();
        assertThat(response.weaknesses()).isEmpty();
        assertThat(response.topicsNeedingPractice()).isEmpty();
        assertThat(response.totalTopicsLearned()).isEqualTo(0);
        assertThat(response.averageMasteryScore()).isEqualTo(0.0);
        assertThat(response.summary()).isEqualTo("No learning data available yet.");
    }

    @Test
    void returnsStrengthsAndWeaknessesSummary() {
        when(userService.findByEmail("student@example.com")).thenReturn(Optional.of(user("user-1")));
        LearningAnalytics strong = new LearningAnalytics("user-1", "DSA_STACK");
        strong.update(2, 0, 80, 90, "ADVANCED", List.of(), false);
        LearningAnalytics weak = new LearningAnalytics("user-1", "DSA_LINKED_LIST");
        weak.update(1, 1, 45, 40, "BEGINNER", List.of(), true);
        when(analyticsRepository.findByUserId("user-1")).thenReturn(List.of(strong, weak));

        LearningInsightsResponse response = learningInsightsService.getLearningInsights("student@example.com");

        assertThat(response.strengths()).containsExactly("DSA_STACK");
        assertThat(response.weaknesses()).containsExactly("DSA_LINKED_LIST");
        assertThat(response.topicsNeedingPractice()).containsExactly("DSA_LINKED_LIST");
        assertThat(response.totalTopicsLearned()).isEqualTo(2);
        assertThat(response.averageMasteryScore()).isEqualTo(65.0);
        assertThat(response.summary()).isEqualTo("You are performing strongly in DSA_STACK but need more practice in DSA_LINKED_LIST.");
    }

    @Test
    void returnsStrongPerformanceSummaryWhenOnlyStrengths() {
        when(userService.findByEmail("student@example.com")).thenReturn(Optional.of(user("user-1")));
        LearningAnalytics strong = new LearningAnalytics("user-1", "DSA_STACK");
        strong.update(1, 0, 90, 95, "ADVANCED", List.of(), false);
        when(analyticsRepository.findByUserId("user-1")).thenReturn(List.of(strong));

        LearningInsightsResponse response = learningInsightsService.getLearningInsights("student@example.com");

        assertThat(response.summary()).isEqualTo("You are showing strong performance across your completed topics.");
    }

    @Test
    void returnsImproveWeakTopicsSummaryWhenOnlyWeaknesses() {
        when(userService.findByEmail("student@example.com")).thenReturn(Optional.of(user("user-1")));
        LearningAnalytics weak = new LearningAnalytics("user-1", "DSA_TREE");
        weak.update(1, 0, 55, 45, "BEGINNER", List.of(), true);
        when(analyticsRepository.findByUserId("user-1")).thenReturn(List.of(weak));

        LearningInsightsResponse response = learningInsightsService.getLearningInsights("student@example.com");

        assertThat(response.summary()).isEqualTo("You should focus on improving your weaker topics.");
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
