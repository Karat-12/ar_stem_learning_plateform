package com.arstem.backend.misconception.api;

import com.arstem.backend.misconception.domain.MisconceptionSeverity;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record RecordMisconceptionRequest(
        @NotBlank(message = "Session id is required.")
        String sessionId,
        @NotBlank(message = "Topic code is required.")
        @Size(max = 100, message = "Topic code must be at most 100 characters.")
        String topicCode,
        @NotBlank(message = "Misconception code is required.")
        @Size(max = 100, message = "Misconception code must be at most 100 characters.")
        String misconceptionCode,
        @NotBlank(message = "Misconception title is required.")
        @Size(max = 200, message = "Misconception title must be at most 200 characters.")
        String misconceptionTitle,
        @NotBlank(message = "Description is required.")
        @Size(max = 2000, message = "Description must be at most 2000 characters.")
        String description,
        @NotNull(message = "Severity is required.")
        MisconceptionSeverity severity) {
}
