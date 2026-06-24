package com.arstem.backend.misconception.domain;

import java.time.Instant;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

@Document(collection = "misconceptions")
public class Misconception {

    @Id
    private String id;
    private String userId;
    private String sessionId;
    private String topicCode;
    private String misconceptionCode;
    private String misconceptionTitle;
    private String description;
    private MisconceptionSeverity severity;
    private Instant createdAt;
    private Instant updatedAt;

    public Misconception() {
    }

    public Misconception(String userId, String sessionId, String topicCode, String misconceptionCode,
            String misconceptionTitle, String description, MisconceptionSeverity severity) {
        this.userId = userId;
        this.sessionId = sessionId;
        this.topicCode = topicCode;
        this.misconceptionCode = misconceptionCode;
        this.misconceptionTitle = misconceptionTitle;
        this.description = description;
        this.severity = severity;
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
    public String getMisconceptionCode() { return misconceptionCode; }
    public String getMisconceptionTitle() { return misconceptionTitle; }
    public String getDescription() { return description; }
    public MisconceptionSeverity getSeverity() { return severity; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
}
