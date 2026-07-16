package com.arstem.backend.ai.api;

import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
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

    @GetMapping
    public RevisionSuggestionResponse getRevisionSuggestions(Authentication authentication) {
        return revisionSuggestionService.getRevisionSuggestions(authentication.getName());
    }
}
