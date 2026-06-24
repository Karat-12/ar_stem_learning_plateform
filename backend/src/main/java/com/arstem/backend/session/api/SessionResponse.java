package com.arstem.backend.session.api;

import java.time.Instant;

import com.arstem.backend.session.domain.LearningSession;
import com.arstem.backend.session.domain.SessionStatus;

public record SessionResponse(String id, String userId, String domainCode, String topicCode, String activityCode,
        SessionStatus status, Instant startedAt, Instant endedAt) {

    public static SessionResponse from(LearningSession session) {
        return new SessionResponse(session.getId(), session.getUserId(), session.getDomainCode(), session.getTopicCode(),
                session.getActivityCode(), session.getStatus(), session.getStartedAt(), session.getEndedAt());
    }
}
