package com.arstem.backend.session.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record StartSessionRequest(
        @NotBlank(message = "Domain code is required.")
        @Size(max = 100, message = "Domain code must be at most 100 characters.")
        String domainCode,
        @NotBlank(message = "Topic code is required.")
        @Size(max = 100, message = "Topic code must be at most 100 characters.")
        String topicCode,
        @NotBlank(message = "Activity code is required.")
        @Size(max = 100, message = "Activity code must be at most 100 characters.")
        String activityCode) {
}
