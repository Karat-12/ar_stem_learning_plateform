package com.arstem.backend.auth.api;

/** Response returned after successful authentication. */
public record TokenResponse(String token, String tokenType) {
}
