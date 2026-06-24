package com.arstem.backend.misconception.repository;

import java.util.List;

import org.springframework.data.mongodb.repository.MongoRepository;

import com.arstem.backend.misconception.domain.Misconception;

public interface MisconceptionRepository extends MongoRepository<Misconception, String> {
    List<Misconception> findByUserIdOrderByCreatedAtDesc(String userId);

    List<Misconception> findBySessionId(String sessionId);
}
