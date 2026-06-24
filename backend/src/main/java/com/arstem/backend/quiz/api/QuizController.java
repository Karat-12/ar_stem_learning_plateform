package com.arstem.backend.quiz.api;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.arstem.backend.quiz.service.QuizService;
import com.arstem.backend.quiz.domain.QuizAttempt;

@RestController
@RequestMapping("/api/v1/quizzes")
public class QuizController {

    private final QuizService quizService;

    public QuizController(QuizService quizService) {
        this.quizService = quizService;
    }

    @PostMapping("/submit")
    public Map<String, Integer> submitQuiz(Authentication authentication, @RequestBody SubmitQuizRequest request) {
        int score = quizService.submitQuiz(authentication.getName(), request);
        return Map.of("score", score);
    }

    @GetMapping("/me")
    public List<QuizAttemptResponse> getMyAttempts(Authentication authentication) {
        return quizService.getMyAttempts(authentication.getName()).stream().map(QuizAttemptResponse::from).collect(Collectors.toList());
    }

    @GetMapping("/topic/{topicCode}")
    public List<QuizAttemptResponse> getTopicAttempts(Authentication authentication, @PathVariable String topicCode) {
        return quizService.getTopicAttempts(authentication.getName(), topicCode).stream().map(QuizAttemptResponse::from).collect(Collectors.toList());
    }
}
