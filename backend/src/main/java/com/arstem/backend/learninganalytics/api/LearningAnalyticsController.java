package com.arstem.backend.learninganalytics.api;

import java.util.List;
import java.util.stream.Collectors;

import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.arstem.backend.learninganalytics.api.LearningAnalyticsResponse;
import com.arstem.backend.learninganalytics.service.LearningAnalyticsService;

@RestController
@RequestMapping("/api/v1/analytics")
public class LearningAnalyticsController {

    private final LearningAnalyticsService analyticsService;

    public LearningAnalyticsController(LearningAnalyticsService analyticsService) {
        this.analyticsService = analyticsService;
    }

    @GetMapping("/me")
    public List<LearningAnalyticsResponse> getMyAnalytics(Authentication authentication) {
        return analyticsService.getMyAnalytics(authentication.getName()).stream().map(LearningAnalyticsResponse::from)
                .collect(Collectors.toList());
    }

    @GetMapping("/topic/{topicCode}")
    public LearningAnalyticsResponse getTopicAnalytics(Authentication authentication, @PathVariable String topicCode) {
        return LearningAnalyticsResponse.from(analyticsService.getTopicAnalytics(authentication.getName(), topicCode));
    }
}
