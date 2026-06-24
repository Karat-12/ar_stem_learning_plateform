package com.arstem.backend.misconception.api;

import java.time.Instant;

import com.arstem.backend.misconception.domain.Misconception;
import com.arstem.backend.misconception.domain.MisconceptionSeverity;

public record MisconceptionResponse(String id, String sessionId, String topicCode, String misconceptionCode,
        String misconceptionTitle, String description, MisconceptionSeverity severity, Instant createdAt) {

    public static MisconceptionResponse from(Misconception misconception) {
        return new MisconceptionResponse(misconception.getId(), misconception.getSessionId(), misconception.getTopicCode(),
                misconception.getMisconceptionCode(), misconception.getMisconceptionTitle(), misconception.getDescription(),
                misconception.getSeverity(), misconception.getCreatedAt());
    }
}
