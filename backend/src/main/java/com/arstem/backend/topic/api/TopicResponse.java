package com.arstem.backend.topic.api;

import com.arstem.backend.topic.domain.Topic;
import com.arstem.backend.topic.domain.TopicStatus;

/** Public representation of a STEM learning topic. */
public record TopicResponse(String id, String domainCode, String topicCode, String title, String description,
        String activityCode, TopicStatus status) {

    public static TopicResponse from(Topic topic) {
        return new TopicResponse(topic.getId(), topic.getDomainCode(), topic.getTopicCode(), topic.getTitle(),
                topic.getDescription(), topic.getActivityCode(), topic.getStatus());
    }
}
