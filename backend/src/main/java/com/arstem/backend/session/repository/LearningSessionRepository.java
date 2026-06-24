package com.arstem.backend.session.repository;

import java.util.List;

import org.springframework.data.mongodb.repository.MongoRepository;

import com.arstem.backend.session.domain.LearningSession;

public interface LearningSessionRepository extends MongoRepository<LearningSession, String> {
    List<LearningSession> findByUserIdOrderByStartedAtDesc(String userId);
}
