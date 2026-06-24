package com.arstem.backend.progress.api;

import java.util.List;

import com.arstem.backend.progress.domain.Progress;

public record ProgressResponse(String topicCode, int completedSessions, int misconceptionCount, int completionPercent,
        int masteryScore, List<String> weakAreas) {

    public static ProgressResponse from(Progress progress) {
        return new ProgressResponse(progress.getTopicCode(), progress.getCompletedSessions(), progress.getMisconceptionCount(),
                progress.getCompletionPercent(), progress.getMasteryScore(), progress.getWeakAreas());
    }
}
