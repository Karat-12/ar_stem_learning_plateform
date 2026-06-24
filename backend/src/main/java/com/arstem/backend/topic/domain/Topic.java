package com.arstem.backend.topic.domain;

import java.time.Instant;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.CompoundIndex;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

@Document(collection = "topics")
@CompoundIndex(name = "domain_topic_code_unique", def = "{'domainCode': 1, 'topicCode': 1}", unique = true)
public class Topic {

    @Id
    private String id;

    private String domainCode;

    @Indexed(unique = true)
    private String topicCode;

    private String title;

    private String description;

    private String activityCode;

    private TopicStatus status;

    private Instant createdAt;

    private Instant updatedAt;

    public Topic() {
    }

    public Topic(String domainCode, String topicCode, String title, String description, String activityCode,
            TopicStatus status) {
        this.domainCode = domainCode;
        this.topicCode = topicCode;
        this.title = title;
        this.description = description;
        this.activityCode = activityCode;
        this.status = status;
    }

    public void markCreated() {
        Instant now = Instant.now();
        this.createdAt = now;
        this.updatedAt = now;
    }

    public void markUpdated() {
        this.updatedAt = Instant.now();
    }

    public String getId() { return id; }
    public String getDomainCode() { return domainCode; }
    public String getTopicCode() { return topicCode; }
    public String getTitle() { return title; }
    public String getDescription() { return description; }
    public String getActivityCode() { return activityCode; }
    public TopicStatus getStatus() { return status; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
}
