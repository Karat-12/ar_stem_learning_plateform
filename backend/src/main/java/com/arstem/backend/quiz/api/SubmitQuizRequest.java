package com.arstem.backend.quiz.api;

public record SubmitQuizRequest(String sessionId, String topicCode, int totalQuestions, int correctAnswers) {
}
