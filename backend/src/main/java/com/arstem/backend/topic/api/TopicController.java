package com.arstem.backend.topic.api;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.arstem.backend.topic.service.TopicService;

@RestController
@RequestMapping("/api/v1/topics")
public class TopicController {

    private final TopicService topicService;

    public TopicController(TopicService topicService) {
        this.topicService = topicService;
    }

    @GetMapping
    public List<TopicResponse> getAllTopics() {
        return topicService.getAllTopics().stream().map(TopicResponse::from).toList();
    }

    @GetMapping("/{topicCode}")
    public TopicResponse getTopicByCode(@PathVariable String topicCode) {
        return TopicResponse.from(topicService.getTopicByCode(topicCode));
    }
}
