package com.arstem.backend.ai.api;

import java.util.List;

import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
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

    @GetMapping
    public List<RecommendationResponse> getRecommendations(Authentication authentication) {
        return aiRecommendationService.getRecommendations(authentication.getName());
    }
}
