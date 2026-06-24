package com.arstem.backend.session.service;

import java.util.List;

import org.springframework.stereotype.Service;

import com.arstem.backend.common.exception.ResourceNotFoundException;
import com.arstem.backend.common.exception.UnauthorizedException;
import com.arstem.backend.session.api.StartSessionRequest;
import com.arstem.backend.session.domain.LearningSession;
import com.arstem.backend.session.repository.LearningSessionRepository;
import com.arstem.backend.user.domain.User;
import com.arstem.backend.user.service.UserService;

@Service
public class LearningSessionService {

    private final LearningSessionRepository learningSessionRepository;
    private final UserService userService;

    public LearningSessionService(LearningSessionRepository learningSessionRepository, UserService userService) {
        this.learningSessionRepository = learningSessionRepository;
        this.userService = userService;
    }

    public LearningSession startSession(String authenticatedEmail, StartSessionRequest request) {
        User user = getAuthenticatedUser(authenticatedEmail);
        LearningSession session = new LearningSession(user.getId(), request.domainCode().trim(), request.topicCode().trim(),
                request.activityCode().trim());
        session.markCreated();
        return learningSessionRepository.save(session);
    }

    public LearningSession endSession(String authenticatedEmail, String sessionId) {
        User user = getAuthenticatedUser(authenticatedEmail);
        LearningSession session = learningSessionRepository.findById(sessionId)
                .orElseThrow(() -> new ResourceNotFoundException("Learning session with id '" + sessionId + "' was not found."));
        if (!session.getUserId().equals(user.getId())) {
            throw new UnauthorizedException("You are not authorized to end this learning session.");
        }
        session.complete();
        return learningSessionRepository.save(session);
    }

    public List<LearningSession> getMySessions(String authenticatedEmail) {
        User user = getAuthenticatedUser(authenticatedEmail);
        return learningSessionRepository.findByUserIdOrderByStartedAtDesc(user.getId());
    }

    private User getAuthenticatedUser(String email) {
        return userService.findByEmail(email)
                .orElseThrow(() -> new UnauthorizedException("Authenticated user no longer exists."));
    }
}
