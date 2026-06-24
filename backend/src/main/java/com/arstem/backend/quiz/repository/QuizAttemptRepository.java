package com.arstem.backend.quiz.repository;

import java.util.List;

import org.springframework.data.mongodb.repository.MongoRepository;

import com.arstem.backend.quiz.domain.QuizAttempt;

public interface QuizAttemptRepository extends MongoRepository<QuizAttempt, String> {
    List<QuizAttempt> findByUserIdOrderBySubmittedAtDesc(String userId);
    List<QuizAttempt> findByUserIdAndTopicCodeOrderBySubmittedAtDesc(String userId, String topicCode);
}
