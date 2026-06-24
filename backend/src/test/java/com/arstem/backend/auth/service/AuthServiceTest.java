package com.arstem.backend.auth.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

import java.util.Optional;
import java.util.Set;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Captor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

import com.arstem.backend.auth.api.LoginRequest;
import com.arstem.backend.auth.api.RegisterRequest;
import com.arstem.backend.common.exception.UnauthorizedException;
import com.arstem.backend.user.domain.Role;
import com.arstem.backend.user.domain.User;
import com.arstem.backend.user.domain.UserStatus;
import com.arstem.backend.user.service.UserService;
import com.arstem.backend.security.JwtService;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UserService userService;

    @Mock
    private JwtService jwtService;

    @Captor
    private ArgumentCaptor<String> passwordHashCaptor;

    @InjectMocks
    private AuthService authService;

    @BeforeEach
    void setUp() {
        authService = new AuthService(userService, new BCryptPasswordEncoder(4), jwtService);
    }

    @Test
    void registerHashesPasswordAndCreatesStudent() {
        User savedUser = new User("Karthik", "karthik@gmail.com", "hash", Set.of(Role.STUDENT), UserStatus.ACTIVE);
        savedUser.markCreated();
        when(userService.createStudent(any(), any(), any())).thenReturn(savedUser);

        authService.register(new RegisterRequest("Karthik", "KARTHIK@GMAIL.COM", "password123"));

        org.mockito.Mockito.verify(userService).createStudent(
                org.mockito.ArgumentMatchers.eq("Karthik"),
                org.mockito.ArgumentMatchers.eq("KARTHIK@GMAIL.COM"),
                passwordHashCaptor.capture());
        assertThat(passwordHashCaptor.getValue()).startsWith("$2");
        assertThat(new BCryptPasswordEncoder(4).matches("password123", passwordHashCaptor.getValue())).isTrue();
    }

    @Test
    void loginRejectsInvalidPassword() {
        User user = new User("Karthik", "karthik@gmail.com", new BCryptPasswordEncoder(4).encode("password123"),
                Set.of(Role.STUDENT), UserStatus.ACTIVE);
        when(userService.findByEmail("karthik@gmail.com")).thenReturn(Optional.of(user));

        assertThatThrownBy(() -> authService.login(new LoginRequest("karthik@gmail.com", "wrong-password")))
                .isInstanceOf(UnauthorizedException.class)
                .hasMessage("Invalid email or password.");
    }
}
