package com.arstem.backend.learninganalytics.service;

import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;

import com.arstem.backend.learninganalytics.api.LearningAnalyticsResponse;
import com.arstem.backend.learninganalytics.domain.LearningAnalytics;
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
import com.arstem.backend.user.domain.User;
import com.arstem.backend.user.service.UserService;

@Service
public class LearningAnalyticsService {

    private final LearningAnalyticsRepository analyticsRepository;
    private final ProgressRepository progressRepository;
    private final QuizAttemptRepository quizAttemptRepository;
    private final MisconceptionRepository misconceptionRepository;
    private final LearningSessionRepository learningSessionRepository;
    private final UserService userService;

    public LearningAnalyticsService(LearningAnalyticsRepository analyticsRepository, ProgressRepository progressRepository,
            QuizAttemptRepository quizAttemptRepository, MisconceptionRepository misconceptionRepository,
            LearningSessionRepository learningSessionRepository, UserService userService) {
        this.analyticsRepository = analyticsRepository;
        this.progressRepository = progressRepository;
        this.quizAttemptRepository = quizAttemptRepository;
        this.misconceptionRepository = misconceptionRepository;
        this.learningSessionRepository = learningSessionRepository;
        this.userService = userService;
    }

    public void generateAnalytics(String authenticatedEmail) {
        User user = getAuthenticatedUser(authenticatedEmail);
        String userId = user.getId();

        List<Progress> progresses = progressRepository.findByUserId(userId);
        List<QuizAttempt> attempts = quizAttemptRepository.findByUserIdOrderBySubmittedAtDesc(userId);
        List<Misconception> misconceptions = misconceptionRepository.findByUserIdOrderByCreatedAtDesc(userId);
        List<LearningSession> sessions = learningSessionRepository.findByUserIdOrderByStartedAtDesc(userId);

        Map<String, List<Progress>> progressByTopic = progresses.stream().collect(Collectors.groupingBy(Progress::getTopicCode));
        Map<String, List<QuizAttempt>> attemptsByTopic = attempts.stream().collect(Collectors.groupingBy(QuizAttempt::getTopicCode));
        Map<String, List<Misconception>> misconceptionsByTopic = misconceptions.stream().collect(Collectors.groupingBy(Misconception::getTopicCode));
        Map<String, List<LearningSession>> sessionsByTopic = sessions.stream().collect(Collectors.groupingBy(LearningSession::getTopicCode));

        Set<String> topicCodes = new TreeSet<>();
        topicCodes.addAll(progressByTopic.keySet());
        topicCodes.addAll(attemptsByTopic.keySet());
        topicCodes.addAll(misconceptionsByTopic.keySet());
        topicCodes.addAll(sessionsByTopic.keySet());

        for (String topicCode : topicCodes) {
            int completedSessions = (int) sessionsByTopic.getOrDefault(topicCode, List.of()).stream()
                    .filter(s -> s.getStatus() == SessionStatus.COMPLETED).count();
            int misconceptionCount = misconceptionsByTopic.getOrDefault(topicCode, List.of()).size();
            List<QuizAttempt> topicAttempts = attemptsByTopic.getOrDefault(topicCode, List.of());
            int averageQuizScore = topicAttempts.isEmpty() ? 0
                    : (int) topicAttempts.stream().mapToInt(QuizAttempt::getScore).average().orElse(0);

            int masteryScore = progressRepository.findByUserIdAndTopicCode(userId, topicCode).map(Progress::getMasteryScore)
                    .orElse(0);
            List<String> weakAreas = progressRepository.findByUserIdAndTopicCode(userId, topicCode)
                    .map(Progress::getWeakAreas).orElse(List.of());

            String masteryLevel = calculateMasteryLevel(masteryScore);
            boolean recommendedPractice = (masteryScore < 80) || (misconceptionCount > 3);

            LearningAnalytics analytics = analyticsRepository.findByUserIdAndTopicCode(userId, topicCode)
                    .orElseGet(() -> {
                        LearningAnalytics a = new LearningAnalytics(userId, topicCode);
                        a.markCreated();
                        return a;
                    });
            analytics.update(completedSessions, misconceptionCount, averageQuizScore, masteryScore, masteryLevel, weakAreas,
                    recommendedPractice);
            analyticsRepository.save(analytics);
        }
    }

    public List<LearningAnalytics> getMyAnalytics(String authenticatedEmail) {
        User user = getAuthenticatedUser(authenticatedEmail);
        generateAnalytics(authenticatedEmail);
        return analyticsRepository.findByUserId(user.getId());
    }

    public LearningAnalytics getTopicAnalytics(String authenticatedEmail, String topicCode) {
        User user = getAuthenticatedUser(authenticatedEmail);
        generateAnalytics(authenticatedEmail);
        return analyticsRepository.findByUserIdAndTopicCode(user.getId(), normalizeTopicCode(topicCode))
                .orElseThrow(() -> new RuntimeException("Analytics for topic '" + topicCode + "' not found."));
    }

    static String calculateMasteryLevel(int masteryScore) {
        if (masteryScore >= 85) return "ADVANCED";
        if (masteryScore >= 60) return "INTERMEDIATE";
        return "BEGINNER";
    }

    private User getAuthenticatedUser(String email) {
        return userService.findByEmail(email)
                .orElseThrow(() -> new com.arstem.backend.common.exception.UnauthorizedException("Authenticated user no longer exists."));
    }

    private String normalizeTopicCode(String topicCode) {
        return topicCode.trim().toUpperCase();
    }
}
