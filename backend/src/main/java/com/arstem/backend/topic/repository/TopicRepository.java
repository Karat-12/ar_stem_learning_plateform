package com.arstem.backend.topic.repository;

import java.util.Optional;

import org.springframework.data.mongodb.repository.MongoRepository;

import com.arstem.backend.topic.domain.Topic;

public interface TopicRepository extends MongoRepository<Topic, String> {
    Optional<Topic> findByTopicCode(String topicCode);
}
