package com.arstem.backend.ai.domain;

import java.util.List;

public record StudyPlanResponse(
        List<String> todayTasks,
        int estimatedTimeMinutes,
        PriorityLevel priorityLevel,
        String reason) {
}
