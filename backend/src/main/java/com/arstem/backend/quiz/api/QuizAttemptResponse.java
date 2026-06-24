package com.arstem.backend.quiz.api;

import com.arstem.backend.quiz.domain.QuizAttempt;

public record QuizAttemptResponse(String id, String sessionId, String topicCode, int totalQuestions,
        int correctAnswers, int score, java.time.Instant submittedAt) {

    public static QuizAttemptResponse from(QuizAttempt attempt) {
        return new QuizAttemptResponse(attempt.getId(), attempt.getSessionId(), attempt.getTopicCode(),
                attempt.getTotalQuestions(), attempt.getCorrectAnswers(), attempt.getScore(), attempt.getSubmittedAt());
    }
}
