package com.arstem.backend.auth.service;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import com.arstem.backend.auth.api.AuthUserResponse;
import com.arstem.backend.auth.api.LoginRequest;
import com.arstem.backend.auth.api.RegisterRequest;
import com.arstem.backend.common.exception.UnauthorizedException;
import com.arstem.backend.auth.api.TokenResponse;
import com.arstem.backend.security.JwtService;
import com.arstem.backend.user.domain.User;
import com.arstem.backend.user.domain.UserStatus;
import com.arstem.backend.user.service.UserService;

@Service
public class AuthService {

    private static final String INVALID_CREDENTIALS_MESSAGE = "Invalid email or password.";

    private final UserService userService;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public AuthService(UserService userService, PasswordEncoder passwordEncoder, JwtService jwtService) {
        this.userService = userService;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
    }

    public AuthUserResponse register(RegisterRequest request) {
        User user = userService.createStudent(
                request.displayName(),
                request.email(),
                passwordEncoder.encode(request.password()));
        return AuthUserResponse.from(user);
    }

    public TokenResponse login(LoginRequest request) {
        User user = userService.findByEmail(request.email())
                .orElseThrow(() -> new UnauthorizedException(INVALID_CREDENTIALS_MESSAGE));

        if (user.getStatus() != UserStatus.ACTIVE || !passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw new UnauthorizedException(INVALID_CREDENTIALS_MESSAGE);
        }
        return new TokenResponse(jwtService.generateAccessToken(user.getEmail()), "Bearer");
    }
}
