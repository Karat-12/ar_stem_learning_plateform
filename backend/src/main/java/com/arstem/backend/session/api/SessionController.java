package com.arstem.backend.session.api;

import java.util.List;

import jakarta.validation.Valid;

import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.arstem.backend.session.service.LearningSessionService;

@RestController
@RequestMapping("/api/v1/sessions")
public class SessionController {

    private final LearningSessionService learningSessionService;

    public SessionController(LearningSessionService learningSessionService) {
        this.learningSessionService = learningSessionService;
    }

    @PostMapping("/start")
    public SessionResponse startSession(Authentication authentication, @Valid @RequestBody StartSessionRequest request) {
        return SessionResponse.from(learningSessionService.startSession(authentication.getName(), request));
    }

    @PostMapping("/{sessionId}/end")
    public SessionResponse endSession(Authentication authentication, @PathVariable String sessionId) {
        return SessionResponse.from(learningSessionService.endSession(authentication.getName(), sessionId));
    }

    @GetMapping("/me")
    public List<SessionResponse> getMySessions(Authentication authentication) {
        return learningSessionService.getMySessions(authentication.getName()).stream().map(SessionResponse::from).toList();
    }
}
