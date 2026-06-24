package com.arstem.backend.user.domain;

import java.time.Instant;
import java.util.HashSet;
import java.util.Set;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

@Document(collection = "users")
public class User {

    @Id
    private String id;

    private String displayName;

    @Indexed(unique = true)
    private String email;

    private String passwordHash;

    private Set<Role> roles = new HashSet<>();

    private UserStatus status;

    private Instant createdAt;

    private Instant updatedAt;

    public User() {
    }

    public User(String displayName, String email, String passwordHash, Set<Role> roles, UserStatus status) {
        this.displayName = displayName;
        this.email = email;
        this.passwordHash = passwordHash;
        this.roles = new HashSet<>(roles);
        this.status = status;
    }

    public void markCreated() {
        Instant now = Instant.now();
        this.createdAt = now;
        this.updatedAt = now;
    }

    public void markUpdated() {
        this.updatedAt = Instant.now();
    }

    public String getId() { return id; }
    public String getDisplayName() { return displayName; }
    public String getEmail() { return email; }
    public String getPasswordHash() { return passwordHash; }
    public Set<Role> getRoles() { return Set.copyOf(roles); }
    public UserStatus getStatus() { return status; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
}
