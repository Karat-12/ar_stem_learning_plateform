package com.arstem.backend.misconception.api;

import java.util.List;

import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.arstem.backend.misconception.service.MisconceptionService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/v1/misconceptions")
public class MisconceptionController {

    private final MisconceptionService misconceptionService;

    public MisconceptionController(MisconceptionService misconceptionService) {
        this.misconceptionService = misconceptionService;
    }

    @PostMapping
    public MisconceptionResponse recordMisconception(Authentication authentication,
            @Valid @RequestBody RecordMisconceptionRequest request) {
        return MisconceptionResponse.from(misconceptionService.recordMisconception(authentication.getName(), request));
    }

    @GetMapping("/me")
    public List<MisconceptionResponse> getMyMisconceptions(Authentication authentication) {
        return misconceptionService.getMyMisconceptions(authentication.getName()).stream()
                .map(MisconceptionResponse::from).toList();
    }

    @GetMapping("/session/{sessionId}")
    public List<MisconceptionResponse> getSessionMisconceptions(Authentication authentication, @PathVariable String sessionId) {
        return misconceptionService.getSessionMisconceptions(authentication.getName(), sessionId).stream()
                .map(MisconceptionResponse::from).toList();
    }
}
