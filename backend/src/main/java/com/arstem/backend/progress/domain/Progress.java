package com.arstem.backend.progress.domain;

import java.time.Instant;
import java.util.List;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.CompoundIndex;
import org.springframework.data.mongodb.core.mapping.Document;

@Document(collection = "progress")
@CompoundIndex(name = "user_topic_unique", def = "{'userId': 1, 'topicCode': 1}", unique = true)
public class Progress {

    @Id
    private String id;
    private String userId;
    private String topicCode;
    private int completedSessions;
    private int misconceptionCount;
    private int completionPercent;
    private int masteryScore;
    private List<String> weakAreas;
    private Instant createdAt;
    private Instant updatedAt;

    public Progress() {
    }

    public Progress(String userId, String topicCode) {
        this.userId = userId;
        this.topicCode = topicCode;
    }

    public void update(int completedSessions, int misconceptionCount, int completionPercent, int masteryScore,
            List<String> weakAreas) {
        this.completedSessions = completedSessions;
        this.misconceptionCount = misconceptionCount;
        this.completionPercent = completionPercent;
        this.masteryScore = masteryScore;
        this.weakAreas = List.copyOf(weakAreas);
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
    public int getCompletionPercent() { return completionPercent; }
    public int getMasteryScore() { return masteryScore; }
    public List<String> getWeakAreas() { return List.copyOf(weakAreas); }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
}
