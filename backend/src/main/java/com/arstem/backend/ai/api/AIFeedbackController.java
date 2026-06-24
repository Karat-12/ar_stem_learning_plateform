package com.arstem.backend.ai.api;

import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.arstem.backend.ai.domain.FeedbackResponse;
import com.arstem.backend.ai.service.AIFeedbackService;

@RestController
@RequestMapping("/api/v1/ai/feedback")
public class AIFeedbackController {

    private final AIFeedbackService feedbackService;

    public AIFeedbackController(AIFeedbackService feedbackService) {
        this.feedbackService = feedbackService;
    }

    @GetMapping
    public FeedbackResponse getFeedback(Authentication authentication) {
        return feedbackService.getFeedback(authentication.getName());
    }
}
