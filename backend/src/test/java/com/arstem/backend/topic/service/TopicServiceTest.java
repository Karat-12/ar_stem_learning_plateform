package com.arstem.backend.topic.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

import java.util.Optional;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.arstem.backend.common.exception.ResourceNotFoundException;
import com.arstem.backend.topic.domain.Topic;
import com.arstem.backend.topic.domain.TopicStatus;
import com.arstem.backend.topic.repository.TopicRepository;

@ExtendWith(MockitoExtension.class)
class TopicServiceTest {

    @Mock
    private TopicRepository topicRepository;

    @InjectMocks
    private TopicService topicService;

    @Test
    void findsTopicByCaseInsensitiveCode() {
        Topic topic = new Topic("DSA", "DSA_STACK", "Stack", "Last-in, first-out.", "STACK", TopicStatus.ACTIVE);
        when(topicRepository.findByTopicCode("DSA_STACK")).thenReturn(Optional.of(topic));

        assertThat(topicService.getTopicByCode("dsa_stack")).isSameAs(topic);
    }

    @Test
    void throwsNotFoundWhenTopicCodeDoesNotExist() {
        when(topicRepository.findByTopicCode("UNKNOWN")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> topicService.getTopicByCode("unknown"))
                .isInstanceOf(ResourceNotFoundException.class);
    }
}
