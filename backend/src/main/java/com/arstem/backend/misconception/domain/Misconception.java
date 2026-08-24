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
    /** Lifecycle state — defaults to ACTIVE on creation, may be moved to RESOLVED. */
    private MisconceptionStatus status = MisconceptionStatus.ACTIVE;
    private Instant resolvedAt;
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
        this.status = MisconceptionStatus.ACTIVE;
        Instant now = Instant.now();
        this.createdAt = now;
        this.updatedAt = now;
    }

    /**
     * Marks this misconception as RESOLVED because the student demonstrated
     * correct understanding in a subsequent assessment.  Once resolved the
     * record is retained for historical analytics but excluded from all
     * AI Coach mastery calculations and revision suggestions.
     */
    public void resolve() {
        this.status = MisconceptionStatus.RESOLVED;
        Instant now = Instant.now();
        this.resolvedAt = now;
        this.updatedAt = now;
    }

    public boolean isActive() {
        return status == null || status == MisconceptionStatus.ACTIVE;
    }

    public String getId() { return id; }
    public String getUserId() { return userId; }
    public String getSessionId() { return sessionId; }
    public String getTopicCode() { return topicCode; }
    public String getMisconceptionCode() { return misconceptionCode; }
    public String getMisconceptionTitle() { return misconceptionTitle; }
    public String getDescription() { return description; }
    public MisconceptionSeverity getSeverity() { return severity; }
    public MisconceptionStatus getStatus() { return status; }
    public Instant getResolvedAt() { return resolvedAt; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
}
