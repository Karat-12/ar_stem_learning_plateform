package com.arstem.backend.security;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;

class JwtServiceTest {

    private static final String BASE64_SECRET = "2VZxTJB9NQjZCtQ8o8a7z9b7bK7NLmc5Jj5nb9oWIVo=";

    @Test
    void generatesTokenThatCanBeValidatedForItsOwner() {
        JwtService jwtService = new JwtService(BASE64_SECRET, 60_000);
        UserDetails user = User.withUsername("karthik@gmail.com")
                .password("not-used")
                .authorities("ROLE_STUDENT")
                .build();

        String token = jwtService.generateAccessToken(user.getUsername());

        assertThat(jwtService.extractUsername(token)).isEqualTo("karthik@gmail.com");
        assertThat(jwtService.isTokenValid(token, user)).isTrue();
    }
}
