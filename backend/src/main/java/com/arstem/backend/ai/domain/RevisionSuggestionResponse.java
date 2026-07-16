package com.arstem.backend.ai.domain;

import java.util.List;

public record RevisionSuggestionResponse(
        List<String> revisionTopics,
        List<String> revisionActions,
        int estimatedRevisionTimeMinutes,
        String reason) {
}
