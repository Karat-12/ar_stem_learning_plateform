package com.arstem.backend.learninganalytics.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.mongodb.repository.MongoRepository;

import com.arstem.backend.learninganalytics.domain.LearningAnalytics;

public interface LearningAnalyticsRepository extends MongoRepository<LearningAnalytics, String> {
    List<LearningAnalytics> findByUserId(String userId);

    Optional<LearningAnalytics> findByUserIdAndTopicCode(String userId, String topicCode);
}
