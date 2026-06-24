package com.arstem.backend.progress.api;

import java.util.List;

import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.arstem.backend.progress.service.ProgressService;

@RestController
@RequestMapping("/api/v1/progress")
public class ProgressController {

    private final ProgressService progressService;

    public ProgressController(ProgressService progressService) {
        this.progressService = progressService;
    }

    @GetMapping("/me")
    public List<ProgressResponse> getMyProgress(Authentication authentication) {
        return progressService.getMyProgress(authentication.getName()).stream().map(ProgressResponse::from).toList();
    }

    @GetMapping("/topic/{topicCode}")
    public ProgressResponse getTopicProgress(Authentication authentication, @PathVariable String topicCode) {
        return ProgressResponse.from(progressService.getTopicProgress(authentication.getName(), topicCode));
    }
}
