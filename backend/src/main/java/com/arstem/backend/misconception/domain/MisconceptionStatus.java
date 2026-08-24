package com.arstem.backend.misconception.domain;

/**
 * Lifecycle state of a misconception.
 *
 * <p>ACTIVE   — the student has demonstrated this error and has not yet
 *               shown correct understanding in a subsequent assessment.
 *               Active misconceptions reduce mastery score and drive revision.
 *
 * <p>RESOLVED — the student later scored well enough on the topic assessment
 *               to prove the misconception was overcome.  Resolved records are
 *               kept for historical analytics but must never appear in AI Coach
 *               suggestions, mastery penalties, or weak-area lists.
 */
public enum MisconceptionStatus {
    ACTIVE,
    RESOLVED
}
