package com.arstem.backend.topic.service;

import java.util.List;
import java.util.Locale;

import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

import com.arstem.backend.common.exception.ResourceNotFoundException;
import com.arstem.backend.topic.domain.Topic;
import com.arstem.backend.topic.repository.TopicRepository;

@Service
public class TopicService {

    private final TopicRepository topicRepository;

    public TopicService(TopicRepository topicRepository) {
        this.topicRepository = topicRepository;
    }

    public List<Topic> getAllTopics() {
        return topicRepository.findAll(Sort.by(Sort.Direction.ASC, "domainCode", "title"));
    }

    public Topic getTopicByCode(String topicCode) {
        return topicRepository.findByTopicCode(normalizeTopicCode(topicCode))
                .orElseThrow(() -> new ResourceNotFoundException("Topic with code '" + topicCode + "' was not found."));
    }

    private String normalizeTopicCode(String topicCode) {
        return topicCode.trim().toUpperCase(Locale.ROOT);
    }
}
