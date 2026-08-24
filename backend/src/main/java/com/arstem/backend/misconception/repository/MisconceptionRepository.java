package com.arstem.backend.misconception.repository;

import java.util.List;

import org.springframework.data.mongodb.repository.MongoRepository;

import com.arstem.backend.misconception.domain.Misconception;
import com.arstem.backend.misconception.domain.MisconceptionStatus;

public interface MisconceptionRepository extends MongoRepository<Misconception, String> {
    List<Misconception> findByUserIdOrderByCreatedAtDesc(String userId);

    /** Returns only misconceptions for a specific topic, used by topic-scoped AI services. */
    List<Misconception> findByUserIdAndTopicCodeOrderByCreatedAtDesc(String userId, String topicCode);

    /**
     * Returns only ACTIVE (unresolved) misconceptions for a specific topic.
     * Use this everywhere the AI Coach needs to penalise mastery or drive
     * revision suggestions — resolved misconceptions must never appear there.
     */
    List<Misconception> findByUserIdAndTopicCodeAndStatusOrderByCreatedAtDesc(
            String userId, String topicCode, MisconceptionStatus status);

    List<Misconception> findBySessionId(String sessionId);
}
