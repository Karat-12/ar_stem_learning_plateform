package com.arstem.backend.user.api;

import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.arstem.backend.common.exception.UnauthorizedException;
import com.arstem.backend.user.service.UserService;

@RestController
@RequestMapping("/api/v1/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping("/me")
    public UserProfileResponse me(Authentication authentication) {
        return userService.findByEmail(authentication.getName())
                .map(UserProfileResponse::from)
                .orElseThrow(() -> new UnauthorizedException("Authenticated user no longer exists."));
    }
}
