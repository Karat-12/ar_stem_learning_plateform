# AR STEM Learning Platform — Core Vision & Project Blueprint

> **Documentation status:** Updated to reflect the current implementation as of the latest code inspection.
> Code is the source of truth. All status percentages reflect the actual implemented state.

---

## Project Name

Adaptive Interactive Learning Framework with Augmented Reality for STEM Education

---

## Core Vision

The goal of this project is NOT to build another quiz app.

The goal is to create an intelligent learning environment where students learn concepts through:

1. Visualization
2. Interaction
3. Error Detection
4. Adaptive Guidance
5. Conceptual Understanding

instead of rote memorization.

---

## The Core Learning Loop

This is the most important idea in the entire project.

```
Student Action
      ↓
Rule-Based Evaluation
      ↓
Conceptual Error Detection
      ↓
Adaptive Feedback
      ↓
Student Correction
      ↓
Improved Understanding
```

---

## Example: Linked List Assessment

The system implements this loop concretely in the Linked List Assessment feature:

A student attempts to "Build the chain" — four unconnected nodes must be linked head-to-tail.

**If the student sets no HEAD:**
- Misconception detected: `DSA_HEAD_POINTER_MISSING`
- Feedback: "No HEAD selected yet. Tap a node and choose 'Set as HEAD'."

**If a node is left disconnected:**
- Misconception detected: `DSA_BROKEN_LINKED_LIST`
- Feedback: "Node 40 is not connected. Draw an arrow from the previous node to reach it."

**If all connected but wrong order:**
- Misconception detected: `DSA_INVALID_TRAVERSAL`
- Feedback: "The chain is connected but the order is wrong."

These misconceptions are recorded to the backend, factored into the mastery score, and used by the AI Coach to generate targeted study plans and revision suggestions.

---

## Research Gap

Most systems provide:

- Visualization only
  OR
- Adaptive learning only

Very few systems combine:

- AR Visualization
- Interaction
- Conceptual Error Detection
- Adaptive Learning
- Explainable Feedback

inside a single framework.

---

## Technical Philosophy

We intentionally use:

**Rule-Based Evaluation**

instead of:

**Black-Box Machine Learning**

because:

- Explainability is critical in education
- Students must understand WHY they are wrong
- Structured STEM domains have clear logical rules

Examples:

- Linked List: HEAD pointer must exist; chain must be fully connected; traversal order must follow next-pointers
- Stack: LIFO — overflow on push beyond capacity, underflow on pop from empty
- Logic Gates: Truth table rules
- Chemistry: Valency rules (C=4, H=1, O=2, N=3, Cl=1)

---

## Current Technology Stack

### Frontend

| Technology | Version | Role |
|---|---|---|
| Flutter | Stable | Cross-platform UI framework |
| Dart SDK | `^3.11.5` | Language |
| Provider | `^6.1.0` | State management (`ChangeNotifier`) |
| Dio | `^5.4.0` | HTTP client |
| flutter_secure_storage | `^9.2.0` | Secure JWT storage |
| shared_preferences | `^2.2.2` | Local key-value storage (declared) |
| camera | `^0.12.0+2` | Camera feed for AR screen (no ARCore) |

### Backend

| Technology | Version | Role |
|---|---|---|
| Java | 21 | Language |
| Spring Boot | 3.5.15 | Framework |
| Spring Security | BOM-managed | Authentication/authorization |
| Spring Data MongoDB | BOM-managed | ODM layer |
| jjwt | 0.12.6 | JWT creation and validation |
| BCrypt | Spring Security built-in | Password hashing |
| MongoDB Atlas | Cloud | Primary data store |
| Maven | — | Build tool |

### Version Control

- Git / GitHub

### Future (Planned — Not Implemented)

- Unity + AR Foundation for true AR scenes
- Gemini / OpenAI / Ollama for generative AI tutor

---

## Current Frontend Status

### Implemented

| Feature | Status |
|---|---|
| Dark cyberpunk glassmorphism design system | Complete |
| Responsive navigation (rail + bottom nav) | Complete |
| Dashboard screen with action grid and metrics | Complete |
| JWT-secured login screen with session restoration | Complete |
| User registration screen | Complete |
| Advanced STEM Labs shell (domain → topic → workspace) | Complete |
| Linked List free-exploration workspace | Complete |
| Linked List task-based construction curriculum (3 tasks) | Complete |
| Linked List 3-challenge scored assessment | Complete |
| Stack workspace (PUSH/POP/TOP, overflow/underflow) | Complete |
| Binary Tree workspace (traversal animations) | Complete |
| Basic Logic Gates workspace | Complete |
| XOR Gate Builder | Complete |
| Complex Gate Construction (NAND/NOR/XNOR) | Complete |
| Truth Table Simulator | Complete |
| Hydrocarbon Builder (valency validation) | Complete |
| Sugar Structure Builder | Complete |
| Alcohol & Functional Groups lab | Complete |
| Bond Simulator | Complete |
| Rule-based misconception detection in all workspaces | Complete |
| Session tracking (start/end per workspace) | Complete |
| Misconception recording to backend | Complete |
| Progress screen (topic mastery, sessions, weak areas) | Complete |
| AI Coach screen (5-panel adaptive report per topic) | Complete |
| AR screen (live camera + Flutter canvas overlay) | Complete (camera-based, no ARCore) |

### Partially Implemented

| Feature | Status |
|---|---|
| Topic catalog browser | Folder created (`lib/features/topic/`), no Dart files implemented |
| AR interaction | Camera live feed works; 3D node scene overlaid on camera with Flutter canvas — no real spatial anchoring |

### Not Implemented

- ARCore / AR Foundation spatial anchoring
- True 3D rendering (Unity or native AR SDKs)
- Token refresh / persistent login beyond valid JWT window
- User registration from within a closed, invite-only system

**Frontend UI + Integration: ~90% Complete**

---

## Current Backend Status

### Implemented

| Module | Status |
|---|---|
| User registration (BCrypt, duplicate check) | Complete |
| Login (BCrypt verify, JWT issue) | Complete |
| Stateless JWT authentication filter | Complete |
| Topic catalog (18 seeded topics) | Complete |
| Learning session lifecycle (start / end) | Complete |
| Misconception recording and retrieval | Complete |
| Quiz attempt submission and scoring | Complete |
| Progress projection (per topic, mastery score) | Complete |
| Learning analytics (4-component mastery formula) | Complete |
| Rule-based AI recommendations | Complete |
| Rule-based AI learning insights | Complete |
| Rule-based AI feedback | Complete |
| Rule-based AI study plan generation | Complete |
| Rule-based AI revision suggestions | Complete |
| Topic code normalization migration | Complete |
| Global exception handler with consistent error envelope | Complete |

### Not Implemented

| Feature | Notes |
|---|---|
| JWT refresh token | Access token only; no `/auth/refresh` endpoint |
| Logout endpoint | No `/auth/logout`; token revocation not implemented |
| Admin role endpoints | `ADMIN` role defined in the domain but no admin-specific routes exist |
| `PATCH /users/me` | User profile editing not implemented |
| AR-specific endpoints | `ar` package directory exists but is empty |
| External AI/LLM integration | All AI services are fully rule-based; no Gemini/OpenAI/Ollama calls |

**Backend Core: ~95% Complete**

---

## Current AI Module Status

### Implemented (Rule-Based Adaptive Intelligence)

All "AI" services are rule-based algorithms computed from MongoDB data. There is **no external AI/LLM integration**.

| Endpoint | Implementation |
|---|---|
| `GET /api/v1/ai/recommendations` | Tier-based recommendation type derived from mastery score and active misconceptions |
| `GET /api/v1/ai/recommendations/{topicCode}` | Same, scoped to one topic |
| `GET /api/v1/ai/insights` | Strengths/weaknesses derived from mastery thresholds; topics needing practice flagged |
| `GET /api/v1/ai/insights/{topicCode}` | Same, scoped to one topic |
| `GET /api/v1/ai/feedback` | Per-topic feedback strings from mastery, quiz scores, misconception counts |
| `GET /api/v1/ai/study-plan` | Task list generated from mastery tier (BEGINNER/DEVELOPING/PROFICIENT/MASTERED) |
| `GET /api/v1/ai/study-plan/{topicCode}` | Same, scoped to one topic |
| `GET /api/v1/ai/revision-suggestions` | Active misconceptions drive revision topic list and time estimates |
| `GET /api/v1/ai/revision-suggestions/{topicCode}` | Same, scoped to one topic |

**Rule-Based AI Layer: 100% Complete**

### Not Implemented (Planned Future AI Service)

- Error explanations via LLM (Gemini/OpenAI/Ollama)
- Dynamic natural-language hints
- AI question generation
- Personalized LLM-written revision content

The `ai_service/` directory exists at the project root but contains no implementation.

---

## Remaining Work

### Phase 3 — Frontend ↔ Backend Integration (Current)

**Completed:**
- Login / JWT storage / session restoration
- Session tracking (start/end per workspace)
- Misconception logging to backend
- Progress retrieval and display
- AI Coach endpoint integration (5 parallel calls per topic)
- Assessment quiz submission

**Remaining:**
- Topic catalog browser (frontend screen)
- Registration confirmation flow improvements
- Token refresh / logout server-side revocation

---

### Phase 4 — Adaptive Feedback Engine

Adaptive visual feedback levels:

- Level 1: Visual error indicators (partially implemented — color coding exists in workspaces)
- Level 2: Hints (implemented in linked list assessment)
- Level 3: Detailed explanations (implemented in AI Coach screen)
- Level 4: Animated demonstrations (not yet implemented)

---

### Phase 5 — AR Integration (Planned)

The current AR screen (`ArLinkedListScreen`) uses the `camera` package to display a live camera preview with a Flutter-rendered 3D-style linked list scene overlaid on top. This is **not true AR** — there is no spatial anchoring, no depth sensing, and no ARCore/ARKit integration.

True AR requires:
- Unity + AR Foundation, or
- ARCore (Android) / ARKit (iOS) native integration

This remains a future phase.

---

### Phase 6 — AI Service (Planned)

A separate `ai_service/` directory exists at the project root. No implementation is present. Planned capabilities:

- LLM-powered AI Tutor
- Dynamic natural-language explanations
- Question generation
- Personalized learning support

Possible models: Gemini, OpenAI, Ollama.

---

## Interview-Ready Terminology

When explaining this project to an interviewer:

- **Adaptive Learning System** — The platform adjusts feedback and guidance based on student actions and recorded misconceptions.
- **Intelligent Tutoring System (ITS)** — Analyzes mistakes and guides students step-by-step through remediation tasks.
- **Rule-Based Evaluation Engine** — Uses domain-specific rules (BST properties, logic gate truth tables, valency rules) to evaluate correctness without a black-box model.
- **Conceptual Error Detection** — Identifies *why* a student is wrong, not just *that* they are wrong. Misconception codes like `DSA_HEAD_POINTER_MISSING` are semantically meaningful.
- **Misconception Analysis** — Recurring mistakes are recorded per topic and per session. They are resolved automatically when quiz performance improves beyond a threshold.
- **Mastery-Based Learning** — A 4-component formula (latest quiz score × 0.40, recent average × 0.30, misconception penalty × 0.20, session consistency × 0.10) drives a mastery score and level (BEGINNER → DEVELOPING → PROFICIENT → MASTERED).
- **Personalized Learning Path** — The AI Coach aggregates analytics, active misconceptions, and quiz history to generate study plans and revision suggestions tailored to the individual student.
- **Interactive STEM Visualization** — Concepts are learned through hands-on drag-and-drop interaction, not passive reading.
- **Progressive Scaffolding** — Hints are provided progressively in the assessment (hint 1 → hint 2 → hint 3) before revealing the full explanation.
- **Explainable AI (XAI)** — Every piece of feedback maps to a named misconception code and a human-readable explanation. There are no black-box decisions.
- **Student Modeling** — Each learner has topic-level mastery scores, weak area lists, session histories, and misconception records stored per user.
- **AR-Assisted Learning (Current: Camera Overlay)** — The AR tab provides a live camera feed with a Flutter-canvas linked list visualization overlay. Full spatial AR anchoring is planned for a future phase.
- **Assessment → AI Coach Feedback Loop** — After completing the Linked List Assessment, the system automatically refreshes the AI Coach report, generating updated study plans, recommendations, and revision actions based on the new performance data.

---

## Current Overall Progress

| Component | Status |
|---|---|
| Backend Core (REST API, security, data layer) | ~95% complete |
| Rule-Based AI Layer | 100% complete |
| Frontend UI (all lab workspaces) | ~95% complete |
| Frontend ↔ Backend Integration | ~85% complete |
| Linked List Assessment + AI Coach loop | 100% complete |
| Adaptive Feedback Loop (visual levels) | ~40% complete |
| AR (camera overlay only) | ~15% complete (true AR not started) |
| External AI/LLM Service | 0% (planned) |

**Overall Project: ~80% Complete**

---

## Golden Rule

Whenever a design decision is made, ask:

> "Does this improve conceptual understanding through interaction, error detection, and adaptive guidance?"

If YES: Build it.
If NO: It is probably outside the core project vision.
