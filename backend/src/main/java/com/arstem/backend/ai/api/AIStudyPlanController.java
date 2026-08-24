package com.arstem.backend.ai.api;

import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.arstem.backend.ai.domain.StudyPlanResponse;
import com.arstem.backend.ai.service.AIStudyPlanService;

@RestController
@RequestMapping("/api/v1/ai/study-plan")
public class AIStudyPlanController {

    private final AIStudyPlanService studyPlanService;

    public AIStudyPlanController(AIStudyPlanService studyPlanService) {
        this.studyPlanService = studyPlanService;
    }

    /** Global study plan across all topics (used by dashboard). */
    @GetMapping
    public StudyPlanResponse getStudyPlan(Authentication authentication) {
        return studyPlanService.getStudyPlan(authentication.getName());
    }

    /** Topic-scoped study plan — used by the AI Coach screen so it never
     *  suggests Stack or Chemistry tasks when reviewing Linked List. */
    @GetMapping("/{topicCode}")
    public StudyPlanResponse getStudyPlanForTopic(
            Authentication authentication,
            @PathVariable String topicCode) {
        return studyPlanService.getStudyPlanForTopic(authentication.getName(), topicCode);
    }
}
