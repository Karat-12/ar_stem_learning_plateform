package com.arstem.backend.progress.service;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.TreeSet;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;

import com.arstem.backend.common.exception.ResourceNotFoundException;
import com.arstem.backend.common.exception.UnauthorizedException;
import com.arstem.backend.misconception.domain.Misconception;
import com.arstem.backend.misconception.repository.MisconceptionRepository;
import com.arstem.backend.progress.domain.Progress;
import com.arstem.backend.progress.repository.ProgressRepository;
import com.arstem.backend.session.domain.LearningSession;
import com.arstem.backend.session.domain.SessionStatus;
import com.arstem.backend.session.repository.LearningSessionRepository;
import com.arstem.backend.user.domain.User;
import com.arstem.backend.user.service.UserService;

@Service
public class ProgressService {

    private final ProgressRepository progressRepository;
    private final LearningSessionRepository learningSessionRepository;
    private final MisconceptionRepository misconceptionRepository;
    private final UserService userService;

    public ProgressService(ProgressRepository progressRepository, LearningSessionRepository learningSessionRepository,
            MisconceptionRepository misconceptionRepository, UserService userService) {
        this.progressRepository = progressRepository;
        this.learningSessionRepository = learningSessionRepository;
        this.misconceptionRepository = misconceptionRepository;
        this.userService = userService;
    }

    public List<Progress> getMyProgress(String authenticatedEmail) {
        User user = getAuthenticatedUser(authenticatedEmail);
        generateProgress(user);
        return progressRepository.findByUserId(user.getId());
    }

    public Progress getTopicProgress(String authenticatedEmail, String topicCode) {
        User user = getAuthenticatedUser(authenticatedEmail);
        generateProgress(user);
        String normalizedTopicCode = normalizeTopicCode(topicCode);
        return progressRepository.findByUserIdAndTopicCode(user.getId(), normalizedTopicCode)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Progress for topic code '" + topicCode + "' was not found."));
    }

    private void generateProgress(User user) {
        List<LearningSession> sessions = learningSessionRepository.findByUserIdOrderByStartedAtDesc(user.getId());
        List<Misconception> misconceptions = misconceptionRepository.findByUserIdOrderByCreatedAtDesc(user.getId());

        Map<String, List<LearningSession>> sessionsByTopic = sessions.stream()
                .collect(Collectors.groupingBy(LearningSession::getTopicCode));
        Map<String, List<Misconception>> misconceptionsByTopic = misconceptions.stream()
                .collect(Collectors.groupingBy(Misconception::getTopicCode));
        TreeSet<String> topicCodes = new TreeSet<>();
        topicCodes.addAll(sessionsByTopic.keySet());
        topicCodes.addAll(misconceptionsByTopic.keySet());

        for (String topicCode : topicCodes) {
            List<LearningSession> topicSessions = sessionsByTopic.getOrDefault(topicCode, List.of());
            List<Misconception> topicMisconceptions = misconceptionsByTopic.getOrDefault(topicCode, List.of());
            int completedSessions = (int) topicSessions.stream()
                    .filter(session -> session.getStatus() == SessionStatus.COMPLETED)
                    .count();
            int misconceptionCount = topicMisconceptions.size();
            List<String> weakAreas = topicMisconceptions.stream()
                    .map(Misconception::getMisconceptionCode)
                    .collect(Collectors.toCollection(TreeSet::new))
                    .stream().toList();

            Progress progress = progressRepository.findByUserIdAndTopicCode(user.getId(), topicCode)
                    .orElseGet(() -> {
                        Progress newProgress = new Progress(user.getId(), topicCode);
                        newProgress.markCreated();
                        return newProgress;
                    });
            progress.update(completedSessions, misconceptionCount, completionPercent(completedSessions),
                    masteryScore(misconceptionCount), weakAreas);
            progressRepository.save(progress);
        }
    }

    static int completionPercent(int completedSessions) {
        return Math.min(Math.max(completedSessions, 0) * 25, 100);
    }

    static int masteryScore(int misconceptionCount) {
        return Math.max(100 - Math.max(misconceptionCount, 0) * 10, 0);
    }

    private User getAuthenticatedUser(String email) {
        return userService.findByEmail(email)
                .orElseThrow(() -> new UnauthorizedException("Authenticated user no longer exists."));
    }

    private String normalizeTopicCode(String topicCode) {
        return topicCode.trim().toUpperCase();
    }
}
