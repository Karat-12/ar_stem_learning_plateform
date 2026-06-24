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

import com.arstem.backend.ai.domain.PriorityLevel;
import com.arstem.backend.ai.domain.StudyPlanResponse;
import com.arstem.backend.learninganalytics.domain.LearningAnalytics;
import com.arstem.backend.learninganalytics.repository.LearningAnalyticsRepository;
import com.arstem.backend.misconception.domain.Misconception;
import com.arstem.backend.misconception.repository.MisconceptionRepository;
import com.arstem.backend.user.domain.Role;
import com.arstem.backend.user.domain.User;
import com.arstem.backend.user.domain.UserStatus;
import com.arstem.backend.user.service.UserService;

@ExtendWith(MockitoExtension.class)
class AIStudyPlanServiceTest {

    @Mock
    private LearningAnalyticsRepository analyticsRepository;
    @Mock
    private MisconceptionRepository misconceptionRepository;
    @Mock
    private UserService userService;
    @InjectMocks
    private AIStudyPlanService studyPlanService;

    @Test
    void generatesHighPriorityPlanForLowMasteryWithMisconceptions() {
        when(userService.findByEmail("student@example.com")).thenReturn(Optional.of(user("user-1")));

        LearningAnalytics analytics = new LearningAnalytics("user-1", "DSA_LINKED_LIST");
        analytics.update(1, 4, 45, 40, "BEGINNER", List.of(), true);
        when(analyticsRepository.findByUserId("user-1")).thenReturn(List.of(analytics));
        when(misconceptionRepository.findByUserIdOrderByCreatedAtDesc("user-1")).thenReturn(List.of(
                new Misconception("user-1", "session-1", "DSA_LINKED_LIST", "M1", "Title", "", null),
                new Misconception("user-1", "session-1", "DSA_LINKED_LIST", "M2", "Title", "", null),
                new Misconception("user-1", "session-1", "DSA_LINKED_LIST", "M3", "Title", "", null),
                new Misconception("user-1", "session-1", "DSA_LINKED_LIST", "M4", "Title", "", null)));

        StudyPlanResponse response = studyPlanService.getStudyPlan("student@example.com");

        assertThat(response.todayTasks()).containsExactly(
                "Review DSA_LINKED_LIST concepts",
                "Complete DSA_LINKED_LIST practice activity",
                "Attempt DSA_LINKED_LIST quiz",
                "Review misconceptions for DSA_LINKED_LIST");
        assertThat(response.estimatedTimeMinutes()).isEqualTo(60);
        assertThat(response.priorityLevel()).isEqualTo(PriorityLevel.HIGH);
        assertThat(response.reason()).isEqualTo(
                "DSA_LINKED_LIST mastery score is below target and repeated misconceptions were detected.");
    }

    @Test
    void generatesMediumPriorityPlanForModerateMastery() {
        when(userService.findByEmail("student@example.com")).thenReturn(Optional.of(user("user-1")));

        LearningAnalytics analytics = new LearningAnalytics("user-1", "DSA_STACK");
        analytics.update(2, 1, 70, 65, "INTERMEDIATE", List.of(), false);
        when(analyticsRepository.findByUserId("user-1")).thenReturn(List.of(analytics));
        when(misconceptionRepository.findByUserIdOrderByCreatedAtDesc("user-1")).thenReturn(List.of());

        StudyPlanResponse response = studyPlanService.getStudyPlan("student@example.com");

        assertThat(response.todayTasks()).containsExactly(
                "Practice DSA_STACK",
                "Attempt quiz revision");
        assertThat(response.estimatedTimeMinutes()).isEqualTo(45);
        assertThat(response.priorityLevel()).isEqualTo(PriorityLevel.MEDIUM);
        assertThat(response.reason()).isEqualTo("DSA_STACK needs targeted practice to improve mastery.");
    }

    @Test
    void generatesLowPriorityPlanForHighMastery() {
        when(userService.findByEmail("student@example.com")).thenReturn(Optional.of(user("user-1")));

        LearningAnalytics analytics = new LearningAnalytics("user-1", "DSA_GRAPH");
        analytics.update(3, 0, 92, 85, "ADVANCED", List.of(), false);
        when(analyticsRepository.findByUserId("user-1")).thenReturn(List.of(analytics));
        when(misconceptionRepository.findByUserIdOrderByCreatedAtDesc("user-1")).thenReturn(List.of());

        StudyPlanResponse response = studyPlanService.getStudyPlan("student@example.com");

        assertThat(response.todayTasks()).containsExactly("Explore next topic after DSA_GRAPH");
        assertThat(response.estimatedTimeMinutes()).isEqualTo(30);
        assertThat(response.priorityLevel()).isEqualTo(PriorityLevel.LOW);
        assertThat(response.reason()).isEqualTo("DSA_GRAPH is ready for extension learning.");
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
