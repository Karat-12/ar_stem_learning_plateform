package com.arstem.backend.learninganalytics.domain;

import java.time.Instant;
import java.util.List;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

@Document(collection = "learning_analytics")
public class LearningAnalytics {

    @Id
    private String id;
    private String userId;
    private String topicCode;
    private int completedSessions;
    private int misconceptionCount;
    private int averageQuizScore;
    private int masteryScore;
    private String masteryLevel;
    private List<String> weakAreas;
    private boolean recommendedPractice;
    private Instant createdAt;
    private Instant updatedAt;

    public LearningAnalytics() {
    }

    public LearningAnalytics(String userId, String topicCode) {
        this.userId = userId;
        this.topicCode = topicCode;
    }

    public void update(int completedSessions, int misconceptionCount, int averageQuizScore, int masteryScore,
            String masteryLevel, List<String> weakAreas, boolean recommendedPractice) {
        this.completedSessions = completedSessions;
        this.misconceptionCount = misconceptionCount;
        this.averageQuizScore = averageQuizScore;
        this.masteryScore = masteryScore;
        this.masteryLevel = masteryLevel;
        this.weakAreas = List.copyOf(weakAreas);
        this.recommendedPractice = recommendedPractice;
        this.updatedAt = Instant.now();
    }

    public void markCreated() {
        Instant now = Instant.now();
        this.createdAt = now;
        this.updatedAt = now;
    }

    public String getId() { return id; }
    public String getUserId() { return userId; }
    public String getTopicCode() { return topicCode; }
    public int getCompletedSessions() { return completedSessions; }
    public int getMisconceptionCount() { return misconceptionCount; }
    public int getAverageQuizScore() { return averageQuizScore; }
    public int getMasteryScore() { return masteryScore; }
    public String getMasteryLevel() { return masteryLevel; }
    public List<String> getWeakAreas() { return List.copyOf(weakAreas); }
    public boolean isRecommendedPractice() { return recommendedPractice; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
}
