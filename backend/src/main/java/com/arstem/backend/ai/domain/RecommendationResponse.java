package com.arstem.backend.ai.domain;

public record RecommendationResponse(String topicCode, RecommendationType recommendationType, String reason) {
}
