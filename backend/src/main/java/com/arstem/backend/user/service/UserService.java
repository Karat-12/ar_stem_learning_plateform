package com.arstem.backend.user.service;

import java.util.Locale;
import java.util.Optional;
import java.util.Set;

import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;

import com.arstem.backend.common.exception.ConflictException;
import com.arstem.backend.user.domain.Role;
import com.arstem.backend.user.domain.User;
import com.arstem.backend.user.domain.UserStatus;
import com.arstem.backend.user.repository.UserRepository;

@Service
public class UserService {

    private final UserRepository userRepository;

    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public User createStudent(String displayName, String email, String passwordHash) {
        String normalizedEmail = normalizeEmail(email);
        if (userRepository.existsByEmail(normalizedEmail)) {
            throw new ConflictException("An account with this email already exists.");
        }

        User user = new User(displayName.trim(), normalizedEmail, passwordHash, Set.of(Role.STUDENT), UserStatus.ACTIVE);
        user.markCreated();
        try {
            return userRepository.save(user);
        } catch (DuplicateKeyException exception) {
            throw new ConflictException("An account with this email already exists.");
        }
    }

    public Optional<User> findByEmail(String email) {
        return userRepository.findByEmail(normalizeEmail(email));
    }

    private String normalizeEmail(String email) {
        return email.trim().toLowerCase(Locale.ROOT);
    }
}
