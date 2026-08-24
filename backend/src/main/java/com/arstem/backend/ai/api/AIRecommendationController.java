package com.arstem.backend.ai.api;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.arstem.backend.ai.domain.RecommendationResponse;
import com.arstem.backend.ai.service.AIRecommendationService;

@RestController
@RequestMapping("/api/v1/ai/recommendations")
public class AIRecommendationController {

    private final AIRecommendationService aiRecommendationService;

    public AIRecommendationController(AIRecommendationService aiRecommendationService) {
        this.aiRecommendationService = aiRecommendationService;
    }

    /** Global recommendations across all topics (used by the dashboard). */
    @GetMapping
    public List<RecommendationResponse> getRecommendations(Authentication authentication) {
        return aiRecommendationService.getRecommendations(authentication.getName());
    }

    /** Topic-scoped single recommendation — used by the AI Coach screen.
     *  Returns 204 No Content when no recommendation applies for this topic. */
    @GetMapping("/{topicCode}")
    public ResponseEntity<RecommendationResponse> getRecommendationForTopic(
            Authentication authentication,
            @PathVariable String topicCode) {
        RecommendationResponse recommendation =
                aiRecommendationService.getRecommendationForTopic(
                        authentication.getName(), topicCode);
        return recommendation != null
                ? ResponseEntity.ok(recommendation)
                : ResponseEntity.noContent().build();
    }
}
