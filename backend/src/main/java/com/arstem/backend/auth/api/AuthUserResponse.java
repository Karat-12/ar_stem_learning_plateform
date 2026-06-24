package com.arstem.backend.auth.api;

import java.time.Instant;
import java.util.Set;

import com.arstem.backend.user.domain.Role;
import com.arstem.backend.user.domain.User;

public record AuthUserResponse(String id, String displayName, String email, Set<Role> roles, Instant createdAt) {
    public static AuthUserResponse from(User user) {
        return new AuthUserResponse(user.getId(), user.getDisplayName(), user.getEmail(), user.getRoles(), user.getCreatedAt());
    }
}
