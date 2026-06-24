package com.arstem.backend.topic.config;

import java.util.List;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

import com.arstem.backend.topic.domain.Topic;
import com.arstem.backend.topic.domain.TopicStatus;
import com.arstem.backend.topic.repository.TopicRepository;

/** Seeds the initial learning catalogue only when the topics collection is empty. */
@Component
public class TopicSeeder implements ApplicationRunner {

    private final TopicRepository topicRepository;

    public TopicSeeder(TopicRepository topicRepository) {
        this.topicRepository = topicRepository;
    }

    @Override
    public void run(ApplicationArguments args) {
        if (topicRepository.count() != 0) {
            return;
        }

        List<Topic> topics = List.of(
                topic("DSA", "DSA_LINKED_LIST", "Linked List", "Explore nodes connected through references.", "LINKED_LIST"),
                topic("DSA", "DSA_STACK", "Stack", "Learn last-in, first-out data operations.", "STACK"),
                topic("DSA", "DSA_BINARY_TREE", "Binary Tree", "Explore hierarchical nodes with up to two children.", "BINARY_TREE"),
                topic("ELECTRONICS", "ELECTRONICS_AND_GATE", "AND Gate", "Learn the output rule for an AND logic gate.", "AND_GATE"),
                topic("ELECTRONICS", "ELECTRONICS_OR_GATE", "OR Gate", "Learn the output rule for an OR logic gate.", "OR_GATE"),
                topic("ELECTRONICS", "ELECTRONICS_NOT_GATE", "NOT Gate", "Learn how a NOT gate inverts a signal.", "NOT_GATE"),
                topic("ELECTRONICS", "ELECTRONICS_XOR_GATE", "XOR Gate", "Learn exclusive OR logic.", "XOR_GATE"),
                topic("ELECTRONICS", "ELECTRONICS_NAND_GATE", "NAND Gate", "Learn the inverted AND logic rule.", "NAND_GATE"),
                topic("ELECTRONICS", "ELECTRONICS_NOR_GATE", "NOR Gate", "Learn the inverted OR logic rule.", "NOR_GATE"),
                topic("ELECTRONICS", "ELECTRONICS_XNOR_GATE", "XNOR Gate", "Learn equivalence logic with XNOR.", "XNOR_GATE"),
                topic("CHEMISTRY", "CHEMISTRY_METHANE", "Methane", "Explore the molecular structure of methane.", "METHANE"),
                topic("CHEMISTRY", "CHEMISTRY_ETHANE", "Ethane", "Explore the molecular structure of ethane.", "ETHANE"),
                topic("CHEMISTRY", "CHEMISTRY_PROPANE", "Propane", "Explore the molecular structure of propane.", "PROPANE"),
                topic("CHEMISTRY", "CHEMISTRY_METHANOL", "Methanol", "Explore the molecular structure of methanol.", "METHANOL"),
                topic("CHEMISTRY", "CHEMISTRY_ETHANOL", "Ethanol", "Explore the molecular structure of ethanol.", "ETHANOL"),
                topic("CHEMISTRY", "CHEMISTRY_GLUCOSE", "Glucose", "Explore the molecular structure of glucose.", "GLUCOSE"),
                topic("CHEMISTRY", "CHEMISTRY_FRUCTOSE", "Fructose", "Explore the molecular structure of fructose.", "FRUCTOSE"),
                topic("CHEMISTRY", "CHEMISTRY_SUCROSE", "Sucrose", "Explore the molecular structure of sucrose.", "SUCROSE"));

        topicRepository.saveAll(topics);
    }

    private Topic topic(String domainCode, String topicCode, String title, String description, String activityCode) {
        Topic topic = new Topic(domainCode, topicCode, title, description, activityCode, TopicStatus.ACTIVE);
        topic.markCreated();
        return topic;
    }
}
