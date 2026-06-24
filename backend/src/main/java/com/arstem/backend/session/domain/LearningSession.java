package com.arstem.backend.session.domain;

import java.time.Instant;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

@Document(collection = "learning_sessions")
public class LearningSession {

    @Id
    private String id;
    private String userId;
    private String domainCode;
    private String topicCode;
    private String activityCode;
    private SessionStatus status;
    private Instant startedAt;
    private Instant endedAt;
    private Instant createdAt;
    private Instant updatedAt;

    public LearningSession() {
    }

    public LearningSession(String userId, String domainCode, String topicCode, String activityCode) {
        this.userId = userId;
        this.domainCode = domainCode;
        this.topicCode = topicCode;
        this.activityCode = activityCode;
        this.status = SessionStatus.ACTIVE;
        this.startedAt = Instant.now();
    }

    public void markCreated() {
        Instant now = Instant.now();
        this.createdAt = now;
        this.updatedAt = now;
    }

    public void complete() {
        this.status = SessionStatus.COMPLETED;
        this.endedAt = Instant.now();
        this.updatedAt = this.endedAt;
    }

    public String getId() { return id; }
    public String getUserId() { return userId; }
    public String getDomainCode() { return domainCode; }
    public String getTopicCode() { return topicCode; }
    public String getActivityCode() { return activityCode; }
    public SessionStatus getStatus() { return status; }
    public Instant getStartedAt() { return startedAt; }
    public Instant getEndedAt() { return endedAt; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
}
