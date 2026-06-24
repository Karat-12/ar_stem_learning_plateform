package com.arstem.backend.misconception.service;

import java.util.List;

import org.springframework.stereotype.Service;

import com.arstem.backend.common.exception.ResourceNotFoundException;
import com.arstem.backend.common.exception.UnauthorizedException;
import com.arstem.backend.misconception.api.RecordMisconceptionRequest;
import com.arstem.backend.misconception.domain.Misconception;
import com.arstem.backend.misconception.repository.MisconceptionRepository;
import com.arstem.backend.session.domain.LearningSession;
import com.arstem.backend.session.repository.LearningSessionRepository;
import com.arstem.backend.user.domain.User;
import com.arstem.backend.user.service.UserService;

@Service
public class MisconceptionService {

    private final MisconceptionRepository misconceptionRepository;
    private final LearningSessionRepository learningSessionRepository;
    private final UserService userService;

    public MisconceptionService(MisconceptionRepository misconceptionRepository,
            LearningSessionRepository learningSessionRepository, UserService userService) {
        this.misconceptionRepository = misconceptionRepository;
        this.learningSessionRepository = learningSessionRepository;
        this.userService = userService;
    }

    public Misconception recordMisconception(String authenticatedEmail, RecordMisconceptionRequest request) {
        User user = getAuthenticatedUser(authenticatedEmail);
        verifySessionOwnership(request.sessionId(), user);
        Misconception misconception = new Misconception(user.getId(), request.sessionId().trim(), request.topicCode().trim(),
                request.misconceptionCode().trim(), request.misconceptionTitle().trim(), request.description().trim(),
                request.severity());
        misconception.markCreated();
        return misconceptionRepository.save(misconception);
    }

    public List<Misconception> getMyMisconceptions(String authenticatedEmail) {
        User user = getAuthenticatedUser(authenticatedEmail);
        return misconceptionRepository.findByUserIdOrderByCreatedAtDesc(user.getId());
    }

    public List<Misconception> getSessionMisconceptions(String authenticatedEmail, String sessionId) {
        User user = getAuthenticatedUser(authenticatedEmail);
        verifySessionOwnership(sessionId, user);
        return misconceptionRepository.findBySessionId(sessionId);
    }

    private User getAuthenticatedUser(String email) {
        return userService.findByEmail(email)
                .orElseThrow(() -> new UnauthorizedException("Authenticated user no longer exists."));
    }

    private void verifySessionOwnership(String sessionId, User user) {
        LearningSession session = learningSessionRepository.findById(sessionId)
                .orElseThrow(() -> new ResourceNotFoundException("Learning session with id '" + sessionId + "' was not found."));
        if (!session.getUserId().equals(user.getId())) {
            throw new UnauthorizedException("You are not authorized to access this learning session.");
        }
    }
}
