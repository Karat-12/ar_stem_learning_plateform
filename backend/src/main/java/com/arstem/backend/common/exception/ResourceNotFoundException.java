package com.arstem.backend.common.exception;

/** Raised when a requested API resource does not exist. */
public class ResourceNotFoundException extends RuntimeException {

    public ResourceNotFoundException(String message) {
        super(message);
    }
}
