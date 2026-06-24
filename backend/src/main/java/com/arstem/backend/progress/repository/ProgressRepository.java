package com.arstem.backend.progress.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.mongodb.repository.MongoRepository;

import com.arstem.backend.progress.domain.Progress;

public interface ProgressRepository extends MongoRepository<Progress, String> {
    List<Progress> findByUserId(String userId);

    Optional<Progress> findByUserIdAndTopicCode(String userId, String topicCode);
}
