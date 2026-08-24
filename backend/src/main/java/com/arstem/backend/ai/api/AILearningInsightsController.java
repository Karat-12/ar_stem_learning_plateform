package com.arstem.backend.ai.api;

import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.arstem.backend.ai.domain.LearningInsightsResponse;
import com.arstem.backend.ai.service.AILearningInsightsService;

@RestController
@RequestMapping("/api/v1/ai/insights")
public class AILearningInsightsController {

    private final AILearningInsightsService learningInsightsService;

    public AILearningInsightsController(AILearningInsightsService learningInsightsService) {
        this.learningInsightsService = learningInsightsService;
    }

    /** Global insights across all topics (used by the dashboard overview). */
    @GetMapping
    public LearningInsightsResponse getLearningInsights(Authentication authentication) {
        return learningInsightsService.getLearningInsights(authentication.getName());
    }

    /** Topic-scoped insights — used by the AI Coach screen so Strengths,
     *  Weak Areas, and Overall Performance only reflect the requested topic. */
    @GetMapping("/{topicCode}")
    public LearningInsightsResponse getLearningInsightsForTopic(
            Authentication authentication,
            @PathVariable String topicCode) {
        return learningInsightsService.getLearningInsightsForTopic(
                authentication.getName(), topicCode);
    }
}
