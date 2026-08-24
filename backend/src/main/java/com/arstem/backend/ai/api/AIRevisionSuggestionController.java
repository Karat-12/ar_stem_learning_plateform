package com.arstem.backend.ai.api;

import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.arstem.backend.ai.domain.RevisionSuggestionResponse;
import com.arstem.backend.ai.service.AIRevisionSuggestionService;

@RestController
@RequestMapping("/api/v1/ai/revision-suggestions")
public class AIRevisionSuggestionController {

    private final AIRevisionSuggestionService revisionSuggestionService;

    public AIRevisionSuggestionController(AIRevisionSuggestionService revisionSuggestionService) {
        this.revisionSuggestionService = revisionSuggestionService;
    }

    /** Global revision suggestions across all topics (used by dashboard). */
    @GetMapping
    public RevisionSuggestionResponse getRevisionSuggestions(Authentication authentication) {
        return revisionSuggestionService.getRevisionSuggestions(authentication.getName());
    }

    /** Topic-scoped revision suggestions — used by the AI Coach screen. */
    @GetMapping("/{topicCode}")
    public RevisionSuggestionResponse getRevisionSuggestionsForTopic(
            Authentication authentication,
            @PathVariable String topicCode) {
        return revisionSuggestionService.getRevisionSuggestionsForTopic(authentication.getName(), topicCode);
    }
}
