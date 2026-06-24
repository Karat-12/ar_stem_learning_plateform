package com.arstem.backend.ai.api;

import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
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

    @GetMapping
    public StudyPlanResponse getStudyPlan(Authentication authentication) {
        return studyPlanService.getStudyPlan(authentication.getName());
    }
}
