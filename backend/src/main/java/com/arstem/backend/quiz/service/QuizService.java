package com.arstem.backend.quiz.service;

import java.util.List;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;

import com.arstem.backend.common.exception.ResourceNotFoundException;
import com.arstem.backend.common.exception.UnauthorizedException;
import com.arstem.backend.quiz.api.SubmitQuizRequest;
import com.arstem.backend.quiz.domain.QuizAttempt;
import com.arstem.backend.quiz.repository.QuizAttemptRepository;
import com.arstem.backend.session.domain.LearningSession;
import com.arstem.backend.session.repository.LearningSessionRepository;
import com.arstem.backend.user.domain.User;
import com.arstem.backend.user.service.UserService;

@Service
public class QuizService {

    private final QuizAttemptRepository quizAttemptRepository;
    private final LearningSessionRepository learningSessionRepository;
    private final UserService userService;

    public QuizService(QuizAttemptRepository quizAttemptRepository, LearningSessionRepository learningSessionRepository,
            UserService userService) {
        this.quizAttemptRepository = quizAttemptRepository;
        this.learningSessionRepository = learningSessionRepository;
        this.userService = userService;
    }

    public int submitQuiz(String authenticatedEmail, SubmitQuizRequest request) {
        User user = getAuthenticatedUser(authenticatedEmail);
        verifySessionOwnership(request.sessionId(), user);

        if (request.totalQuestions() <= 0) {
            throw new IllegalArgumentException("totalQuestions must be greater than 0");
        }
        if (request.correctAnswers() < 0 || request.correctAnswers() > request.totalQuestions()) {
            throw new IllegalArgumentException("correctAnswers must be between 0 and totalQuestions");
        }

        int score = calculateScore(request.correctAnswers(), request.totalQuestions());
        QuizAttempt attempt = new QuizAttempt(user.getId(), request.sessionId().trim(), request.topicCode().trim(),
                request.totalQuestions(), request.correctAnswers(), score);
        attempt.markCreated();
        quizAttemptRepository.save(attempt);
        return score;
    }

    public List<QuizAttempt> getMyAttempts(String authenticatedEmail) {
        User user = getAuthenticatedUser(authenticatedEmail);
        return quizAttemptRepository.findByUserIdOrderBySubmittedAtDesc(user.getId());
    }

    public List<QuizAttempt> getTopicAttempts(String authenticatedEmail, String topicCode) {
        User user = getAuthenticatedUser(authenticatedEmail);
        String normalized = normalizeTopicCode(topicCode);
        return quizAttemptRepository.findByUserIdAndTopicCodeOrderBySubmittedAtDesc(user.getId(), normalized);
    }

    static int calculateScore(int correctAnswers, int totalQuestions) {
        if (totalQuestions == 0) return 0;
        return (correctAnswers * 100) / totalQuestions;
    }

    private User getAuthenticatedUser(String email) {
        return userService.findByEmail(email)
                .orElseThrow(() -> new UnauthorizedException("Authenticated user no longer exists."));
    }

    private void verifySessionOwnership(String sessionId, User user) {
        LearningSession session = learningSessionRepository.findById(sessionId)
                .orElseThrow(() -> new ResourceNotFoundException("Learning session with id '" + sessionId + "' was not found."));
        if (!session.getUserId().equals(user.getId())) {
            throw new UnauthorizedException("You are not authorized to access this learning session.");
        }
    }

    private String normalizeTopicCode(String topicCode) {
        return topicCode.trim().toUpperCase();
    }
}
