# Adaptive Interactive STEM Learning Framework — Backend Architecture

## 1. Architecture goals and scope

The current Flutter application is a UI-first interactive learning cockpit. It already models learner actions and local rule-based feedback for Data Structures (linked lists, stacks, binary trees), Digital Electronics (logic gates, XOR, complex gates, truth tables), and Organic Chemistry (hydrocarbons, sugars, functional groups, bonds). AR and the progress tracker are deliberately placeholders.

Phase 1 creates the durable learning platform beneath those experiences. The backend must receive observable learner events, identify and aggregate misconceptions, maintain a learning history, provide analytics and adaptive next steps, and act as the controlled gateway to future AI and AR systems. It must not duplicate Flutter's immediate interaction rendering; the client remains responsible for low-latency visual feedback, while the backend persists authoritative learning records and returns durable/adaptive guidance.

**Stack:** Java 21, Spring Boot 3.x, Maven, Spring Data MongoDB, MongoDB Atlas, Spring Security, JWT, REST/JSON. Use a modular monolith initially: independently testable feature packages in one deployable service. This keeps transactions, deployment, and team velocity simple while preserving clean extraction boundaries for a future AI worker or AR service.

### Architectural principles

- Version every lab/topic and event payload so laboratory rules can evolve without corrupting history.
- Derive `userId` from the verified JWT; never trust a user ID supplied by a learner client.
- Store raw, immutable learning events in sessions/misconceptions and maintain read-optimized progress summaries separately.
- Use stable, domain-neutral identifiers: `domainCode`, `topicCode`, `activityCode`, `misconceptionCode`.
- Let the backend validate reported event types and activity ownership; it does not need to replay every drag gesture in Phase 1.
- Treat AI output as untrusted, versioned educational content: validate, log provenance, cache/reuse where suitable, and retain a moderation/status field.
- Make AR a first-class activity mode and event source now, without building camera/scene logic yet.

### System context

```text
Flutter client ──HTTPS/JWT──> Spring Boot API ──> MongoDB Atlas
                                 │       │
                                 │       └──> AI service (private HTTP/API gateway)
                                 │
Future AR client ──HTTPS/JWT─────┘

Admin tools ──────HTTPS/JWT──────> Spring Boot API
```

The API is the only client-facing system of record. The AI service is never exposed directly to Flutter; this protects provider keys, allows rate limits and safety checks, and makes provider changes invisible to the app.

---

## 2. Backend folder structure

```text
backend/
├── pom.xml
├── README.md
├── BACKEND_ARCHITECTURE.md
├── src/
│   ├── main/
│   │   ├── java/com/arstem/learning/
│   │   │   ├── AdaptiveStemApplication.java
│   │   │   ├── auth/
│   │   │   │   ├── api/                 # register/login/refresh/logout DTOs and controller
│   │   │   │   ├── service/             # credential and token lifecycle
│   │   │   │   └── model/               # refresh-token persistence if enabled
│   │   │   ├── user/
│   │   │   │   ├── api/                 # profile endpoints and DTOs
│   │   │   │   ├── domain/              # User, Role, learner preferences
│   │   │   │   ├── repository/
│   │   │   │   └── service/
│   │   │   ├── topic/
│   │   │   │   ├── api/                 # catalog endpoints
│   │   │   │   ├── domain/              # domain/topic/activity metadata
│   │   │   │   ├── repository/
│   │   │   │   └── service/
│   │   │   ├── session/
│   │   │   │   ├── api/                 # start, heartbeat/events, end
│   │   │   │   ├── domain/              # LearningSession and activity event DTOs
│   │   │   │   ├── repository/
│   │   │   │   └── service/
│   │   │   ├── misconception/
│   │   │   │   ├── api/                 # report/list/resolve endpoints
│   │   │   │   ├── domain/              # occurrence, severity, status, detector metadata
│   │   │   │   ├── repository/
│   │   │   │   └── service/             # validation, dedupe, aggregation, remediation rules
│   │   │   ├── progress/
│   │   │   │   ├── api/                 # learner dashboard and history endpoints
│   │   │   │   ├── domain/              # denormalized topic progress/read models
│   │   │   │   ├── repository/
│   │   │   │   └── service/             # projections, mastery and weak-area calculation
│   │   │   ├── quiz/
│   │   │   │   ├── api/                 # quiz discovery/delivery/submission
│   │   │   │   ├── domain/              # Quiz, Question, QuizAttempt
│   │   │   │   ├── repository/
│   │   │   │   └── service/             # grading, attempt policy, scoring
│   │   │   ├── ai/
│   │   │   │   ├── api/                 # explanation, hint, revision, generation endpoints
│   │   │   │   ├── client/              # typed client for the external AI service
│   │   │   │   ├── domain/              # request context, stored explanation/question records
│   │   │   │   ├── repository/
│   │   │   │   └── service/             # prompt context assembly, validation, caching/audit
│   │   │   ├── ar/
│   │   │   │   ├── api/                 # reserved activity/session context endpoints
│   │   │   │   ├── domain/              # AR activity/content references (Phase 1 metadata only)
│   │   │   │   └── service/
│   │   │   ├── security/
│   │   │   │   ├── JwtAuthenticationFilter.java
│   │   │   │   ├── JwtService.java
│   │   │   │   ├── SecurityConfig.java
│   │   │   │   └── CurrentUser.java     # principal/current-user helper
│   │   │   ├── config/                  # Mongo, CORS, Jackson, OpenAPI, properties
│   │   │   └── common/
│   │   │       ├── api/                 # ApiResponse, pagination, error DTOs
│   │   │       ├── exception/           # mapped domain exceptions/global handler
│   │   │       ├── validation/          # shared validators
│   │   │       ├── audit/               # request/audit metadata
│   │   │       └── util/
│   │   └── resources/
│   │       ├── application.yml
│   │       ├── application-dev.yml
│   │       ├── application-prod.yml
│   │       └── db/seed/                 # versioned topic/quiz seed data, never user data
│   └── test/java/com/arstem/learning/
│       └── ... mirrors main packages
└── docs/                                # OpenAPI exports, ADRs, event-contract examples
```

Each feature owns its API DTOs, domain model, repository, and application service. Cross-feature calls happen through public service interfaces/events—not by one feature reaching into another feature's repository. `common` contains only genuinely shared technical concerns, avoiding a catch-all business-logic package.

---

## 3. MongoDB schema design

### Shared conventions

All IDs are MongoDB `ObjectId` values serialized to strings in the API. Store references as `ObjectId` in Mongo where feasible. All time fields are UTC BSON dates. Use `createdAt`, `updatedAt`, and an optional `schemaVersion` on mutable documents. `topicCode` values are stable slugs such as `dsa.linked-list` and `electronics.xor-builder`; display titles may change.

Recommended indexes are noted after each collection. MongoDB Atlas encryption at rest is enabled; no password, JWT, or AI provider credential is stored in documents.

### 3.1 `users`

**Purpose:** identity, authorization, learner preferences, and lightweight profile data. One document per account.

**Fields:** `_id`, `email` (normalized/lowercase), `passwordHash` (Argon2id or BCrypt), `displayName`, `roles` (`[STUDENT]` or `[ADMIN]`), `status` (`ACTIVE|DISABLED`), `preferences` (`locale`, `difficultyPreference`, `accessibility`), `lastLoginAt`, `createdAt`, `updatedAt`, `schemaVersion`.

```json
{
  "_id": { "$oid": "665000000000000000000001" },
  "email": "aisha@example.edu",
  "passwordHash": "$argon2id$...",
  "displayName": "Aisha Khan",
  "roles": ["STUDENT"],
  "status": "ACTIVE",
  "preferences": { "locale": "en-IN", "difficultyPreference": "ADAPTIVE" },
  "lastLoginAt": { "$date": "2026-06-20T16:42:00Z" },
  "createdAt": { "$date": "2026-06-20T16:00:00Z" },
  "updatedAt": { "$date": "2026-06-20T16:42:00Z" },
  "schemaVersion": 1
}
```

**Indexes:** unique `{email: 1}`; `{status: 1}` for administration.

### 3.2 `learning_sessions`

**Purpose:** an immutable-ish record of one continuous learning visit. It ties client actions, misconception occurrences, quiz attempts, duration, and future AR activity to one context.

**Fields:** `_id`, `userId`, `domainCode`, `topicCode`, `activityCode`, `activityVersion`, `mode` (`FLUTTER_2D|AR`), `status` (`ACTIVE|COMPLETED|ABANDONED`), `startedAt`, `lastActivityAt`, `endedAt`, `durationSeconds`, `eventSummary` (counts by action/event type), `outcome` (completion, score, mastery delta), `client` (app version/platform), `metadata` (safe, bounded lab state summary), timestamps.

```json
{
  "_id": { "$oid": "665000000000000000000101" },
  "userId": { "$oid": "665000000000000000000001" },
  "domainCode": "dsa",
  "topicCode": "dsa.linked-list",
  "activityCode": "linked-list-playground",
  "activityVersion": "1.0.0",
  "mode": "FLUTTER_2D",
  "status": "COMPLETED",
  "startedAt": { "$date": "2026-06-20T16:45:00Z" },
  "lastActivityAt": { "$date": "2026-06-20T16:53:17Z" },
  "endedAt": { "$date": "2026-06-20T16:54:02Z" },
  "durationSeconds": 542,
  "eventSummary": { "nodeInserted": 2, "traversalRun": 2, "misconceptionReported": 1 },
  "outcome": { "completionStatus": "COMPLETED", "score": 80, "masteryDelta": 0.08 },
  "client": { "platform": "windows", "appVersion": "0.1.0" },
  "metadata": { "finalNodeCount": 5, "finalTraversal": "FORWARD" },
  "createdAt": { "$date": "2026-06-20T16:45:00Z" },
  "updatedAt": { "$date": "2026-06-20T16:54:02Z" }
}
```

**Indexes:** `{userId:1, startedAt:-1}`, `{userId:1, topicCode:1, startedAt:-1}`, `{status:1, lastActivityAt:1}` for stale-session cleanup.

### 3.3 `misconceptions`

**Purpose:** one detected or reported misconception occurrence, linked to a user and session. This is the evidence layer; progress holds the aggregate view.

**Fields:** `_id`, `userId`, `sessionId`, `domainCode`, `topicCode`, `activityCode`, `misconceptionCode`, `category`, `severity` (`LOW|MEDIUM|HIGH`), `source` (`CLIENT_RULE|SERVER_RULE|QUIZ_GRADING|AI_REVIEW|AR`), `status` (`OPEN|ACKNOWLEDGED|PRACTICED|RESOLVED`), `occurredAt`, `eventId` (client idempotency key), `trigger` (event type + safe parameters), `evidence` (expected vs observed, no raw sensitive data), `feedbackShown`, `remediation` (suggested activity/quiz), `resolvedAt`, timestamps.

```json
{
  "_id": { "$oid": "665000000000000000000201" },
  "userId": { "$oid": "665000000000000000000001" },
  "sessionId": { "$oid": "665000000000000000000101" },
  "domainCode": "dsa",
  "topicCode": "dsa.linked-list",
  "activityCode": "linked-list-playground",
  "misconceptionCode": "DSA_BROKEN_LINKED_LIST",
  "category": "STRUCTURE_INVARIANT",
  "severity": "MEDIUM",
  "source": "CLIENT_RULE",
  "status": "OPEN",
  "occurredAt": { "$date": "2026-06-20T16:50:12Z" },
  "eventId": "f8c20da5-0c37-4e78-b682-7db1b9a7f913",
  "trigger": { "eventType": "LINK_VALIDATION_FAILED", "ruleVersion": "1.0", "parameters": { "brokenEdgeCount": 1 } },
  "evidence": { "expected": "connected path from head", "observed": "missing next link after node B" },
  "feedbackShown": true,
  "remediation": { "type": "ACTIVITY", "targetCode": "dsa.linked-list.repair-links" },
  "createdAt": { "$date": "2026-06-20T16:50:12Z" },
  "updatedAt": { "$date": "2026-06-20T16:50:12Z" }
}
```

**Indexes:** unique `{userId:1, eventId:1}`; `{userId:1, topicCode:1, occurredAt:-1}`; `{sessionId:1}`; `{misconceptionCode:1, occurredAt:-1}` for aggregate reporting.

### 3.4 `progress`

**Purpose:** one read-optimized learner-topic projection, updated when sessions, misconceptions, and quiz attempts change. It powers the Flutter Progress Tracker without expensive aggregation across large history collections.

**Fields:** `_id`, `userId`, `topicCode`, `domainCode`, `completionStatus` (`NOT_STARTED|IN_PROGRESS|COMPLETED|MASTERED`), `completionPercent`, `masteryScore` (0–100), `bestQuizScore`, `latestQuizScore`, `totalAttempts`, `totalSessionSeconds`, `lastActivityAt`, `weakAreas` (misconception code, severity, occurrence count, last seen), `recommendedNext` (type/code/reason), `historySummary` (first/last completed, streak), `calculationVersion`, timestamps.

```json
{
  "_id": { "$oid": "665000000000000000000301" },
  "userId": { "$oid": "665000000000000000000001" },
  "topicCode": "dsa.linked-list",
  "domainCode": "dsa",
  "completionStatus": "IN_PROGRESS",
  "completionPercent": 65,
  "masteryScore": 58,
  "bestQuizScore": 70,
  "latestQuizScore": 60,
  "totalAttempts": 3,
  "totalSessionSeconds": 1460,
  "lastActivityAt": { "$date": "2026-06-20T16:54:02Z" },
  "weakAreas": [
    { "misconceptionCode": "DSA_BROKEN_LINKED_LIST", "severity": "MEDIUM", "occurrenceCount": 2, "lastSeenAt": { "$date": "2026-06-20T16:50:12Z" } }
  ],
  "recommendedNext": { "type": "PRACTICE_ACTIVITY", "code": "dsa.linked-list.repair-links", "reason": "Repair pointer connections before retrying traversal." },
  "historySummary": { "firstStartedAt": { "$date": "2026-06-18T10:00:00Z" }, "lastCompletedAt": null, "activeDaysLast30": 2 },
  "calculationVersion": "1.0",
  "createdAt": { "$date": "2026-06-18T10:00:00Z" },
  "updatedAt": { "$date": "2026-06-20T16:54:02Z" }
}
```

**Indexes:** unique `{userId:1, topicCode:1}`; `{userId:1, domainCode:1}`; `{userId:1, lastActivityAt:-1}`.

### 3.5 `quizzes`

**Purpose:** curated/admin-approved quiz definitions. AI-created questions only become public quiz material after validation/approval; dynamic questions remain in `ai_generated_questions` until promoted.

**Fields:** `_id`, `quizCode`, `title`, `domainCode`, `topicCode`, `activityCode` (optional), `version`, `status` (`DRAFT|PUBLISHED|ARCHIVED`), `difficulty`, `tags`, `questions` (embedded ordered items with `questionId`, type, prompt, options, answer key, explanation, misconceptionMappings), `attemptPolicy`, `createdBy`, timestamps.

```json
{
  "_id": { "$oid": "665000000000000000000401" },
  "quizCode": "dsa-linked-list-basics-v1",
  "title": "Linked List Foundations",
  "domainCode": "dsa",
  "topicCode": "dsa.linked-list",
  "version": 1,
  "status": "PUBLISHED",
  "difficulty": "BEGINNER",
  "tags": ["head-pointer", "traversal"],
  "questions": [
    {
      "questionId": "q1",
      "type": "SINGLE_CHOICE",
      "prompt": "Which reference identifies the first node?",
      "options": [{ "id": "a", "text": "head" }, { "id": "b", "text": "tail" }],
      "answerKey": { "optionIds": ["a"] },
      "explanation": "The head reference identifies the first node.",
      "misconceptionMappings": [{ "incorrectOptionId": "b", "misconceptionCode": "DSA_HEAD_POINTER_MISSING" }]
    }
  ],
  "attemptPolicy": { "maxAttempts": null, "showFeedback": "AFTER_SUBMISSION" },
  "createdBy": { "type": "ADMIN", "userId": { "$oid": "665000000000000000000099" } },
  "createdAt": { "$date": "2026-06-20T10:00:00Z" },
  "updatedAt": { "$date": "2026-06-20T10:00:00Z" }
}
```

**Indexes:** unique `{quizCode:1, version:1}`; `{status:1, topicCode:1, difficulty:1}`. The server never returns `answerKey` to a student before grading.

### 3.6 `quiz_attempts`

**Purpose:** immutable learner submissions and grading outcome, optionally tied to a learning session.

**Fields:** `_id`, `userId`, `quizId`, `quizCode`, `quizVersion`, `sessionId` (optional), `topicCode`, `attemptNumber`, `status` (`IN_PROGRESS|SUBMITTED|GRADED`), `startedAt`, `submittedAt`, `answers`, `questionResults` (correctness, score, mapped misconception codes), `score`, `maxScore`, `percentage`, `durationSeconds`, `createdAt`.

```json
{
  "_id": { "$oid": "665000000000000000000501" },
  "userId": { "$oid": "665000000000000000000001" },
  "quizId": { "$oid": "665000000000000000000401" },
  "quizCode": "dsa-linked-list-basics-v1",
  "quizVersion": 1,
  "sessionId": { "$oid": "665000000000000000000101" },
  "topicCode": "dsa.linked-list",
  "attemptNumber": 2,
  "status": "GRADED",
  "startedAt": { "$date": "2026-06-20T16:55:00Z" },
  "submittedAt": { "$date": "2026-06-20T16:57:00Z" },
  "answers": [{ "questionId": "q1", "selectedOptionIds": ["b"] }],
  "questionResults": [{ "questionId": "q1", "correct": false, "earnedScore": 0, "misconceptionCodes": ["DSA_HEAD_POINTER_MISSING"] }],
  "score": 0,
  "maxScore": 1,
  "percentage": 0,
  "durationSeconds": 120,
  "createdAt": { "$date": "2026-06-20T16:57:00Z" }
}
```

**Indexes:** `{userId:1, topicCode:1, submittedAt:-1}`, `{userId:1, quizId:1, attemptNumber:-1}`, `{sessionId:1}`.

### 3.7 `ai_explanations`

**Purpose:** auditable, reusable AI explanations, hints, and revision suggestions returned by the backend.

**Fields:** `_id`, `userId`, `sessionId` (optional), `topicCode`, `activityCode` (optional), `misconceptionCode` (optional), `requestType` (`EXPLANATION|HINT|REVISION`), `requestContext` (sanitized/size-limited), `response` (content, format, suggested actions), `provider` (service/model), `promptVersion`, `status` (`GENERATED|VALIDATED|REJECTED|EXPIRED`), `contentHash`, `generatedAt`, `expiresAt` (optional), timestamps.

```json
{
  "_id": { "$oid": "665000000000000000000601" },
  "userId": { "$oid": "665000000000000000000001" },
  "sessionId": { "$oid": "665000000000000000000101" },
  "topicCode": "dsa.linked-list",
  "activityCode": "linked-list-playground",
  "misconceptionCode": "DSA_BROKEN_LINKED_LIST",
  "requestType": "EXPLANATION",
  "requestContext": { "learnerLevel": "BEGINNER", "recentOccurrenceCount": 2 },
  "response": { "content": "A linked list remains reachable only when every node points to the next node...", "format": "MARKDOWN", "suggestedActions": ["repair-links", "retry-traversal"] },
  "provider": { "service": "ai-service", "model": "configured-model" },
  "promptVersion": "explanation-v1",
  "status": "VALIDATED",
  "contentHash": "sha256:...",
  "generatedAt": { "$date": "2026-06-20T16:51:00Z" },
  "createdAt": { "$date": "2026-06-20T16:51:00Z" },
  "updatedAt": { "$date": "2026-06-20T16:51:00Z" }
}
```

**Indexes:** `{userId:1, topicCode:1, generatedAt:-1}`, `{contentHash:1}`, TTL `{expiresAt:1}` only if expiration is used.

### 3.8 `ai_generated_questions`

**Purpose:** generated question candidates and personalized practice sets, separate from curated quizzes until validated or explicitly delivered to a learner.

**Fields:** `_id`, `userId` (optional for reusable candidate), `topicCode`, `misconceptionCode` (optional), `generationRequestId`, `sourceExplanationId` (optional), `question` (same safe question shape as quizzes), `difficulty`, `generationContext`, `provider`, `promptVersion`, `validation` (schema/safety/reviewer state), `lifecycleStatus` (`CANDIDATE|APPROVED|DELIVERED|REJECTED|PROMOTED`), `expiresAt` (personalized questions), timestamps.

```json
{
  "_id": { "$oid": "665000000000000000000701" },
  "userId": { "$oid": "665000000000000000000001" },
  "topicCode": "electronics.xor-builder",
  "misconceptionCode": "ELECTRONICS_INVALID_XOR_CONSTRUCTION",
  "generationRequestId": "0fd1db48-88a3-4c68-857d-e8dd0f6fd0c8",
  "question": { "type": "SINGLE_CHOICE", "prompt": "Which combination can form XOR?", "options": [{ "id": "a", "text": "..." }], "answerKey": { "optionIds": ["a"] }, "explanation": "..." },
  "difficulty": "INTERMEDIATE",
  "generationContext": { "purpose": "REMEDIATION", "targetSkill": "xor-construction" },
  "provider": { "service": "ai-service", "model": "configured-model" },
  "promptVersion": "question-v1",
  "validation": { "schemaValid": true, "safetyStatus": "PASSED", "reviewStatus": "AUTO_APPROVED" },
  "lifecycleStatus": "DELIVERED",
  "expiresAt": { "$date": "2026-07-20T00:00:00Z" },
  "createdAt": { "$date": "2026-06-20T17:00:00Z" },
  "updatedAt": { "$date": "2026-06-20T17:00:00Z" }
}
```

**Indexes:** `{userId:1, topicCode:1, createdAt:-1}`, `{lifecycleStatus:1, topicCode:1}`, TTL `{expiresAt:1}` for personal question retention.

### Reference catalog decision

The listed required collections intentionally cover learner data. Add a version-controlled `topics` collection (or load a static catalog from seed JSON) before implementation because `GET /topics` needs a canonical catalog, prerequisites, activity metadata, and allowed misconception codes. Keep topic definitions admin-managed and versioned; learner documents retain their stable codes/version snapshots.

---

## 4. Authentication and authorization

### Registration

`POST /api/v1/auth/register` accepts display name, email, and password over TLS. Validate format and password policy; normalize email; reject duplicates; hash password with Argon2id (preferred) or BCrypt; create a user with role `STUDENT` only. Admin creation is never exposed through public registration.

### Login and JWT lifecycle

`POST /api/v1/auth/login` validates credentials and returns a short-lived signed access token (for example 15 minutes) plus a longer-lived refresh token (for example 7–30 days). Store refresh tokens as hashed, revocable records if refresh/logout is implemented in Phase 1. The Flutter client stores tokens only in secure platform storage and sends `Authorization: Bearer <accessToken>`.

The JWT contains only necessary claims: `sub` = user ID, `email`, `roles`, `iat`, `exp`, `jti`, and issuer/audience. It is signed with a strong secret managed outside source control (or asymmetric keys managed by a secret manager). `JwtAuthenticationFilter` verifies signature, issuer, audience, expiry, and populates Spring Security's principal. Passwords and sensitive profile data never appear in a token.

### Role policy

| Role | Permissions |
| --- | --- |
| `STUDENT` | Own profile, own sessions/events/misconceptions/progress/attempts, published topics/quizzes, AI requests scoped to self. |
| `ADMIN` | Student permissions plus topic/quiz lifecycle management, generated-question review/promotion, aggregate analytics, user/status administration. |

Object-level authorization is mandatory: `/progress/{userId}` permits the owning student or an admin only. Prefer `/progress/me` for Flutter, which removes accidental identity misuse. Apply method-level role checks to admin routes and ownership checks in services.

### Operational safeguards

- CORS allowlist for approved Flutter web origins; mobile apps do not rely on permissive CORS.
- HTTPS only in deployed environments, rate limit registration/login/AI routes, and use generic failed-login errors.
- Validate DTOs, enforce request size limits, redact authorization headers and sensitive fields in logs.
- Record admin content changes in an audit log (a future optional collection).

---

## 5. Misconception engine

### Model

The engine is domain-independent in shape and domain-specific in rules. A `MisconceptionDefinition` in the topic catalog specifies code, topic/activity applicability, severity defaults, accepted event types, rule version, and remediation targets. The client can perform immediate local detection for a fluid experience; the server verifies the code/event/activity pairing, stores evidence, and updates progress. Later, equivalent server rules can independently derive findings from rich event data.

Initial controlled vocabulary:

| Domain | Codes |
| --- | --- |
| Data Structures | `DSA_STACK_UNDERFLOW`, `DSA_STACK_OVERFLOW`, `DSA_INVALID_TRAVERSAL`, `DSA_BROKEN_LINKED_LIST`, `DSA_HEAD_POINTER_MISSING`, `DSA_TREE_HIERARCHY_INVALID` |
| Digital Electronics | `ELECTRONICS_INVALID_XOR_CONSTRUCTION`, `ELECTRONICS_INCORRECT_OUTPUT`, `ELECTRONICS_INVALID_GATE_CONNECTION` |
| Organic Chemistry | `CHEMISTRY_INVALID_VALENCY`, `CHEMISTRY_INCORRECT_BOND_STRUCTURE`, `CHEMISTRY_HYDROGEN_COUNT_MISMATCH` |

### Frontend event flow

1. Flutter starts a session before entering a lab and receives `sessionId`.
2. A lab action triggers existing local validation. For example: POP on an empty stack; linked-list connection broken; XOR wiring invalid; carbon valency exceeded.
3. Flutter immediately shows its current feedback, then sends a compact idempotent event to `POST /api/v1/misconceptions` with the session ID, topic/activity codes, event ID, supported code, source, and safe evidence summary.
4. The backend obtains `userId` from JWT, verifies the session belongs to that user and the event is allowed for the activity, then de-duplicates by `(userId,eventId)`.
5. It creates a `misconceptions` occurrence, updates the topic `progress` projection atomically/eventually, and returns a remediation recommendation. Repeated evidence raises weak-area priority; a later successful remediation or high-confidence quiz result may mark earlier occurrences `RESOLVED`.
6. The session is ended with duration/outcome; its summary is used in history and mastery computation.

Example request (user identity is deliberately absent):

```json
{
  "eventId": "f8c20da5-0c37-4e78-b682-7db1b9a7f913",
  "sessionId": "665000000000000000000101",
  "domainCode": "dsa",
  "topicCode": "dsa.linked-list",
  "activityCode": "linked-list-playground",
  "misconceptionCode": "DSA_BROKEN_LINKED_LIST",
  "source": "CLIENT_RULE",
  "trigger": { "eventType": "LINK_VALIDATION_FAILED", "ruleVersion": "1.0" },
  "evidence": { "brokenEdgeCount": 1 }
}
```

### Dedupe, severity, and resolution

Do not create a fresh finding every animation frame. The client should emit at meaningful moments, and the service should treat the same event ID as idempotent; it can also coalesce identical signals in a short configurable window. Severity is based on the definition plus recency/frequency. An occurrence is evidence, not a permanent label: `OPEN → ACKNOWLEDGED → PRACTICED → RESOLVED`, with resolution driven by successful targeted activity, improved quiz performance, or a configurable rule. Preserve the original occurrence even when resolved so analytics remain honest.

---

## 6. Progress tracking and adaptive learning

### What is tracked

- **Topic completion:** activity milestones and completed session outcomes update `completionPercent` and `completionStatus`.
- **Scores:** store immutable quiz-attempt scores; `progress` keeps latest/best values for fast dashboards.
- **Weak areas:** rank open/recent misconception codes by severity, frequency, persistence, and related quiz errors.
- **Attempts:** count activity and quiz attempts, retaining exact attempts in `learning_sessions` and `quiz_attempts`.
- **Learning history:** sessions form the chronological timeline; progress documents provide current state only.

### Initial mastery calculation

Use an explicit, versioned and explainable formula—not a hidden AI score:

```text
mastery = clamp(0, 100,
  0.45 × normalized recent quiz score
  + 0.25 × activity completion score
  + 0.20 × successful remediation score
  + 0.10 × consistency score
  − misconception persistence penalty)
```

Weights and the `calculationVersion` belong in configuration. Recalculate the affected user/topic projection synchronously for Phase 1 after a graded attempt or significant misconception event; move projection updates to an asynchronous queue only when scale demands it. The response should expose a short human-readable reason for recommendations, e.g. “Practise XOR construction: two invalid constructions in the last session.”

### API read model

`GET /api/v1/progress/me` returns cross-topic dashboard cards, domain summaries, current weak areas, and recommendations. `GET /api/v1/progress/me/topics/{topicCode}` returns the detailed projection and paginated links to learning sessions, misconceptions, and attempts. This gives the future Flutter Progress Tracker a small fast initial load plus drill-down routes.

---

## 7. AI integration

### Responsibilities

The backend requests four narrowly typed AI capabilities:

1. **Explanation generation** for a concept or detected misconception.
2. **Hint generation** that helps the learner act without simply revealing the answer.
3. **Quiz/question generation** targeted to topic, difficulty, and weak area.
4. **Personalized revision suggestions** based on the learner's progress projection and recent history.

### Request and response flow

```text
Flutter request + JWT
  → API authenticates, authorizes, rate-limits, validates topic/session
  → AI service builds a minimized prompt from catalog + learner context
  → AI provider returns structured JSON
  → API validates schema, size, policy/status, persists provenance
  → API returns safe response DTO to Flutter
```

The API should send only the necessary pedagogical context: topic, activity, learner level, active misconception codes, aggregate recent performance, and an explicit output schema. Avoid sending email, name, raw device data, or a full unbounded learning history. The AI service/provider endpoint and credentials stay server-side.

### Storage strategy

- Persist every delivered explanation/hint/revision result in `ai_explanations`, including model/provider, prompt version, sanitized request context, validation state, and content hash.
- Persist generated question candidates in `ai_generated_questions`; validate their schema and educational constraints before delivery. Never directly add an AI candidate to a published shared `quizzes` document.
- Reuse a validated explanation when topic + misconception + learner-level + prompt version match, subject to freshness rules. Personal revision advice is normally user-specific and should be short-lived.
- Store only compact structured outputs; large transcripts/debug prompts belong in protected observability tooling only if retention policy allows it.

### Failure behavior

AI is an enhancement, not a dependency for core labs. On timeout/provider failure, return a stable fallback: the catalog's rule-based explanation/remediation and a retriable error code. Never block session completion or misconception persistence on an AI response. Use request IDs, timeouts, circuit breaking, and rate limits.

---

## 8. REST API design

### Conventions

- Base path: `/api/v1`; JSON; UTC ISO-8601 timestamps; `Authorization: Bearer` on protected routes.
- The authenticated learner is represented by `me`; IDs in paths are for admin/cross-user use only.
- Successful writes return `201` for create, `200` for computed action, or `204` for no body. Use `409` for duplicate email/idempotency conflict where appropriate, `422` for semantically invalid lab events, and a consistent problem-error body: `{ "code", "message", "traceId", "fieldErrors" }`.
- Paginated resources accept `page`, `size`, `sort`; cap page size. Mutating event endpoints accept `Idempotency-Key` or a request `eventId`.

### Authentication and user

| Method | Endpoint | Access | Responsibility |
| --- | --- | --- | --- |
| POST | `/auth/register` | Public | Create a `STUDENT` account. |
| POST | `/auth/login` | Public | Issue access and refresh tokens. |
| POST | `/auth/refresh` | Public with refresh token | Rotate/reissue access token. |
| POST | `/auth/logout` | Authenticated | Revoke refresh token/current device session. |
| GET | `/users/me` | Student/Admin | Read own profile and roles. |
| PATCH | `/users/me` | Student/Admin | Update safe profile/preferences. |
| GET | `/admin/users` | Admin | Search/manage learners. |
| PATCH | `/admin/users/{userId}/status` | Admin | Disable/enable account. |

### Topic catalog and sessions

| Method | Endpoint | Access | Responsibility |
| --- | --- | --- | --- |
| GET | `/topics` | Authenticated | Domains, topics, activities, prerequisites, supported codes. |
| GET | `/topics/{topicCode}` | Authenticated | Detailed topic and activity metadata. |
| POST | `/sessions/start` | Student/Admin | Open a lab/quiz/AR session. |
| POST | `/sessions/{sessionId}/events` | Owner/Admin | Record approved compact learning events/heartbeats. |
| POST | `/sessions/{sessionId}/end` | Owner/Admin | Finalize outcome/duration and update progress. |
| GET | `/sessions/me` | Student/Admin | Paginated personal learning history. |
| GET | `/sessions/{sessionId}` | Owner/Admin | Read one session. |

### Misconceptions and progress

| Method | Endpoint | Access | Responsibility |
| --- | --- | --- | --- |
| POST | `/misconceptions` | Student/Admin | Report one validated, idempotent misconception occurrence. |
| GET | `/misconceptions/me` | Student/Admin | List/filter own occurrences. |
| PATCH | `/misconceptions/{id}` | Owner/Admin | Acknowledge or record remediation status (server controls resolution rules). |
| GET | `/progress/me` | Student/Admin | Dashboard projection: domains, topic cards, weak areas, recommendations. |
| GET | `/progress/me/topics/{topicCode}` | Student/Admin | Detailed topic analytics and history summary. |
| GET | `/progress/{userId}` | Admin or owner | Administrative/legacy equivalent; prefer `/me`. |

### Quizzes and attempts

| Method | Endpoint | Access | Responsibility |
| --- | --- | --- | --- |
| GET | `/quizzes` | Authenticated | Find published quizzes by topic/difficulty. |
| GET | `/quizzes/{quizId}` | Authenticated | Deliver quiz without answer keys. |
| POST | `/quizzes/{quizId}/attempts` | Student/Admin | Start an attempt, optionally tied to a session. |
| POST | `/quiz-attempts/{attemptId}/submit` | Owner/Admin | Submit answers; server grades, creates findings, updates progress. |
| GET | `/quiz-attempts/me` | Student/Admin | List personal attempt history. |
| POST | `/admin/quizzes` | Admin | Create draft quiz. |
| PATCH | `/admin/quizzes/{quizId}` | Admin | Edit/version/publish/archive quiz. |

### AI and future AR

| Method | Endpoint | Access | Responsibility |
| --- | --- | --- | --- |
| POST | `/ai/explanations` | Student/Admin | Explain a topic or active misconception. |
| POST | `/ai/hints` | Student/Admin | Return progressive hint for activity/question. |
| POST | `/ai/questions` | Student/Admin | Generate targeted practice questions. |
| POST | `/ai/revision-suggestions` | Student/Admin | Produce personalized revision plan. |
| GET | `/ai/explanations/me` | Student/Admin | Read explanation/history cache. |
| GET | `/ar/activities/{activityCode}/context` | Student/Admin | Reserved metadata/context for future AR client. |
| POST | `/ar/events` | Student/Admin | Reserved ingestion route using the same session/event contract. |
| GET | `/admin/ai/generated-questions` | Admin | Review/reject/promote generated question candidates. |

For the user-provided examples, the canonical equivalents are `POST /api/v1/auth/register`, `POST /api/v1/auth/login`, `GET /api/v1/topics`, `POST /api/v1/sessions/start`, `POST /api/v1/sessions/{id}/end`, `POST /api/v1/misconceptions`, `GET /api/v1/progress/me`, `POST /api/v1/ai/explanations`, and `POST /api/v1/ai/questions`.

---

## 9. Development roadmap

### Phase 1A — foundation and contracts

1. Initialize the Spring Boot/Maven Java 21 service; define environment configuration and secret handling.
2. Implement MongoDB Atlas connectivity, indexes, health checks, standard error envelope, OpenAPI contract, CORS, and test profile.
3. Seed the canonical topic/activity/misconception catalog matching the current Flutter labs.
4. Implement registration, login, JWT filter, refresh-token decision, roles, and ownership tests.

**Exit criteria:** secured service deploys to a non-production Atlas database; Flutter can register/login and fetch topics.

### Phase 1B — learning telemetry and misconception persistence

1. Implement learning session start/event/end with idempotency and activity validation.
2. Implement controlled misconception definitions, reporting, deduplication, evidence storage, and remediation response.
3. Add Flutter integration for the currently implemented feedback points: linked-list missing head/broken link/invalid traversal, stack overflow/underflow, gate errors, and chemistry validation errors.

**Exit criteria:** a learner's real lab interaction is stored, traceable to a session, and safely linked to that learner.

### Phase 1C — progress, quizzes, and adaptation

1. Implement topic progress projections, mastery calculation versioning, dashboard/detail endpoints, and learning-history pagination.
2. Implement curated quiz delivery, server-side grading, misconception mappings, and attempt history.
3. Generate explainable next-activity recommendations from weak areas and prerequisites.

**Exit criteria:** the Progress Tracker can render persisted completion, scores, attempts, weak areas, and one justified next step.

### Phase 1D — AI gateway and operational hardening

1. Integrate the internal AI service through typed contracts, timeout/fallback, structured validation, rate limiting, and audit persistence.
2. Deliver explanations, hints, generated practice candidates, and personalized revision suggestions.
3. Add admin review/promotion for AI questions; metrics, tracing, backup/retention policy, security review, and load tests.

**Exit criteria:** AI improves the learning loop but a provider outage cannot prevent core learning persistence.

### Phase 2 — AR integration

1. Define AR activity manifests and asset/content references; keep assets in object storage/CDN, not MongoDB.
2. Have AR clients use the same JWT, topic catalog, session, and misconception event contracts with `mode: AR` and `source: AR`.
3. Add scene-level telemetry only after privacy, bandwidth, and educational-value requirements are agreed.

### Key decisions to confirm before implementation

- Token strategy: access-only initially versus access + rotating refresh tokens.
- Whether educator/classroom roles are in future scope (do not invent them yet; current requirement is `STUDENT` and `ADMIN`).
- The first supported Flutter event contract and the exact topic catalog identifiers.
- AI provider/service interface, moderation policy, retention period, and whether AI-generated content requires mandatory human review.
- Quantitative definition of topic completion/milestones for each existing lab.

---

## 10. Testing and deployment baseline

- Unit-test feature services, progress calculations, grading, misconception validation, and ownership checks.
- Use Spring integration tests with Testcontainers MongoDB (or an isolated test database) for indexes, query behavior, and repository mappings.
- Contract-test Flutter-facing JSON schemas and the AI service client; add idempotency/concurrency tests for event submission.
- In CI: compile on Java 21, run tests and static analysis, build immutable artifact/container, scan dependencies, deploy with environment-only configuration.
- In production: MongoDB Atlas least-privilege user, IP/private networking policy, backups, Atlas alerts, structured logs with trace IDs, metrics for latency/error rate, and secret-manager supplied values for Mongo/JWT/AI credentials.

This plan deliberately establishes a stable learning-data contract before adding implementation. It supports the present 2D Flutter labs immediately and lets AR become another activity mode rather than a parallel, incompatible product.
