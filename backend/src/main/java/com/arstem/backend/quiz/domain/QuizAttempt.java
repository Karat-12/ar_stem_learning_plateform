package com.arstem.backend.quiz.domain;

import java.time.Instant;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

@Document(collection = "quiz_attempts")
public class QuizAttempt {

    @Id
    private String id;
    private String userId;
    private String sessionId;
    private String topicCode;
    private int totalQuestions;
    private int correctAnswers;
    private int score;
    private Instant submittedAt;
    private Instant createdAt;
    private Instant updatedAt;

    public QuizAttempt() {
    }

    public QuizAttempt(String userId, String sessionId, String topicCode, int totalQuestions, int correctAnswers,
            int score) {
        this.userId = userId;
        this.sessionId = sessionId;
        this.topicCode = topicCode;
        this.totalQuestions = totalQuestions;
        this.correctAnswers = correctAnswers;
        this.score = score;
        this.submittedAt = Instant.now();
    }

    public void markCreated() {
        Instant now = Instant.now();
        this.createdAt = now;
        this.updatedAt = now;
    }

    public String getId() { return id; }
    public String getUserId() { return userId; }
    public String getSessionId() { return sessionId; }
    public String getTopicCode() { return topicCode; }
    public int getTotalQuestions() { return totalQuestions; }
    public int getCorrectAnswers() { return correctAnswers; }
    public int getScore() { return score; }
    public Instant getSubmittedAt() { return submittedAt; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
}
