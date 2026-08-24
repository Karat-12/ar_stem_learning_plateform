# Adaptive Interactive STEM Learning Framework — Backend Architecture

> **Documentation status:** Updated to reflect the actual current implementation.
> Code is the source of truth. Planned features that are not implemented are clearly marked.

---

## 1. Overview

The backend is a **modular monolith** built on Spring Boot 3, Java 21, and MongoDB Atlas. It exposes a REST/JSON API consumed by the Flutter frontend. It receives learner events from the Flutter client, records misconceptions, persists session and quiz data, computes mastery analytics, and returns rule-based adaptive guidance.

**The backend does not contain any external AI/LLM integration.** All "AI" endpoints (`/api/v1/ai/*`) are rule-based algorithms computed locally from MongoDB data.

### Technology Stack

| Component | Technology | Version |
|---|---|---|
| Language | Java | 21 |
| Framework | Spring Boot | 3.5.15 |
| Security | Spring Security | BOM-managed |
| Data | Spring Data MongoDB | BOM-managed |
| JWT | jjwt | 0.12.6 (api + impl + jackson) |
| Password Hashing | BCrypt | Spring Security built-in |
| Validation | Spring Validation | BOM-managed |
| Database | MongoDB Atlas | Cloud |
| Build | Maven | — |
| Dev Tools | Spring DevTools, Lombok | Optional |

### System Context

```
Flutter client ──HTTPS/JWT──> Spring Boot API ──> MongoDB Atlas
                                    │
                             Rule-based AI services
                             (no external LLM calls)

ai_service/ directory exists at project root — no implementation present
```

---

## 2. Application Entry Point

**Class:** `com.arstem.backend.BackendApplication`
**Annotation:** `@SpringBootApplication`
**Method:** `main(String[])` → `SpringApplication.run(BackendApplication.class, args)`

On startup, two `ApplicationRunner` beans execute in order:
1. `TopicSeeder` (`@Order(1)`) — seeds 18 topics if the `topics` collection is empty
2. `TopicCodeMigrationRunner` (`@Order(2)`) — normalizes legacy topic codes across all 5 data collections

---

## 3. Configuration

### `application.properties`

| Key | Value |
|---|---|
| `spring.application.name` | `backend` |
| `spring.data.mongodb.uri` | `${MONGODB_URI}` — required env var |
| `spring.data.mongodb.database` | `ar_stem_learning` |
| `jwt.secret` | `${JWT_SECRET}` — required env var (Base64-encoded 256-bit key) |
| `jwt.expiration` | `${JWT_EXPIRATION:86400000}` — default 24 hours in ms |

Secrets are **never** hardcoded. They are provided via environment variables at runtime.

---

## 4. Actual Folder Structure

```
backend/
├── pom.xml
├── BACKEND_ARCHITECTURE.md
├── echo.md                          # Local dev env var notes — do not commit secrets
├── src/
│   ├── main/
│   │   ├── java/com/arstem/backend/
│   │   │   ├── BackendApplication.java
│   │   │   ├── auth/
│   │   │   │   ├── api/             # AuthController, LoginRequest, RegisterRequest,
│   │   │   │   │                    #   TokenResponse, AuthUserResponse
│   │   │   │   └── service/         # AuthService
│   │   │   ├── user/
│   │   │   │   ├── api/             # UserController, UserProfileResponse
│   │   │   │   ├── domain/          # User (@Document), Role (enum), UserStatus (enum)
│   │   │   │   ├── repository/      # UserRepository
│   │   │   │   └── service/         # UserService
│   │   │   ├── topic/
│   │   │   │   ├── api/             # TopicController, TopicResponse
│   │   │   │   ├── domain/          # Topic (@Document), TopicStatus (enum)
│   │   │   │   ├── repository/      # TopicRepository
│   │   │   │   ├── service/         # TopicService
│   │   │   │   └── config/          # TopicSeeder (ApplicationRunner, @Order(1))
│   │   │   ├── session/
│   │   │   │   ├── api/             # SessionController, StartSessionRequest,
│   │   │   │   │                    #   SessionResponse
│   │   │   │   ├── domain/          # LearningSession (@Document), SessionStatus (enum)
│   │   │   │   ├── repository/      # LearningSessionRepository
│   │   │   │   └── service/         # LearningSessionService
│   │   │   ├── quiz/
│   │   │   │   ├── api/             # QuizController, SubmitQuizRequest,
│   │   │   │   │                    #   QuizAttemptResponse
│   │   │   │   ├── domain/          # QuizAttempt (@Document)
│   │   │   │   ├── repository/      # QuizAttemptRepository
│   │   │   │   └── service/         # QuizService
│   │   │   ├── misconception/
│   │   │   │   ├── api/             # MisconceptionController,
│   │   │   │   │                    #   RecordMisconceptionRequest,
│   │   │   │   │                    #   MisconceptionResponse
│   │   │   │   ├── domain/          # Misconception (@Document),
│   │   │   │   │                    #   MisconceptionSeverity (enum),
│   │   │   │   │                    #   MisconceptionStatus (enum)
│   │   │   │   ├── repository/      # MisconceptionRepository
│   │   │   │   └── service/         # MisconceptionService
│   │   │   ├── progress/
│   │   │   │   ├── api/             # ProgressController, ProgressResponse
│   │   │   │   ├── domain/          # Progress (@Document)
│   │   │   │   ├── repository/      # ProgressRepository
│   │   │   │   └── service/         # ProgressService
│   │   │   ├── learninganalytics/
│   │   │   │   ├── api/             # LearningAnalyticsController,
│   │   │   │   │                    #   LearningAnalyticsResponse
│   │   │   │   ├── domain/          # LearningAnalytics (@Document)
│   │   │   │   ├── repository/      # LearningAnalyticsRepository
│   │   │   │   └── service/         # LearningAnalyticsService
│   │   │   ├── ai/
│   │   │   │   ├── api/             # 5 controllers (Feedback, Insights, Recommendation,
│   │   │   │   │                    #   RevisionSuggestion, StudyPlan)
│   │   │   │   ├── domain/          # 7 response records + 2 enums
│   │   │   │   └── service/         # 5 rule-based services
│   │   │   ├── security/
│   │   │   │   ├── SecurityConfig.java
│   │   │   │   ├── JwtService.java
│   │   │   │   ├── JwtAuthenticationFilter.java
│   │   │   │   └── CustomUserDetailsService.java
│   │   │   ├── common/
│   │   │   │   ├── api/             # ApiResponse<T>, ApiError
│   │   │   │   └── exception/       # GlobalExceptionHandler,
│   │   │   │                        #   ConflictException,
│   │   │   │                        #   ResourceNotFoundException,
│   │   │   │                        #   UnauthorizedException
│   │   │   ├── migration/
│   │   │   │   ├── TopicCodeMigrationRunner.java   # @Order(2)
│   │   │   │   └── TopicCodeMigrationService.java
│   │   │   ├── ar/                  # EMPTY — no source files
│   │   │   └── config/              # EMPTY — no source files
│   │   └── resources/
│   │       └── application.properties
│   └── test/java/com/arstem/backend/
│       └── (test files)
```

> **Note:** The `ar` and `config` packages exist as directories but contain no source files.

---

## 5. Security and Authentication

### 5.1 SecurityConfig

**Class:** `com.arstem.backend.security.SecurityConfig`

| Aspect | Implementation |
|---|---|
| Session | Stateless (`SessionCreationPolicy.STATELESS`) |
| CSRF | Disabled |
| HTTP Basic | Disabled |
| Form Login | Disabled |
| Unauthenticated response | HTTP 401 (`HttpStatusEntryPoint`) |
| Password encoder | `BCryptPasswordEncoder` |
| Public endpoints | `POST /api/v1/auth/register`, `POST /api/v1/auth/login` |
| All other endpoints | Require valid JWT |
| Filter | `JwtAuthenticationFilter` before `UsernamePasswordAuthenticationFilter` |

### 5.2 JwtService

**Class:** `com.arstem.backend.security.JwtService`

| Aspect | Implementation |
|---|---|
| Algorithm | HMAC-SHA (key size determined by Base64-decoded secret) |
| Subject | User's email address |
| Claims | `sub` (email), `iat`, `exp` only — no roles, no jti, no issuer |
| Default expiration | 24 hours (`86400000` ms) — configurable via `JWT_EXPIRATION` env var |
| Key source | `JWT_SECRET` env var, Base64-decoded via `Decoders.BASE64` |

Key methods:
- `generateAccessToken(String email)` — builds and signs the JWT
- `extractUsername(String token)` — parses token and returns subject (email)
- `isTokenValid(String token, UserDetails userDetails)` — checks enabled status and username match; JJWT throws on expired tokens during parsing

### 5.3 JwtAuthenticationFilter

**Class:** `com.arstem.backend.security.JwtAuthenticationFilter` — extends `OncePerRequestFilter`

Per-request flow:
1. Reads `Authorization` header. If absent or not `Bearer ...`, passes through.
2. Extracts token, calls `JwtService.extractUsername()`.
3. Loads `UserDetails` via `CustomUserDetailsService` (looks up user by email).
4. Calls `JwtService.isTokenValid()`. On success, sets `UsernamePasswordAuthenticationToken` in `SecurityContextHolder`.
5. Any `JwtException`, `IllegalArgumentException`, or `UsernameNotFoundException` clears the context (the filter chain produces 401 downstream).
6. Always calls `filterChain.doFilter()`.

### 5.4 CustomUserDetailsService

**Class:** `com.arstem.backend.security.CustomUserDetailsService` — implements `UserDetailsService`

- `loadUserByUsername(String email)` — delegates to `UserService.findByEmail()`. Maps `UserStatus.ACTIVE` to `enabled=true`; maps `Role` values to Spring authority strings (`ROLE_STUDENT`, `ROLE_ADMIN`).

### 5.5 Role Policy

| Role | What it controls |
|---|---|
| `STUDENT` | Own sessions, misconceptions, quiz attempts, progress, analytics, AI endpoints |
| `ADMIN` | Defined in domain model — no admin-specific API routes currently implemented |

> **Note:** Object-level ownership is enforced in service methods by comparing the JWT's email to the stored `userId` on session, misconception, and attempt records.

### 5.6 What Is NOT Implemented

| Feature | Status |
|---|---|
| JWT refresh token | Not implemented — access token only |
| `POST /api/v1/auth/refresh` | Endpoint does not exist |
| `POST /api/v1/auth/logout` | Endpoint does not exist |
| Token revocation / blocklist | Not implemented |
| `PATCH /users/me` | Not implemented |
| Admin API routes | Not implemented |

---

## 6. MongoDB Schema

### Database name: `ar_stem_learning`

### Collections

| Collection | Entity Class | Key Unique Index |
|---|---|---|
| `users` | `User` | `email` |
| `topics` | `Topic` | `topicCode`; compound `(domainCode, topicCode)` |
| `learning_sessions` | `LearningSession` | none |
| `quiz_attempts` | `QuizAttempt` | none |
| `misconceptions` | `Misconception` | none |
| `progress` | `Progress` | compound `(userId, topicCode)` |
| `learning_analytics` | `LearningAnalytics` | compound `(userId, topicCode)` |

> The following collections described in the original architecture document do **not exist** in the current implementation: `ai_explanations`, `ai_generated_questions`. There is no separate `quizzes` collection with embedded question documents — quiz content is client-side; only attempt scores are persisted.

---

### 6.1 `users`

**`User.java`** — `@Document(collection = "users")`

| Field | Type | Notes |
|---|---|---|
| `id` | `String` | `@Id` |
| `displayName` | `String` | |
| `email` | `String` | `@Indexed(unique = true)`, normalized to lowercase |
| `passwordHash` | `String` | BCrypt hash |
| `roles` | `Set<Role>` | `STUDENT` or `ADMIN` |
| `status` | `UserStatus` | `ACTIVE` or `DISABLED` |
| `createdAt` | `Instant` | |
| `updatedAt` | `Instant` | |

---

### 6.2 `topics`

**`Topic.java`** — `@Document(collection = "topics")`

| Field | Type | Notes |
|---|---|---|
| `id` | `String` | `@Id` |
| `domainCode` | `String` | e.g. `"DSA"`, `"ELECTRONICS"`, `"CHEMISTRY"` |
| `topicCode` | `String` | `@Indexed(unique = true)` e.g. `"DSA_LINKED_LIST"` |
| `title` | `String` | Human-readable |
| `description` | `String` | |
| `activityCode` | `String` | AR activity identifier |
| `status` | `TopicStatus` | `ACTIVE` or `INACTIVE` |
| `createdAt` | `Instant` | |
| `updatedAt` | `Instant` | |

**Seeded topics** (18 total, via `TopicSeeder`):

| Domain | Topic Codes |
|---|---|
| DSA | `DSA_LINKED_LIST`, `DSA_STACK`, `DSA_BINARY_TREE` |
| ELECTRONICS | `ELECTRONICS_AND_GATE`, `ELECTRONICS_OR_GATE`, `ELECTRONICS_NOT_GATE`, `ELECTRONICS_XOR_GATE`, `ELECTRONICS_NAND_GATE`, `ELECTRONICS_NOR_GATE`, `ELECTRONICS_XNOR_GATE` |
| CHEMISTRY | `CHEMISTRY_METHANE`, `CHEMISTRY_ETHANE`, `CHEMISTRY_PROPANE`, `CHEMISTRY_METHANOL`, `CHEMISTRY_ETHANOL`, `CHEMISTRY_GLUCOSE`, `CHEMISTRY_FRUCTOSE`, `CHEMISTRY_SUCROSE` |

---

### 6.3 `learning_sessions`

**`LearningSession.java`** — `@Document(collection = "learning_sessions")`

| Field | Type | Notes |
|---|---|---|
| `id` | `String` | `@Id` |
| `userId` | `String` | FK to `users` |
| `domainCode` | `String` | Uppercase |
| `topicCode` | `String` | Uppercase |
| `activityCode` | `String` | Uppercase |
| `status` | `SessionStatus` | `ACTIVE` → `COMPLETED` |
| `startedAt` | `Instant` | |
| `endedAt` | `Instant` | Set on `complete()` |
| `createdAt` | `Instant` | |
| `updatedAt` | `Instant` | |

---

### 6.4 `quiz_attempts`

**`QuizAttempt.java`** — `@Document(collection = "quiz_attempts")`

| Field | Type | Notes |
|---|---|---|
| `id` | `String` | `@Id` |
| `userId` | `String` | |
| `sessionId` | `String` | |
| `topicCode` | `String` | Uppercase |
| `totalQuestions` | `int` | |
| `correctAnswers` | `int` | |
| `score` | `int` | `(correctAnswers * 100) / totalQuestions`, 0–100 |
| `submittedAt` | `Instant` | |
| `createdAt` | `Instant` | |
| `updatedAt` | `Instant` | |

> There is no separate `quizzes` collection with question definitions. Quiz content is managed client-side. The backend only receives and stores `totalQuestions` + `correctAnswers` + computed `score`.

---

### 6.5 `misconceptions`

**`Misconception.java`** — `@Document(collection = "misconceptions")`

| Field | Type | Notes |
|---|---|---|
| `id` | `String` | `@Id` |
| `userId` | `String` | |
| `sessionId` | `String` | |
| `topicCode` | `String` | Uppercase |
| `misconceptionCode` | `String` | e.g. `"DSA_HEAD_POINTER_MISSING"` |
| `misconceptionTitle` | `String` | |
| `description` | `String` | |
| `severity` | `MisconceptionSeverity` | `LOW`, `MEDIUM`, `HIGH` |
| `status` | `MisconceptionStatus` | `ACTIVE` or `RESOLVED` |
| `resolvedAt` | `Instant` | Set by `resolve()` |
| `createdAt` | `Instant` | |
| `updatedAt` | `Instant` | |

Domain methods: `isActive()`, `resolve()`, `markCreated()`

Resolution logic: handled in `LearningAnalyticsService` — latest quiz score ≥ 80 resolves all active misconceptions; ≥ 60 resolves the oldest half.

**Known misconception codes used by the Flutter client:**

| Domain | Code |
|---|---|
| DSA | `DSA_HEAD_POINTER_MISSING`, `DSA_BROKEN_LINKED_LIST`, `DSA_INVALID_TRAVERSAL`, `DSA_STACK_OVERFLOW`, `DSA_STACK_UNDERFLOW`, `DSA_STACK_TOP_POINTER_MISMATCH`, `DSA_INVALID_TREE_HIERARCHY`, `DSA_INVALID_TREE_TRAVERSAL`, `DSA_DUPLICATE_TREE_NODE` |
| Electronics | `ELECTRONICS_INVALID_XOR_CONSTRUCTION`, `ELECTRONICS_INCORRECT_OUTPUT`, `ELECTRONICS_INVALID_GATE_CONNECTION` |
| Chemistry | `OC_INVALID_VALENCY`, `OC_HYDROGEN_VALENCY_MISMATCH`, `OC_INVALID_SUGAR_VALENCY`, `OC_SUGAR_HYDROGEN_MISMATCH`, `OC_INVALID_FUNCTIONAL_GROUP_VALENCY`, `OC_FUNCTIONAL_GROUP_HYDROGEN_MISMATCH`, `OC_INVALID_BOND_VALENCY`, `OC_BOND_HYDROGEN_MISMATCH` |

---

### 6.6 `progress`

**`Progress.java`** — `@Document(collection = "progress")`

Compound unique index: `(userId, topicCode)`

| Field | Type | Notes |
|---|---|---|
| `id` | `String` | `@Id` |
| `userId` | `String` | |
| `topicCode` | `String` | |
| `completedSessions` | `int` | Count of COMPLETED sessions |
| `misconceptionCount` | `int` | Total (including resolved) |
| `completionPercent` | `int` | `min(completedSessions × 25, 100)` |
| `masteryScore` | `int` | `max(100 − misconceptionCount × 10, 0)` |
| `weakAreas` | `List<String>` | Unique sorted `misconceptionCode` values |
| `createdAt` | `Instant` | |
| `updatedAt` | `Instant` | |

> The `masteryScore` in `progress` uses a **simplified formula**. The more accurate 4-component formula is in `LearningAnalytics`.

---

### 6.7 `learning_analytics`

**`LearningAnalytics.java`** — `@Document(collection = "learning_analytics")`

Compound unique index: `(userId, topicCode)`

| Field | Type | Notes |
|---|---|---|
| `id` | `String` | `@Id` |
| `userId` | `String` | |
| `topicCode` | `String` | |
| `completedSessions` | `int` | |
| `misconceptionCount` | `int` | Active-only (post-resolution) |
| `averageQuizScore` | `int` | Average of all attempts |
| `masteryScore` | `int` | 4-component formula, 0–100 |
| `masteryLevel` | `String` | `MASTERED`/`PROFICIENT`/`DEVELOPING`/`BEGINNER` |
| `weakAreas` | `List<String>` | Distinct active misconceptionCodes, sorted |
| `recommendedPractice` | `boolean` | `masteryScore < 80` or `activeMisconceptions > 0` |
| `summary` | `String` | Personalized narrative generated by `LearningAnalyticsService` |
| `createdAt` | `Instant` | |
| `updatedAt` | `Instant` | |

---

## 7. Mastery Calculation

### 7.1 Progress (Simplified)

Used in `ProgressService`:

```
completionPercent = min(completedSessions × 25, 100)
masteryScore      = max(100 − totalMisconceptionCount × 10, 0)
```

### 7.2 Learning Analytics (4-Component Formula)

Used in `LearningAnalyticsService.computeAndSave()`:

```
latestScore        = score of the most recent quiz attempt  (0–100)
recentAvg          = average of the 3 most recent attempts  (0–100)
activePenalty      = 100 − min(activeMisconceptions × 10, 100)
consistency        = min(completedSessions × 25, 100)

masteryScore = round(
    latestScore   × 0.40
  + recentAvg     × 0.30
  + activePenalty × 0.20
  + consistency   × 0.10
), clamped to [0, 100]
```

### 7.3 Mastery Levels

| Score Range | Level |
|---|---|
| 80–100 | MASTERED |
| 60–79 | PROFICIENT |
| 40–59 | DEVELOPING |
| 0–39 | BEGINNER |

### 7.4 Misconception Resolution

Triggered every time `LearningAnalyticsService.generateForUser()` runs:

| Latest Quiz Score | Resolution Action |
|---|---|
| ≥ 80 | Resolve ALL active misconceptions for the topic |
| 60–79 | Resolve the oldest half of active misconceptions |
| < 60 | No resolution |

---

## 8. REST API

### Base path: `/api/v1`
### Format: JSON, UTC ISO-8601 timestamps
### Auth: `Authorization: Bearer <accessToken>` on all protected routes

### 8.1 Authentication

| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/auth/register` | Public | Register a new STUDENT account |
| POST | `/auth/login` | Public | Validate credentials, return JWT |

**`RegisterRequest`** fields: `displayName` (max 100), `email` (email format, max 320), `password` (8–72 chars)

**`LoginRequest`** fields: `email`, `password`

**`TokenResponse`** fields: `token` (JWT), `tokenType` ("Bearer")

**`AuthUserResponse`** fields: `id`, `displayName`, `email`, `roles`, `createdAt`

> No `/auth/refresh` or `/auth/logout` endpoints exist.

### 8.2 User

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/users/me` | Required | Return own profile |

**`UserProfileResponse`** fields: `id`, `displayName`, `email`, `roles`, `status`

### 8.3 Topics

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/topics` | Required | List all topics, sorted by domainCode + title |
| GET | `/topics/{topicCode}` | Required | Get one topic by code (normalized to uppercase) |

**`TopicResponse`** fields: `id`, `domainCode`, `topicCode`, `title`, `description`, `activityCode`, `status`

### 8.4 Learning Sessions

| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/sessions/start` | Required | Start a new learning session |
| POST | `/sessions/{sessionId}/end` | Owner only | Complete the session |
| GET | `/sessions/me` | Required | List own sessions, newest first |

**`StartSessionRequest`** fields: `domainCode`, `topicCode`, `activityCode` (all required)

**`SessionResponse`** fields: `id`, `userId`, `domainCode`, `topicCode`, `activityCode`, `status`, `startedAt`, `endedAt`

### 8.5 Quiz Attempts

| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/quizzes/submit` | Required | Submit assessment result |
| GET | `/quizzes/me` | Required | List own attempts, newest first |
| GET | `/quizzes/topic/{topicCode}` | Required | List own attempts for one topic |

**`SubmitQuizRequest`** fields: `sessionId`, `topicCode`, `totalQuestions`, `correctAnswers`

**`QuizAttemptResponse`** fields: `id`, `sessionId`, `topicCode`, `totalQuestions`, `correctAnswers`, `score`, `submittedAt`

> Score is computed server-side: `(correctAnswers × 100) / totalQuestions`

### 8.6 Misconceptions

| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/misconceptions` | Required | Record one misconception occurrence |
| GET | `/misconceptions/me` | Required | List own misconceptions, newest first |
| GET | `/misconceptions/session/{sessionId}` | Owner only | List misconceptions for one session |

**`RecordMisconceptionRequest`** fields: `sessionId`, `topicCode`, `misconceptionCode`, `misconceptionTitle`, `description`, `severity` (LOW/MEDIUM/HIGH)

**`MisconceptionResponse`** fields: `id`, `sessionId`, `topicCode`, `misconceptionCode`, `misconceptionTitle`, `description`, `severity`, `createdAt`

### 8.7 Progress

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/progress/me` | Required | Progress across all topics |
| GET | `/progress/topic/{topicCode}` | Required | Progress for one topic |

**`ProgressResponse`** fields: `topicCode`, `completedSessions`, `misconceptionCount`, `completionPercent`, `masteryScore`, `weakAreas`

### 8.8 Learning Analytics

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/analytics/me` | Required | Analytics across all topics (triggers recalculation) |
| GET | `/analytics/topic/{topicCode}` | Required | Analytics for one topic (triggers recalculation) |

**`LearningAnalyticsResponse`** fields: `topicCode`, `completedSessions`, `misconceptionCount`, `averageQuizScore`, `masteryScore`, `masteryLevel`, `weakAreas`, `recommendedPractice`, `summary`

### 8.9 Rule-Based AI Endpoints

All endpoints are GET requests. All are authenticated. All responses are computed from MongoDB data — no external service calls.

| Method | Path | Description |
|---|---|---|
| GET | `/ai/feedback` | Per-topic feedback strings |
| GET | `/ai/insights` | Strengths, weaknesses, practice topics across all topics |
| GET | `/ai/insights/{topicCode}` | Same, scoped to one topic |
| GET | `/ai/recommendations` | Recommendation type per topic |
| GET | `/ai/recommendations/{topicCode}` | Recommendation for one topic (204 if no data) |
| GET | `/ai/revision-suggestions` | Revision topics, actions, and time estimate |
| GET | `/ai/revision-suggestions/{topicCode}` | Same, scoped to one topic |
| GET | `/ai/study-plan` | Today's task list with priority and time estimate |
| GET | `/ai/study-plan/{topicCode}` | Same, scoped to one topic |

**Recommendation types** (from `RecommendationType` enum):
`PRACTICE`, `NEXT_TOPIC`, `REVISION`, `QUIZ_PRACTICE`

**Study plan priority levels** (from `PriorityLevel` enum):
`HIGH` (BEGINNER/DEVELOPING), `MEDIUM` (PROFICIENT), `LOW` (MASTERED)

---

## 9. Rule-Based AI Services

### `AIRecommendationService`

Recommendation tiers derived from `LearningAnalytics.masteryLevel` and active misconceptions:

| Condition | Recommendation Type |
|---|---|
| Active misconceptions > 0 (overrides tier) | `REVISION` |
| masteryScore ≥ 80 (MASTERED) | `NEXT_TOPIC` |
| masteryScore 60–79 (PROFICIENT) | `QUIZ_PRACTICE` |
| masteryScore 40–59 (DEVELOPING) | `REVISION` |
| masteryScore < 40 (BEGINNER) | `PRACTICE` |

### `AIStudyPlanService`

Task sets per mastery tier:
- **BEGINNER**: Study topic + AR practice + retry assessment (HIGH priority, 60 min)
- **DEVELOPING**: Practice insert/delete operations + quiz attempt (HIGH priority, 60 min)
- **PROFICIENT**: Challenge exercises + timed assessment (MEDIUM priority, 45 min)
- **MASTERED**: Start next topic (LOW priority, 30 min)

Active misconceptions > 3 raises priority by one level.

### `AIRevisionSuggestionService`

Generates revision topics from ACTIVE misconceptions only. Estimated time: `revisionTopics.size() × 20 + reviewActions × 10` minutes.

### `AILearningInsightsService`

Strengths = topics with masteryScore ≥ 80. Weaknesses = topics with masteryScore < 40. Topics needing practice = any with `misconceptionCount > 0` or `averageQuizScore < 60`.

### `AIFeedbackService`

Emits per-topic feedback strings:
- masteryScore ≥ 80 → strong performance message
- masteryScore < 50 → below-target message
- Active misconceptions > 3 → multiple misconceptions message
- averageQuizScore < 60 → poor quiz performance message

---

## 10. Common Infrastructure

### Response Envelope

All non-trivial create responses use `ApiResponse<T>`:

```json
{
  "success": true,
  "message": "User registered successfully.",
  "data": { ... }
}
```

### Error Envelope

All errors return `ApiError`:

```json
{
  "code": "VALIDATION_ERROR",
  "message": "Validation failed",
  "traceId": "a1b2c3d4-...",
  "fieldErrors": {
    "email": "must be a well-formed email address"
  }
}
```

### Exception Mapping

| Exception | HTTP Status | Code |
|---|---|---|
| `MethodArgumentNotValidException` | 400 | `VALIDATION_ERROR` |
| `ConflictException` | 409 | `CONFLICT` |
| `UnauthorizedException` | 401 | `UNAUTHORIZED` |
| `ResourceNotFoundException` | 404 | `NOT_FOUND` |
| `Exception` (catch-all) | 500 | `INTERNAL_ERROR` |

---

## 11. Topic Code Migration

The `migration` package handles normalization of legacy topic codes stored in older documents.

**`TopicCodeMigrationService`** uses `MongoTemplate` directly to run bulk updates across 5 collections (`learning_sessions`, `quiz_attempts`, `misconceptions`, `progress`, `learning_analytics`).

Example mappings: `"linked-list"` → `"DSA_LINKED_LIST"`, `"methane"` → `"CHEMISTRY_METHANE"`.

For `progress` and `learning_analytics` (which have a unique compound index on `userId + topicCode`), a `mergeOrRename` strategy is used: if a canonical document already exists for the user, the legacy orphan is deleted; otherwise the legacy document is renamed in place.

The migration is **idempotent** — running it a second time finds 0 matching documents and exits instantly.

---

## 12. What Was Planned but Not Implemented

The following items appear in the original architecture document but are **not present in the current codebase**:

| Planned Feature | Status |
|---|---|
| Argon2id password hashing | Not implemented — BCrypt is used |
| JWT refresh tokens and `/auth/refresh` | Not implemented |
| `/auth/logout` endpoint | Not implemented |
| `PATCH /users/me` profile editing | Not implemented |
| Admin user management endpoints | Not implemented |
| `ai_explanations` MongoDB collection | Not implemented |
| `ai_generated_questions` MongoDB collection | Not implemented |
| `quizzes` collection with embedded question documents | Not implemented — quiz content is client-side |
| External AI/LLM gateway | Not implemented — all AI is rule-based |
| AR endpoints | Directory exists, no source files |
| `POST /ai/*` endpoints | All AI endpoints are GET only |
| Rate limiting, circuit breaking | Not implemented |
| CORS configuration | Not explicitly configured (Spring Boot defaults) |
| OpenAPI / Swagger documentation | Not configured |

---

## 13. Testing

Test files exist under `src/test/java/com/arstem/backend/` (generated by Spring Initializr). No domain-specific tests have been written at the time of this documentation update.

Test dependencies available:
- `spring-boot-starter-test`
- `spring-security-test`
