package com.arstem.backend.user.api;

import java.util.Set;

import com.arstem.backend.user.domain.Role;
import com.arstem.backend.user.domain.User;
import com.arstem.backend.user.domain.UserStatus;

/** Safe public representation of the authenticated user's profile. */
public record UserProfileResponse(String id, String displayName, String email, Set<Role> roles, UserStatus status) {
    public static UserProfileResponse from(User user) {
        return new UserProfileResponse(user.getId(), user.getDisplayName(), user.getEmail(), user.getRoles(), user.getStatus());
    }
}
